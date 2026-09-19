import 'dart:io';
import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  final progress = context.logger.progress('Formatting harness scripts');
  await Process.run('dart', ['format', 'scripts/agent/'], runInShell: true);
  progress.complete('Harness scripts formatted.');

  final lintWired = _wireLintPlugin(context);

  final harnessDir = Directory('.harness');
  if (!harnessDir.existsSync()) {
    harnessDir.createSync();
    context.logger.info('  ✔ Created .harness directory for cross-session AI context.');
  }

  // Mirror the universal skill into Cursor's discovery path so both
  // .agents/skills/ (Antigravity, Gemini, universal) and .cursor/skills/
  // (Cursor IDE) auto-discover the same content from one source.
  _mirrorSkill(context);

  context.logger.success('\n🤖 AI Agent Harness installed successfully!');
  context.logger.info(
    '  - AGENTS.md: Universal cognitive contract for all AI tools (Cursor, Claude Code, Copilot, etc.)\n'
    '  - .harness/: Token-efficient cross-session project context (snapshot + handoff log)\n'
    '  - CLAUDE.md: Native transclusion pointing to @AGENTS.md and @.harness/ files\n'
    '  - .agents/skills/flutter-senior-dev/: Universal skill (senior Flutter dev, auto-discovered)\n'
    '  - .cursor/skills/flutter-senior-dev/: Mirrored for Cursor IDE auto-discovery\n'
    '  - scripts/agent/wire_route.dart: Automated route wiring CLI (auto-scaffolds via `mason make bloc`)\n'
    '  - scripts/agent/verify.ps1 / verify.sh: Deterministic quality gate (format + analyze)\n'
    '\n'
    'Quick Start:\n'
    '  - Scaffold + wire a route: dart run scripts/agent/wire_route.dart <feature_name> [path]\n'
    '  - Run verification quality gate: ./scripts/agent/verify.ps1 (or verify.sh)\n'
    '${lintWired ? '  - Run `dart pub get` / `flutter pub get` to fetch the redux_rxdart_lints custom_lint plugin.\n' : ''}',
  );
}

/// Wires the redux_rxdart_lints custom_lint plugin (enforces Golden Rules
/// #1, #3, #4 from AGENTS.md at analyze time) into the consuming project's
/// pubspec.yaml + analysis_options.yaml. Returns true if anything changed.
bool _wireLintPlugin(HookContext context) {
  var changed = false;

  final pubspecFile = File('pubspec.yaml');
  if (pubspecFile.existsSync()) {
    var pubspec = pubspecFile.readAsStringSync();
    if (!pubspec.contains('redux_rxdart_lints')) {
      const snippet = '  custom_lint: ^0.7.6\n'
          '  redux_rxdart_lints:\n'
          '    git:\n'
          '      url: https://github.com/TheJenilDGohel/Flutter-RxDart-Base.git\n'
          '      path: packages/redux_rxdart_lints';

      final devDepsMatch = RegExp(
        r'^dev_dependencies:\s*$',
        multiLine: true,
      ).firstMatch(pubspec);

      pubspec = devDepsMatch != null
          ? pubspec.substring(0, devDepsMatch.end) +
              '\n$snippet' +
              pubspec.substring(devDepsMatch.end)
          : '$pubspec\ndev_dependencies:\n$snippet\n';

      pubspecFile.writeAsStringSync(pubspec);
      context.logger
          .info('  ✔ Added redux_rxdart_lints dev_dependency to pubspec.yaml');
      changed = true;
    }
  }

  final analysisFile = File('analysis_options.yaml');
  const pluginSnippet = '  plugins:\n    - custom_lint';
  if (analysisFile.existsSync()) {
    var analysis = analysisFile.readAsStringSync();
    if (!analysis.contains('custom_lint')) {
      final analyzerMatch = RegExp(
        r'^analyzer:\s*$',
        multiLine: true,
      ).firstMatch(analysis);

      analysis = analyzerMatch != null
          ? analysis.substring(0, analyzerMatch.end) +
              '\n$pluginSnippet' +
              analysis.substring(analyzerMatch.end)
          : 'analyzer:\n$pluginSnippet\n\n$analysis';

      analysisFile.writeAsStringSync(analysis);
      context.logger
          .info('  ✔ Enabled custom_lint plugin in analysis_options.yaml');
      changed = true;
    }
  } else {
    analysisFile.writeAsStringSync('analyzer:\n$pluginSnippet\n');
    context.logger
        .info('  ✔ Created analysis_options.yaml enabling custom_lint plugin');
    changed = true;
  }

  return changed;
}

/// Mirrors `.agents/skills/flutter-senior-dev/` into `.cursor/skills/` so
/// Cursor IDE auto-discovers the same skill that Antigravity, Gemini and
/// other `.agents/`-aware tools already see. Skips silently if the source
/// directory is missing (e.g. when only AGENTS.md is used).
void _mirrorSkill(HookContext context) {
  const skillName = 'flutter-senior-dev';
  final source = Directory('.agents/skills/$skillName');
  final target = Directory('.cursor/skills/$skillName');

  if (!source.existsSync()) return;

  target.createSync(recursive: true);

  for (final entity in source.listSync(recursive: true)) {
    final relativePath = entity.path.substring(source.path.length);
    if (entity is File) {
      final destFile = File('${target.path}$relativePath');
      destFile.parent.createSync(recursive: true);
      entity.copySync(destFile.path);
    }
  }

  context.logger.info('  ✔ Mirrored skill to .cursor/skills/$skillName/ for Cursor IDE.');
}
