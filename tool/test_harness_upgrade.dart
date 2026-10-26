import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// End-to-end test of the harness's real `scripts/agent/upgrade.dart`
/// against a pre-1.6 project carrying team customisations, as real
/// projects do: their own scripts in `scripts/agent/`, rules added inside
/// the old template sections, a `mason.yaml` pinning an old harness brick
/// and a `.claude/settings.json` with a hook of their own.
///
/// The "upstream" is a local git repository holding this checkout's harness
/// brick, so the default render path (a throwaway mason workspace naming
/// `upstream_repo`) is exercised without network.
///
/// Run from the repository root: `dart run tool/test_harness_upgrade.dart`.
Future<void> main() async {
  final root = Directory.current.path;
  final app = Directory(p.join(root, 'temp_upgrade_test'));
  if (app.existsSync()) app.deleteSync(recursive: true);
  app.createSync(recursive: true);

  final failures = <String>[];
  void check(String name, bool ok, [String detail = '']) {
    print('${ok ? 'PASS' : 'FAIL'}  $name');
    if (!ok) {
      failures.add(name);
      if (detail.isNotEmpty) print(detail);
    }
  }

  String read(String rel) => File(p.join(app.path, rel)).readAsStringSync();
  bool exists(String rel) => File(p.join(app.path, rel)).existsSync();
  void write(String rel, String content) => File(p.join(app.path, rel))
    ..createSync(recursive: true)
    ..writeAsStringSync(content);
  int count(String haystack, String needle) =>
      needle.allMatches(haystack).length;
  Future<ProcessResult> run(String exe, List<String> args, String dir) =>
      Process.run(exe, args, workingDirectory: dir, runInShell: true);
  Future<ProcessResult> upgrade([List<String> args = const []]) =>
      run('dart', ['run', 'scripts/agent/upgrade.dart', ...args], app.path);
  String out(ProcessResult r) => '${r.stdout}${r.stderr}';

  final brickDir = p.join(root, 'bricks/harness');
  final brickVersion = RegExp(r'^version:\s*(\S+)', multiLine: true)
      .firstMatch(File(p.join(brickDir, 'brick.yaml')).readAsStringSync())!
      .group(1);
  final fixture = p.join(root, 'tool/fixtures/harness_1.5.1');

  try {
    // ── Upstream: a git repository with this checkout's harness brick ───
    final upstream = Directory(p.join(app.path, '_upstream'));
    _copyDir(Directory(brickDir),
        Directory(p.join(upstream.path, 'bricks/harness')));
    for (final args in [
      ['init', '-q'],
      ['add', '.'],
      ['-c', 'user.email=t@t', '-c', 'user.name=t', 'commit', '-qm', 'harness'],
    ]) {
      await run('git', args, upstream.path);
    }
    final upstreamUrl = Uri.directory(upstream.path).toString();

    // ── A legacy (1.5.1) project with team customisations ──────────────
    write('pubspec.yaml', 'name: legacy_app\nenvironment:\n  sdk: ^3.13.0\n');
    write(
        'scripts/agent/upgrade.dart',
        File(p.join(brickDir, '__brick__/scripts/agent/upgrade.dart'))
            .readAsStringSync());
    write('scripts/agent/check_ids.dart', '// team id-drift check\n');
    write('scripts/agent/stop-gate.ps1', '# team stop gate\n');
    write(
        '.harness/version.json',
        jsonEncode({
          'brick': 'harness',
          'version': '1.5.0',
          'installed_at': '2026-01-01T00:00:00Z',
          'upstream_repo': upstreamUrl,
        }));
    const memory = '''# Active Context

## Current Focus
Migrating checkout to Stripe PaymentSheet.

## Recent Tasks
- feat(payment): scaffold payment_bloc (commit:a1b2c3d)

## Key Decisions
- PaymentIntents API, not Charges.

## Known Issues
- 3DS takes 4s on the Android emulator.
''';
    write('.harness/active-context.md', memory);
    write('.harness/progress.md', '# Progress Log\n[2026-01-01] chore: init\n');

    // CLAUDE.md as 1.5.1 rendered it, plus team edits inside its sections.
    write(
        'CLAUDE.md',
        File(p.join(fixture, 'CLAUDE.md'))
            .readAsStringSync()
            .replaceFirst(
              '└── features/<name>/',
              '├── flavors/           # FlavorConfig per flavor (team)\n'
                  '└── features/<name>/',
            )
            .replaceFirst(
              '## QA & Review Defaults',
              '- Build-time config lives in FlavorConfig, never in .env.\n\n'
                  '## Team Notes\n'
                  'Always talk to the payments team before touching checkout.\n\n'
                  '## QA & Review Defaults',
            ));
    write(
        'AGENTS.md',
        '${File(p.join(fixture, 'AGENTS.md')).readAsStringSync().replaceFirst('## 3. Backend API Discovery', '13. **White-label**: brand and asset work goes through the white-label pipeline.\n\n## 3. Backend API Discovery')}'
            '\n## 8. Payments\nNever log card numbers.\n');

    // Files older harness versions shipped, and one the team added.
    write('.agents/agents/flutter-qa.md', 'legacy qa agent');
    write('.cursor/skills/flutter-senior-dev/SKILL.md', 'stale mirror');
    write('.agents/skills/flutter-senior-dev/references/architecture.md',
        'old location');
    write('.agents/skills/flutter-senior-dev/team-notes.md', 'our notes');
    write('.agents/skills/team-payments/SKILL.md',
        '---\nname: team-payments\ndescription: ours\n---\n');

    // A project mason.yaml pinning an old harness brick.
    write('old_brick/brick.yaml', '''
name: harness
description: An old harness.
version: 1.0.0
vars:
  project_name:
    type: string
  android_package_name:
    type: string
  ios_bundle_id:
    type: string
''');
    write('old_brick/__brick__/.harness/version.json',
        '{"brick": "harness", "version": "1.0.0"}');
    write('mason.yaml', 'bricks:\n  harness:\n    path: old_brick\n');
    await run('mason', ['get'], app.path);

    // ── Upgrade ─────────────────────────────────────────────────────────
    var r = await upgrade();
    print(r.stdout);
    if (r.exitCode != 0) print(r.stderr);
    check('upgrade exits 0', r.exitCode == 0);
    check('renders from upstream, not the project mason.yaml pin',
        out(r).contains('Rendered harness $brickVersion from $upstreamUrl'));

    var manifest = jsonDecode(read('.harness/version.json')) as Map;
    check('manifest stamped with brick version $brickVersion',
        manifest['version'] == brickVersion);
    check('manifest keeps installed_at',
        manifest['installed_at'] == '2026-01-01T00:00:00Z');
    check(
        'manifest records history', (manifest['history'] as List).length == 1);
    check('android id recovered from legacy CLAUDE.md',
        (manifest['vars'] as Map)['android_package_name'] == 'com.acme.legacy');

    final claude = read('CLAUDE.md');
    check('CLAUDE.md imports AGENTS.md', claude.contains('@AGENTS.md'));
    check('CLAUDE.md keeps real ids', claude.contains('com.acme.legacy-ios'));
    check(
        'CLAUDE.md keeps team notes once', count(claude, '## Team Notes') == 1);
    check(
        'CLAUDE.md keeps a rule added inside a shipped section',
        count(claude,
                'Build-time config lives in FlavorConfig, never in .env.') ==
            1,
        claude);
    check(
        'CLAUDE.md keeps a line added inside a shipped code block, fenced',
        RegExp(r'```\n├── flavors/ +# FlavorConfig per flavor \(team\)\n```')
            .hasMatch(claude),
        claude);
    check(
        'CLAUDE.md drops the old template lines',
        !claude.contains('Flutter · Redux (global session state)') &&
            !claude.contains('**Repository is transport ONLY**') &&
            !claude.contains('Android package: `com.acme.legacy`'),
        claude);
    check('CLAUDE.md transcludes memory exactly once',
        count(claude, '@.harness/active-context.md') == 1);
    check('CLAUDE.md team lines sit below the project-rules marker',
        claude.indexOf('harness:project-rules') < claude.indexOf('Team Notes'));

    final agents = read('AGENTS.md');
    check('AGENTS.md has new template',
        agents.contains('## 4. Tooling for Agents'));
    check('AGENTS.md keeps custom section once',
        count(agents, '## 8. Payments') == 1);
    check('AGENTS.md keeps a rule added inside the old golden rules',
        agents.contains('**White-label**: brand and asset work'), agents);
    check(
        'AGENTS.md drops the old template lines',
        !agents.contains('MUST ONLY call `ApiBaseHelper` and return raw') &&
            !agents.contains('## 1. Architecture: Hybrid Redux + RxDart + Dio\n'
                '- **Redux (Global)**'),
        agents);
    check('AGENTS.md has project-rules marker',
        agents.contains('harness:project-rules'));

    final context = read('.harness/active-context.md');
    check(
        'memory preserved',
        context.contains('Stripe PaymentSheet') &&
            context.contains('3DS takes 4s'));
    check('upgrade logged in Recent Tasks',
        context.contains('chore(harness): upgraded 1.5.0'));
    check('progress log untouched',
        read('.harness/progress.md').contains('[2026-01-01] chore: init'));

    check(
        "the team's scripts in scripts/agent/ are kept and reported",
        exists('scripts/agent/check_ids.dart') &&
            exists('scripts/agent/stop-gate.ps1') &&
            out(r).contains('scripts/agent/check_ids.dart'));
    check('a team file inside a shipped skill folder is kept',
        read('.agents/skills/flutter-senior-dev/team-notes.md') == 'our notes');
    check(
        'files older harness versions shipped are removed',
        !exists('.agents/agents/flutter-qa.md') &&
            !exists('.cursor/skills/flutter-senior-dev/SKILL.md') &&
            !exists(
                '.agents/skills/flutter-senior-dev/references/architecture.md') &&
            exists('.claude/agents/flutter-qa.md'));
    check(
        'Claude skill + settings + MCP config added',
        exists('.claude/skills/flutter-senior-dev/SKILL.md') &&
            exists('.claude/settings.json') &&
            exists('.mcp.json'));

    final shipped = Directory(p.join(brickDir, '__brick__/.agents/skills'))
        .listSync()
        .whereType<Directory>()
        .map((d) => p.basename(d.path))
        .toList()
      ..sort();
    check(
        'every shipped skill installed for all agents and Claude Code',
        shipped.length >= 8 &&
            shipped.every((s) =>
                exists('.agents/skills/$s/SKILL.md') &&
                exists('.claude/skills/$s/SKILL.md')));
    check('manifest records managed_skills',
        (manifest['managed_skills'] as List).join(',') == shipped.join(','));
    check('project-created skill untouched',
        read('.agents/skills/team-payments/SKILL.md').contains('ours'));
    check('lessons store created for old projects',
        read('.harness/lessons.md').contains('## Active'));
    check('learn.dart installed', exists('scripts/agent/learn.dart'));

    final backups = Directory(p.join(app.path, '.harness'))
        .listSync()
        .whereType<Directory>()
        .where((d) => d.path.contains('.backup_'));
    check(
        'backup holds the old CLAUDE.md',
        backups.any((d) => File(p.join(d.path, 'CLAUDE.md'))
            .readAsStringSync()
            .contains('Project Memory')));
    check('staging cleaned up',
        !Directory(p.join(app.path, '.harness/.staging_upgrade')).existsSync());

    // ── Idempotency ─────────────────────────────────────────────────────
    write(
        'CLAUDE.md', '${read('CLAUDE.md')}\n## Added After Upgrade\nkeep me\n');
    r = await upgrade();
    check('second run is a no-op',
        r.exitCode == 0 && out(r).contains('Already on $brickVersion'), out(r));

    // --check-only must never claim "up to date" when it couldn't look.
    final manifestPath = p.join(app.path, '.harness', 'version.json');
    final realManifest = File(manifestPath).readAsStringSync();
    final offline = (jsonDecode(realManifest) as Map)
      ..['upstream_repo'] = 'https://github.com/nobody-xyz-404/missing.git';
    File(manifestPath).writeAsStringSync(jsonEncode(offline));
    r = await upgrade(['--check-only']);
    check(
        '--check-only reports an unreachable upstream honestly',
        out(r).contains('Could not determine') &&
            !out(r).contains('up to date'));
    File(manifestPath).writeAsStringSync(realManifest);

    // A source older than what is installed changes nothing.
    r = await upgrade(['--brick', p.join(app.path, 'old_brick')]);
    check(
        'never downgrades without --force',
        out(r).contains('older than the installed') &&
            (jsonDecode(read('.harness/version.json')) as Map)['version'] ==
                brickVersion,
        out(r));

    // ── Re-apply with a locally edited engine ───────────────────────────
    const learned = '# Lessons\n\n## Active\n'
        '- [L1] add-endpoint (2x, 2026-10-01): Dates are epoch seconds.\n'
        '\n## Promoted\n_None yet._\n';
    write('.harness/lessons.md', learned);
    write('.harness/skills/add-feature.md', '# add-feature additions\n');
    write('.agents/skills/retired-skill/SKILL.md', 'old');
    write('.claude/skills/retired-skill/SKILL.md', 'old');
    final stamped = jsonDecode(File(manifestPath).readAsStringSync()) as Map;
    stamped['managed_skills'] = [
      ...stamped['managed_skills'] as List,
      'retired-skill'
    ];
    File(manifestPath).writeAsStringSync(jsonEncode(stamped));
    write(
        '.claude/settings.json',
        jsonEncode({
          'permissions': {
            'allow': ['Bash(flutter test:*)']
          },
          'hooks': {
            'Stop': [
              {
                'hooks': [
                  {
                    'type': 'command',
                    'command':
                        'powershell -File "\$CLAUDE_PROJECT_DIR/scripts/agent/stop-gate-old.ps1"',
                  }
                ]
              }
            ]
          },
        }));
    write('scripts/agent/upgrade.dart',
        '${read('scripts/agent/upgrade.dart')}\n// edited locally\n');

    r = await upgrade(['--force', '--brick', brickDir]);
    check('a different engine hands over to the shipped one',
        r.exitCode == 0 && out(r).contains('Handing over to the'), out(r));
    check('the shipped engine replaced the edited one',
        !read('scripts/agent/upgrade.dart').contains('edited locally'));
    check('lessons kept verbatim', read('.harness/lessons.md') == learned);
    check('skill overlay kept',
        read('.harness/skills/add-feature.md') == '# add-feature additions\n');
    check(
        'a skill the harness no longer ships is removed',
        !exists('.agents/skills/retired-skill/SKILL.md') &&
            !exists('.claude/skills/retired-skill/SKILL.md') &&
            exists('.agents/skills/team-payments/SKILL.md'));
    check('a hook running a missing script is reported',
        out(r).contains('runs scripts/agent/stop-gate-old.ps1'), out(r));
    check(
        'missing template hooks and permissions are listed, settings kept',
        out(r).contains('learn.dart') &&
            read('.claude/settings.json').contains('flutter test'));
    check('team scripts survive a forced re-apply too',
        exists('scripts/agent/check_ids.dart'));

    final forced = read('CLAUDE.md');
    check('--force keeps everything below the marker',
        forced.contains('keep me') && count(forced, '## Team Notes') == 1);
    check('--force does not duplicate the transclusion',
        count(forced, '@.harness/active-context.md') == 1);
    check('--force keeps AGENTS.md custom section once',
        count(read('AGENTS.md'), '## 8. Payments') == 1);
  } finally {
    if (app.existsSync()) {
      try {
        app.deleteSync(recursive: true);
      } catch (_) {}
    }
  }

  if (failures.isEmpty) {
    print('\nAll harness upgrade checks passed.');
  } else {
    stderr.writeln('\n${failures.length} check(s) failed.');
    exitCode = 1;
  }
}

void _copyDir(Directory from, Directory to) {
  for (final file in from.listSync(recursive: true).whereType<File>()) {
    final target = File(p.join(to.path, p.relative(file.path, from: from.path)))
      ..parent.createSync(recursive: true);
    file.copySync(target.path);
  }
}
