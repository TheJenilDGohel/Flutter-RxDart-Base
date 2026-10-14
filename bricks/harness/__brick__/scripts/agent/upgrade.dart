// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

/// Upgrades the AI agent harness in this project without losing context.
///
/// ```
/// dart run scripts/agent/upgrade.dart                 # latest upstream release
/// dart run scripts/agent/upgrade.dart --ref <git-ref> # a branch, tag or commit
/// dart run scripts/agent/upgrade.dart --brick <dir>   # a local harness brick
/// dart run scripts/agent/upgrade.dart --check-only    # report, change nothing
/// dart run scripts/agent/upgrade.dart --force         # re-apply the same version
/// ```
///
/// Three tiers:
/// 1. **Managed** (`scripts/agent/`, the skills the brick ships, the QA
///    subagent) — every file the brick ships is written. Files it does not
///    ship are never deleted (your own scripts or notes stay), except files
///    older harness versions shipped and later retired. Shipped skills the
///    brick no longer ships are removed; skills you created are untouched.
/// 2. **Memory** (`.harness/`: active context, progress, lessons, skill
///    overlays, specs) — never touched; missing files are created.
/// 3. **Contracts** (`AGENTS.md`, `CLAUDE.md`) — the template part above the
///    `harness:project-rules` marker is replaced; everything below it is kept
///    verbatim. Pre-1.6 files (no marker) keep every line the harness never
///    shipped. Config you may have edited (`.claude/settings.json`,
///    `.mcp.json`) is only added when missing, with a report of what differs.
///
/// The templates are rendered in a throwaway mason workspace that names the
/// upstream repository (`upstream_repo` in `.harness/version.json`), so a
/// stale global brick or a project `mason.yaml` pin cannot serve an old
/// version. Offline, the `harness` brick registered with mason is used.
/// When the rendered harness ships a different `upgrade.dart`, that new
/// engine applies the upgrade, so its fixes take effect immediately. Nothing
/// changes unless rendering succeeds, and every touched file is backed up to
/// `.harness/.backup_<timestamp>/`.
Future<void> main(List<String> args) async {
  final options = _Options(args);

  if (!File('pubspec.yaml').existsSync()) {
    _fail('Run from the Flutter project root (pubspec.yaml not found).');
  }

  final manifestFile = File('.harness/version.json');
  final manifest = _readJson(manifestFile);
  final current = manifest['version']?.toString() ?? '0.0.0';
  // fork-url: the fork until upstream (TheJenilDGohel) merges harness 1.6.
  final upstream =
      manifest['upstream_repo']?.toString() ??
      'https://github.com/jenilseawind-glitch/Flutter-RxDart-Base.git';

  if (options.checkOnly) {
    final latest = await _latestUpstreamVersion(upstream);
    final hasUpdate = latest != null && _compare(latest, current) > 0;
    if (latest == null) {
      print(
        'Could not determine the latest harness version from $upstream '
        '(network or repository unavailable). Installed: $current.',
      );
    } else if (hasUpdate) {
      print('Update available: $current → $latest');
    } else {
      print('Harness $current is up to date (upstream: $latest).');
    }
    final ghOutput = Platform.environment['GITHUB_OUTPUT'];
    if (ghOutput != null) {
      File(ghOutput).writeAsStringSync(
        'has_update=$hasUpdate\nnew_version=${latest ?? current}\n',
        mode: FileMode.append,
      );
    }
    return;
  }

  final vars = _resolveVars(manifest);

  // An older engine rendered the templates and handed them to this one.
  final handedOver = options.apply;
  if (handedOver != null) {
    final target = _renderedVersion(handedOver);
    if (target == null) _fail('--apply: no rendered harness in $handedOver.');
    _apply(handedOver, manifest, current, target, vars);
    return;
  }

  print(
    'Harness $current — rendering templates for ${vars['project_name']} '
    '(${vars['android_package_name']} / ${vars['ios_bundle_id']})...',
  );

  final staging = Directory('.harness/.staging_upgrade');
  if (staging.existsSync()) staging.deleteSync(recursive: true);
  staging.createSync(recursive: true);

  try {
    final out = Directory('${staging.path}/out').absolute.path;
    final source = await _render(options, upstream, vars, staging.path, out);
    final target = _renderedVersion(out)!;
    print('Rendered harness $target from $source.');

    final cmp = _compare(target, current);
    if (cmp <= 0 && !options.force) {
      print(
        cmp == 0
            ? 'Already on $target. Use --force to re-apply it.'
            : 'The source renders $target, older than the installed '
                  '$current; nothing changed. Use --force to install it.',
      );
      return;
    }

    // Let the new engine apply its own version: fixes in the upgrade logic
    // then take effect on the upgrade that ships them.
    final mine = File('scripts/agent/upgrade.dart');
    final theirs = File('$out/scripts/agent/upgrade.dart');
    if (theirs.existsSync() &&
        (!mine.existsSync() ||
            mine.readAsStringSync() != theirs.readAsStringSync())) {
      print('Handing over to the $target upgrade engine...');
      // The Dart VM running this script is already the project's SDK (FVM
      // or not). Re-resolving `fvm` here can hit a pub-global shim whose
      // snapshot was built by another SDK ("Can't load Kernel binary").
      final child = await Process.start(Platform.resolvedExecutable, [
        theirs.path,
        '--apply',
        out,
      ], mode: ProcessStartMode.inheritStdio);
      exitCode = await child.exitCode;
      return;
    }
    _apply(out, manifest, current, target, vars);
  } finally {
    if (staging.existsSync()) staging.deleteSync(recursive: true);
  }
}

class _Options {
  _Options(List<String> args) {
    String? valueOf(String flag) {
      final i = args.indexOf(flag);
      if (i == -1) return null;
      if (i + 1 >= args.length) _fail('$flag needs a value.');
      return args[i + 1];
    }

    checkOnly = args.contains('--check-only');
    force = args.contains('--force');
    ref = valueOf('--ref');
    brick = valueOf('--brick');
    apply = valueOf('--apply');
  }

  late final bool checkOnly;
  late final bool force;
  late final String? ref;
  late final String? brick;
  late final String? apply;
}

/// Renders the harness into [out] and says where it came from.
Future<String> _render(
  _Options options,
  String upstream,
  Map<String, String> vars,
  String staging,
  String out,
) async {
  final make = [
    'make',
    'harness',
    for (final e in vars.entries) ...['--${e.key}', e.value],
    '--on-conflict',
    'overwrite',
    '-o',
    out,
  ];
  final workspace = Directory('$staging/workspace')
    ..createSync(recursive: true);
  final brick = options.brick;
  final ref = options.ref;

  // A throwaway workspace whose own mason.yaml names the source. Being the
  // nearest mason.yaml, it wins over the project's and the global one.
  final String source;
  final String yaml;
  if (brick != null) {
    final dir = Directory(brick).absolute.path;
    if (!File('$dir/brick.yaml').existsSync()) {
      _fail('--brick $brick: no brick.yaml there.');
    }
    source = dir;
    yaml = 'bricks:\n  harness:\n    path: ${jsonEncode(dir)}\n';
  } else {
    source = ref == null ? upstream : '$upstream @ $ref';
    yaml =
        'bricks:\n  harness:\n    git:\n'
        '      url: ${jsonEncode(upstream)}\n'
        '      path: bricks/harness\n'
        '${ref == null ? '' : '      ref: ${jsonEncode(ref)}\n'}';
  }
  File('${workspace.path}/mason.yaml').writeAsStringSync(yaml);

  final errors = StringBuffer();
  Future<bool> mason(List<String> args, String dir) async {
    final r = await Process.run(
      'mason',
      args,
      workingDirectory: dir,
      runInShell: true,
    );
    if (r.exitCode != 0) errors.write('${r.stdout}${r.stderr}');
    return r.exitCode == 0;
  }

  if (await mason(['get'], workspace.path) &&
      await mason(make, workspace.path) &&
      _renderedVersion(out) != null) {
    return source;
  }
  if (brick != null || ref != null) {
    _fail(
      'Could not render the harness from $source (nothing was changed).\n'
      '$errors',
    );
  }

  // Offline: the brick registered with mason (project mason.yaml first,
  // then the global one).
  print(
    'Could not render the harness from $upstream (offline?). Falling back '
    'to the `harness` brick registered with mason.',
  );
  if (!await mason(make, '.') || _renderedVersion(out) == null) {
    _fail(
      'Could not render the harness brick (nothing was changed).\n'
      '$errors\n'
      'Check your network, or register the brick once with:\n'
      '  mason add -g harness --git-url $upstream --git-path bricks/harness',
    );
  }
  final latest = await _latestUpstreamVersion(upstream);
  final rendered = _renderedVersion(out)!;
  if (latest != null && _compare(latest, rendered) > 0) {
    print(
      'Note: the registered brick renders $rendered but upstream is at '
      '$latest. A project mason.yaml/mason-lock.json pins it (run `mason '
      'upgrade` here) or the global copy is stale (`mason upgrade -g`).',
    );
  }
  return 'the `harness` brick registered with mason';
}

/// The repositories the harness template has ever named as `upstream_repo`.
const _stockRepos = {
  'https://github.com/jenilseawind-glitch/Flutter-RxDart-Base.git',
  'https://github.com/TheJenilDGohel/Flutter-RxDart-Base.git',
};

String? _renderedVersion(String dir) =>
    _readJson(File('$dir/.harness/version.json'))['version']?.toString();

/// Files older harness versions shipped in managed folders and no longer
/// do. They are removed on upgrade; any other file there is yours and stays.
/// Add a path here whenever a managed file is renamed or removed.
const _retiredFiles = [
  '.agents/agents/flutter-qa.md',
  '.agents/skills/flutter-senior-dev/references/architecture.md',
  '.agents/skills/flutter-senior-dev/references/base-gaps.md',
  '.agents/skills/flutter-senior-dev/references/planning-checklist.md',
  '.cursor/skills/flutter-senior-dev/SKILL.md',
  '.cursor/skills/flutter-senior-dev/architecture.md',
  '.cursor/skills/flutter-senior-dev/base-gaps.md',
  '.cursor/skills/flutter-senior-dev/planning-checklist.md',
  '.cursor/skills/flutter-senior-dev/references/api-layer.md',
  '.cursor/skills/flutter-senior-dev/references/architecture.md',
  '.cursor/skills/flutter-senior-dev/references/base-gaps.md',
  '.cursor/skills/flutter-senior-dev/references/planning-checklist.md',
  '.cursor/skills/flutter-senior-dev/references/redux-vs-rxdart.md',
  '.cursor/skills/flutter-senior-dev/references/ui-conventions.md',
];

void _apply(
  String staged,
  Map<String, dynamic> manifest,
  String current,
  String target,
  Map<String, String> vars,
) {
  final backup = _backup();
  print('Backup: ${backup.path}');

  // Tier 1 — managed files.
  final retiredFiles = [
    for (final f in _retiredFiles)
      if (File(f).existsSync()) f,
  ];
  for (final f in retiredFiles) {
    File(f).deleteSync();
    _deleteEmptyParents(File(f).parent);
  }
  if (retiredFiles.isNotEmpty) {
    print(
      'Removed files older harness versions shipped:\n'
      '${retiredFiles.map((f) => '  $f').join('\n')}',
    );
  }

  final shipped = _skillNames('$staged/.agents/skills');
  final previouslyManaged =
      (manifest['managed_skills'] as List?)?.map((e) => e.toString()) ??
      const ['flutter-senior-dev'];
  for (final retired in previouslyManaged.where((s) => !shipped.contains(s))) {
    for (final root in ['.agents/skills', '.claude/skills']) {
      final dir = Directory('$root/$retired');
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
        print('Removed $root/$retired (no longer shipped by the harness).');
      }
    }
  }
  final kept = [
    for (final dir in [
      'scripts/agent',
      'scripts/team',
      '.claude/agents',
      '.claude/rules',
      '.cursor/rules',
      '.maestro/flows',
      for (final skill in shipped) ...[
        '.agents/skills/$skill',
        '.claude/skills/$skill',
      ],
    ])
      ..._syncDir(staged, dir),
  ];
  if (!File('.worktreeinclude').existsSync() &&
      File('$staged/.worktreeinclude').existsSync()) {
    _copyFile('$staged/.worktreeinclude', '.worktreeinclude');
  }
  if (File('$staged/.harness/team-protocol.md').existsSync()) {
    _copyFile('$staged/.harness/team-protocol.md', '.harness/team-protocol.md');
  }
  if (kept.isNotEmpty) {
    print(
      'Kept files the harness does not ship (yours):\n'
      '${kept.map((f) => '  $f').join('\n')}',
    );
  }

  // Tier 2 — memory: create only when missing.
  for (final f in [
    '.harness/active-context.md',
    '.harness/progress.md',
    '.harness/lessons.md',
  ]) {
    if (!File(f).existsSync()) _copyFile('$staged/$f', f);
  }

  // Config you may have customised: add only when missing.
  for (final f in ['.claude/settings.json', '.mcp.json', '.cursor/mcp.json']) {
    if (File(f).existsSync()) {
      print('Kept your $f.');
    } else {
      _copyFile('$staged/$f', f);
    }
  }
  _reportSettings('$staged/.claude/settings.json');
  _reportMcpServers('$staged/.mcp.json');

  // Tier 3 — contracts.
  for (final f in ['AGENTS.md', 'CLAUDE.md']) {
    final template = File('$staged/$f').readAsStringSync();
    final existing = File(f).existsSync() ? File(f).readAsStringSync() : null;
    final merged = mergeContract(f, template, existing, vars);
    File(f).writeAsStringSync(merged);
    if (existing != null &&
        !existing.contains(marker) &&
        merged.contains(_keptHeading)) {
      print(
        '$f: lines your team wrote in sections the harness used to ship '
        'are under "$_keptHeading" — review them.',
      );
    }
  }

  // Manifest.
  final history = [...(manifest['history'] as List? ?? const [])];
  history.add({
    'from': current,
    'to': target,
    'at': DateTime.now().toUtc().toIso8601String(),
  });
  final stagedManifest = _readJson(File('$staged/.harness/version.json'));
  File('.harness/version.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      ...stagedManifest,
      // A project that points at its own fork or mirror keeps it; the
      // stock repositories follow the template (e.g. fork → upstream).
      if (!_stockRepos.contains(manifest['upstream_repo'] ?? _stockRepos.first))
        'upstream_repo': manifest['upstream_repo'],
      'vars': vars,
      if (manifest['installed_at'] != null)
        'installed_at': manifest['installed_at'],
      'managed_skills': shipped,
      'history': history,
    }),
  );

  _logTask(current, target);
  print('Upgraded harness $current → $target.');
  print('Run `dart run scripts/agent/verify.dart` to confirm.');
}

/// Writes every file the brick ships under [rel] and returns the project's
/// other files there, which are left alone.
List<String> _syncDir(String staged, String rel) {
  final from = Directory('$staged/$rel');
  if (!from.existsSync()) return const [];
  final shipped = <String>{};
  for (final file in from.listSync(recursive: true).whereType<File>()) {
    final sub = _relative(file.path, from.path);
    shipped.add(sub);
    _copyFile(file.path, '$rel/$sub');
  }
  return [
    for (final file in Directory(
      rel,
    ).listSync(recursive: true).whereType<File>())
      if (!shipped.contains(_relative(file.path, rel)))
        '$rel/${_relative(file.path, rel)}',
  ]..sort();
}

String _relative(String path, String root) =>
    path.substring(root.length + 1).replaceAll(r'\', '/');

void _deleteEmptyParents(Directory dir) {
  var d = dir;
  while (d.path != '.' &&
      d.existsSync() &&
      d.listSync().isEmpty &&
      !['.agents', '.claude', '.cursor', 'scripts'].contains(d.path)) {
    d.deleteSync();
    d = d.parent;
  }
}

/// Reports what the project's `.claude/settings.json` lacks or breaks
/// compared with the template: hooks that run a missing script, template
/// hooks it doesn't register, and template permissions it doesn't allow.
void _reportSettings(String templatePath) {
  final file = File('.claude/settings.json');
  if (!file.existsSync()) return;
  final mine = _readJson(file);
  final template = _readJson(File(templatePath));
  final commands = _hookCommands(mine);

  for (final command in commands) {
    for (final script in _projectScripts(command)) {
      if (!File(script).existsSync()) {
        print(
          'Warning: a hook in .claude/settings.json runs $script, which does '
          'not exist. Restore it (see the backup) or update the hook.',
        );
      }
    }
  }
  final missingHooks = _hookCommands(
    template,
  ).where((c) => !commands.contains(c)).toList();
  if (missingHooks.isNotEmpty) {
    print(
      'The template also registers these hook commands; add them to '
      '.claude/settings.json if you want them (see the brick\'s copy):\n'
      '${missingHooks.map((c) => '  $c').join('\n')}',
    );
  }
  final missing = _missingPermissions(templatePath, file.path);
  if (missing.isNotEmpty) {
    print(
      'The template also pre-approves these commands; add them to '
      'permissions.allow in .claude/settings.json if you want them:\n'
      '${missing.map((e) => '  "$e"').join(',\n')}',
    );
  }
}

void _reportMcpServers(String templatePath) {
  final file = File('.mcp.json');
  if (!file.existsSync() || !File(templatePath).existsSync()) return;
  final mine = _readJson(file);
  final template = _readJson(File(templatePath));
  final myServers = (mine['mcpServers'] as Map?)?.keys.toSet() ?? {};
  final templateServers = (template['mcpServers'] as Map?)?.keys.toSet() ?? {};
  final missing = templateServers.difference(myServers);
  if (missing.isNotEmpty) {
    print(
      'The template also registers these MCP servers in .mcp.json:\n'
      '${missing.map((s) => '  $s').join('\n')}',
    );
  }
}

Set<String> _hookCommands(Map<String, dynamic> settings) {
  final commands = <String>{};
  final hooks = settings['hooks'];
  if (hooks is! Map) return commands;
  for (final groups in hooks.values) {
    if (groups is! List) continue;
    for (final group in groups) {
      final entries = group is Map ? group['hooks'] : null;
      if (entries is! List) continue;
      for (final entry in entries) {
        final command = entry is Map ? entry['command'] : null;
        if (command is String) commands.add(command);
      }
    }
  }
  return commands;
}

/// Project-relative scripts a hook command runs (absolute paths skipped).
Iterable<String> _projectScripts(String command) sync* {
  final tokens = command
      .replaceAll(
        RegExp(r'\$\{?CLAUDE_PROJECT_DIR\}?|%CLAUDE_PROJECT_DIR%'),
        '@',
      )
      .split(RegExp(r'''[\s"']+'''));
  final script = RegExp(
    r'^@?[/\\]?((?:[\w.-]+[/\\])*[\w.-]+\.(?:dart|ps1|sh|py|js|mjs|ts))$',
  );
  for (final token in tokens) {
    final m = script.firstMatch(token);
    if (m == null) continue;
    final absolute = token.startsWith('/') || token.startsWith(r'\');
    if (absolute && !token.startsWith('@')) continue;
    yield m.group(1)!.replaceAll(r'\', '/');
  }
}

const marker = '<!-- harness:project-rules';
const _keptHeading = 'Kept from your previous version of this file';

/// Template head (up to and including the marker line) + the project's
/// own tail. Files from before 1.6.0 have no marker: what the team wrote is
/// recovered line by line and placed below the marker.
String mergeContract(
  String file,
  String template,
  String? existing, [
  Map<String, String> vars = const {},
]) {
  final templateMarker = template.indexOf(marker);
  if (existing == null || templateMarker == -1) return template;
  final head = template.substring(
    0,
    template.indexOf('\n', templateMarker) + 1,
  );

  final existingMarker = existing.indexOf(marker);
  if (existingMarker != -1) {
    return head +
        existing.substring(existing.indexOf('\n', existingMarker) + 1);
  }

  final custom = _legacyCustom(existing, vars);
  final templateTail = template.substring(head.length);
  if (custom.isEmpty) return template;
  return '$head\n$custom\n\n$templateTail';
}

/// What the team wrote in a pre-1.6 contract (or any file without the
/// marker). Sections the harness never shipped are kept whole. In sections
/// it did ship, every line no harness template ever contained is kept
/// under its old heading, so a rule added to "Hard Rules" survives too.
/// Imports of harness files are dropped: the new template adds them.
String _legacyCustom(String text, Map<String, String> vars) {
  final custom = <String>[];
  final kept = <String>[];
  String? heading = 'Top of the file';
  var shipped = true;
  var fence = false;
  var keptFence = false;

  void closeKeptFence() {
    if (keptFence) kept.add('```');
    keptFence = false;
  }

  for (final raw in text.replaceAll('\r\n', '\n').split('\n')) {
    final line = raw.trimRight();
    final trimmed = line.trim();
    if (!fence && line.startsWith('#') && RegExp(r'^#{1,2} ').hasMatch(line)) {
      closeKeptFence();
      final title = line.startsWith('# ');
      shipped = title || _isTemplateLine(trimmed, vars);
      if (!shipped) custom.add(line);
      heading = title ? 'Top of the file' : line.substring(3);
      continue;
    }
    if (trimmed.startsWith('```')) {
      fence = !fence;
      if (!shipped) custom.add(line);
      continue;
    }
    if (_isHarnessImport(trimmed)) continue;
    if (!shipped) {
      custom.add(line);
      continue;
    }
    if (trimmed.isEmpty || trimmed == '---' || _isTemplateLine(trimmed, vars)) {
      continue;
    }
    if (heading != null) {
      closeKeptFence();
      kept
        ..add('')
        ..add('### $heading');
      heading = null;
    }
    if (fence != keptFence) {
      kept.add('```');
      keptFence = fence;
    }
    kept.add(line);
  }
  closeKeptFence();

  // The old memory transclusion sat after a closing rule.
  while (custom.isNotEmpty &&
      (custom.last.trim().isEmpty || custom.last.trim() == '---')) {
    custom.removeLast();
  }
  return [
    ...custom,
    if (kept.isNotEmpty) ...[
      if (custom.isNotEmpty) '',
      '## $_keptHeading',
      '_Lines your team added to sections the harness used to ship. Move '
          'them where they belong, then delete this section._',
      ...kept,
    ],
  ].join('\n').trim();
}

bool _isHarnessImport(String line) =>
    line.startsWith('@') &&
    RegExp(
      r'^@(\./)?(AGENTS\.md|CLAUDE\.md|\.harness/|\.agents/|\.claude/)',
    ).hasMatch(line);

/// Whether [line] appeared in a harness `CLAUDE.md`/`AGENTS.md` template
/// before 1.6.0 (FNV-1a of the whitespace-normalised line; a rendered
/// project name or app id is put back into its placeholder first).
bool _isTemplateLine(String line, Map<String, String> vars) {
  final normal = line.trim().split(RegExp(r'\s+')).join(' ');
  if (_legacyTemplateLines.contains(_fnv1a(normal))) return true;
  var generic = normal;
  final byLength = vars.entries.toList()
    ..sort((a, b) => b.value.length.compareTo(a.value.length));
  // Built without a literal double brace: mason renders this file as a
  // mustache template and would eat one.
  const open = '{', close = '}';
  for (final MapEntry(:key, :value) in byLength) {
    if (value.isNotEmpty) {
      generic = generic.replaceAll(value, '$open$open$key$close$close');
    }
  }
  return generic != normal && _legacyTemplateLines.contains(_fnv1a(generic));
}

int _fnv1a(String s) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(s)) {
    hash = ((hash ^ byte) * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

/// Every line of the `CLAUDE.md` and `AGENTS.md` templates from 1.4.0 to
/// 1.5.1, hashed. Frozen: 1.6+ contracts carry the project-rules marker.
const _legacyTemplateLines = {
  0x008a0532,
  0x01689d4a,
  0x02930a9a,
  0x04cf6a0a,
  0x05fc6563,
  0x06e890e6,
  0x078a0f50,
  0x0792284c,
  0x0c9acbf9,
  0x0d4d346b,
  0x0d62e36d,
  0x0ea989cf,
  0x1181d72c,
  0x125b20af,
  0x177f1fe9,
  0x19699e55,
  0x1b219dfd,
  0x1b6e11d3,
  0x1f2eba73,
  0x1fa84404,
  0x1fda67a9,
  0x20e2ac67,
  0x22189180,
  0x24b982a1,
  0x262c2ed0,
  0x276f09e8,
  0x282342e4,
  0x288d5763,
  0x2ad1ef52,
  0x2c03a66e,
  0x2df793d6,
  0x2e39a724,
  0x2e59d481,
  0x2ec1ac5d,
  0x2ecdaf78,
  0x2fe1aaa8,
  0x30dd8d9e,
  0x3190235f,
  0x357f302b,
  0x366d895f,
  0x3739996e,
  0x39f14ff8,
  0x3bfe6aa9,
  0x3d6658a9,
  0x3f0bad66,
  0x3f8b6442,
  0x424990c5,
  0x43e77684,
  0x446eb446,
  0x46442f17,
  0x4c8ba77b,
  0x4d933aa4,
  0x4da5417a,
  0x51aa3250,
  0x530f4899,
  0x55912064,
  0x55a0a722,
  0x561bd96e,
  0x567f5017,
  0x578caae8,
  0x5963d2af,
  0x59fcab67,
  0x5b7e8e4c,
  0x5e6db6cd,
  0x5ec3dad7,
  0x6592864f,
  0x6649f702,
  0x6700d767,
  0x67b6068f,
  0x67d0abbf,
  0x6d89c4ae,
  0x6dbd18bb,
  0x6f432734,
  0x71bd0b4b,
  0x7364c328,
  0x7a5983cd,
  0x7b60f76a,
  0x7c1bf16e,
  0x7de22b4a,
  0x7f58fed0,
  0x7fafa8e4,
  0x7fce2bb7,
  0x82c0e101,
  0x83afa30a,
  0x842e50da,
  0x8476c137,
  0x84fe2224,
  0x8775d2ba,
  0x8d03d05e,
  0x8d563443,
  0x8d58963b,
  0x92cc6c42,
  0x93888dcd,
  0x99a43069,
  0x9b45514b,
  0x9fa35540,
  0xa1939a22,
  0xa1ba403c,
  0xa3208b86,
  0xa76f3131,
  0xa83a5132,
  0xa99ffa84,
  0xaac29ccb,
  0xac2bd388,
  0xade74a3f,
  0xb1d17b39,
  0xb6b1e345,
  0xb718c90a,
  0xb7985e1e,
  0xb7e64822,
  0xb8cbeab9,
  0xb9d86e2c,
  0xbb02cfeb,
  0xbbc0b1b3,
  0xbf202f2c,
  0xbf8cf033,
  0xc13755e0,
  0xc164acec,
  0xc16f90ac,
  0xc346c493,
  0xc6614d75,
  0xc8097cbe,
  0xc936c29f,
  0xc9d71ff9,
  0xca528186,
  0xcb9a5423,
  0xcc6e0b09,
  0xcd766e46,
  0xceae126a,
  0xd1b42062,
  0xd34478c1,
  0xd4025876,
  0xd4180b73,
  0xd5291d4b,
  0xd7f8a410,
  0xda600257,
  0xdb942f92,
  0xdba257db,
  0xdbf064a3,
  0xdc89176b,
  0xdd3d4534,
  0xe0673e2d,
  0xe18e0ef2,
  0xe2273e23,
  0xe44ff73d,
  0xe49758d1,
  0xe5bcd472,
  0xe6ff582c,
  0xec19cf8a,
  0xeeb97dd7,
  0xeee6a94f,
  0xeefa3cc5,
  0xf2529780,
  0xf6dbe12c,
  0xfaa8314b,
};

Map<String, String> _resolveVars(Map<String, dynamic> manifest) {
  final fromManifest =
      (manifest['vars'] as Map?)?.cast<String, dynamic>() ?? {};
  final name =
      fromManifest['project_name']?.toString() ??
      RegExp(
        r'^name:\s*(\w+)',
        multiLine: true,
      ).firstMatch(File('pubspec.yaml').readAsStringSync())?.group(1) ??
      'app';

  String? android = fromManifest['android_package_name']?.toString();
  String? ios = fromManifest['ios_bundle_id']?.toString();

  // Pre-1.6 projects: recover ids from the old CLAUDE.md, then the platforms.
  final claude = File('CLAUDE.md');
  if ((android == null || ios == null) && claude.existsSync()) {
    final m = RegExp(
      r'Android package: `([^`]+)`\. iOS bundle id: `([^`]+)`',
    ).firstMatch(claude.readAsStringSync());
    android ??= m?.group(1);
    ios ??= m?.group(2);
  }
  for (final gradle in [
    'android/app/build.gradle.kts',
    'android/app/build.gradle',
  ]) {
    if (android != null) break;
    final f = File(gradle);
    if (f.existsSync()) {
      android = RegExp(
        r'''applicationId\s*=?\s*["']([^"']+)["']''',
      ).firstMatch(f.readAsStringSync())?.group(1);
    }
  }
  final pbx = File('ios/Runner.xcodeproj/project.pbxproj');
  if (ios == null && pbx.existsSync()) {
    ios = RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);')
        .allMatches(pbx.readAsStringSync())
        .map((m) => m.group(1)!)
        .where((id) => !id.endsWith('RunnerTests'))
        .firstOrNull;
  }

  return {
    'project_name': name,
    'android_package_name': android ?? 'com.example.$name',
    'ios_bundle_id': ios ?? android ?? 'com.example.$name',
  };
}

Directory _backup() {
  final dir = Directory(
    '.harness/.backup_${DateTime.now().toUtc().millisecondsSinceEpoch}',
  )..createSync(recursive: true);
  for (final path in [
    'AGENTS.md',
    'CLAUDE.md',
    '.mcp.json',
    '.cursor/mcp.json',
    '.harness/active-context.md',
    '.claude',
    '.agents',
    '.cursor',
    'scripts/agent',
    'scripts/team',
  ]) {
    final type = FileSystemEntity.typeSync(path);
    if (type == FileSystemEntityType.file) {
      _copyFile(path, '${dir.path}/$path');
    } else if (type == FileSystemEntityType.directory) {
      _replaceDir(Directory(path), Directory('${dir.path}/$path'));
    }
  }
  // Keep the three most recent backups.
  final backups =
      Directory('.harness')
          .listSync()
          .whereType<Directory>()
          .where((d) => d.path.contains('.backup_'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));
  for (final old in backups.skip(3)) {
    old.deleteSync(recursive: true);
  }
  return dir;
}

void _logTask(String from, String to) {
  final file = File('.harness/active-context.md');
  if (!file.existsSync()) return;
  final entry =
      '- chore(harness): upgraded $from → $to (file:.harness/version.json)';
  var text = file.readAsStringSync().replaceAll('\r\n', '\n');
  if (text.contains('_No tasks completed yet._')) {
    text = text.replaceFirst('_No tasks completed yet._', entry);
  } else {
    text = text.replaceFirst('## Recent Tasks\n', '## Recent Tasks\n$entry\n');
  }
  file.writeAsStringSync(text);
}

/// Skill folders (those with a `SKILL.md`) directly under [root], sorted.
List<String> _skillNames(String root) {
  final dir = Directory(root);
  if (!dir.existsSync()) return [];
  return dir
      .listSync()
      .whereType<Directory>()
      .where((d) => File('${d.path}/SKILL.md').existsSync())
      .map((d) => d.uri.pathSegments.where((s) => s.isNotEmpty).last)
      .toList()
    ..sort();
}

/// Template `permissions.allow` entries missing from the project's file.
List<String> _missingPermissions(String template, String mine) {
  List<String> allow(String path) {
    final permissions = _readJson(File(path))['permissions'];
    final list = permissions is Map ? permissions['allow'] : null;
    return list is List ? list.map((e) => e.toString()).toList() : const [];
  }

  final have = allow(mine).toSet();
  return allow(template).where((e) => !have.contains(e)).toList();
}

const _skipBackupDirNames = {
  'worktrees',
  '.git',
  '.dart_tool',
  'build',
};

void _replaceDir(Directory from, Directory to) {
  if (!from.existsSync()) return;
  if (to.existsSync()) to.deleteSync(recursive: true);
  to.createSync(recursive: true);
  _copyDirRecursive(from, to);
}

void _copyDirRecursive(Directory from, Directory to) {
  try {
    for (final entity in from.listSync(followLinks: false)) {
      final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (_skipBackupDirNames.contains(name) || name.startsWith('.backup_')) {
        continue;
      }
      final dest = '${to.path}/$name';
      if (entity is File) {
        _copyFile(entity.path, dest);
      } else if (entity is Directory) {
        Directory(dest).createSync(recursive: true);
        _copyDirRecursive(entity, Directory(dest));
      }
    }
  } on FileSystemException {
    // Gracefully ignore unreadable or path-length-exceeded entities in non-managed trees.
  }
}

void _copyFile(String from, String to) {
  final src = File(from);
  if (!src.existsSync()) return;
  File(to).parent.createSync(recursive: true);
  src.copySync(to);
}

Map<String, dynamic> _readJson(File file) {
  if (!file.existsSync()) return {};
  try {
    return (jsonDecode(file.readAsStringSync()) as Map).cast<String, dynamic>();
  } catch (_) {
    return {};
  }
}

/// Latest harness version published upstream: the `version:` in
/// `bricks/harness/brick.yaml` on the default branch, falling back to the
/// highest `v1.2.3` / `harness-v1.2.3` tag. Null when neither is reachable.
Future<String?> _latestUpstreamVersion(String repo) async {
  final gh = RegExp(
    r'github\.com[/:]([^/]+)/([^/]+?)(?:\.git)?/?$',
  ).firstMatch(repo);
  if (gh != null) {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(
        Uri.parse(
          'https://raw.githubusercontent.com/${gh[1]}/${gh[2]}/HEAD/bricks/harness/brick.yaml',
        ),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final version = RegExp(
          r'^version:\s*(\S+)',
          multiLine: true,
        ).firstMatch(body)?.group(1);
        if (version != null) return version;
      }
    } catch (_) {
      // Fall through to tags.
    } finally {
      client.close(force: true);
    }
  }

  try {
    final r = await Process.run(
      'git',
      [
        '-c',
        'credential.helper=',
        '-c',
        'core.askPass=',
        'ls-remote',
        '--tags',
        repo,
      ],
      environment: const {
        'GIT_TERMINAL_PROMPT': '0',
        // An IDE terminal (VS Code and forks) exports its own GIT_ASKPASS,
        // which overrides core.askPass and waits on a GUI credential prompt.
        'GIT_ASKPASS': '',
        'SSH_ASKPASS': '',
        'GCM_INTERACTIVE': 'never',
      },
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => ProcessResult(0, 1, '', 'timeout'),
    );
    if (r.exitCode != 0) return null;
    final versions =
        RegExp(
            r'refs/tags/(?:harness-)?v?(\d+\.\d+\.\d+)$',
            multiLine: true,
          ).allMatches(r.stdout as String).map((m) => m.group(1)!).toList()
          ..sort(_compare);
    return versions.isEmpty ? null : versions.last;
  } catch (_) {
    return null;
  }
}

int _compare(String a, String b) {
  List<int> parts(String v) => v
      .split(RegExp(r'[-+]'))
      .first
      .split('.')
      .map((p) => int.tryParse(p) ?? 0)
      .toList();
  final pa = parts(a), pb = parts(b);
  for (var i = 0; i < 3; i++) {
    final x = i < pa.length ? pa[i] : 0, y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}
