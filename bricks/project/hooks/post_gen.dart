import 'dart:io';

import 'package:mason/mason.dart';

/// Lines merged into the app's existing `.gitignore` (never replaced, so the
/// `flutter create` defaults such as build/ and .dart_tool/ survive).
const _gitignoreLines = [
  '# AI Harness pre-flight safety backups',
  '.harness/.backup_*',
  '.harness/backup_*',
];

Future<void> run(HookContext context) async {
  // Inputs were validated and normalised in pre_gen.
  final androidPackageName = context.vars['android_package_name'] as String;
  final iosBundleId = context.vars['ios_bundle_id'] as String;

  final progress = context.logger.progress('Resolving dependencies');

  Future<bool> step(String label, String exe, List<String> args) async {
    final result = await Process.run(exe, args, runInShell: true);
    if (result.exitCode != 0) {
      progress.fail('$label failed');
      context.logger.err('${result.stdout}\n${result.stderr}');
      context.logger.info(
        'Generated files were kept. Fix the error above and re-run:\n'
        '  $exe ${args.join(' ')}',
      );
      return false;
    }
    return true;
  }

  if (!await step('flutter pub get', 'flutter', ['pub', 'get']) ||
      !await step('flutter gen-l10n', 'flutter', ['gen-l10n']) ||
      !await step('Android package rename', 'dart', [
        'run',
        'change_app_package_name:main',
        androidPackageName,
        '--android',
      ])) {
    exit(1);
  }

  final removeResult = await Process.run(
      'flutter',
      [
        'pub',
        'remove',
        'change_app_package_name',
      ],
      runInShell: true);
  if (removeResult.exitCode != 0) {
    context.logger.warn(
      'Could not remove the one-shot change_app_package_name dev dependency; '
      'remove it from pubspec.yaml manually.',
    );
  }

  if (!_applyIosBundleId(iosBundleId)) {
    context.logger.warn(
      'ios/Runner.xcodeproj/project.pbxproj not found; set the iOS bundle id '
      '($iosBundleId) in Xcode.',
    );
  }
  _mergeGitignore();

  progress.complete(
    'Dependencies resolved, localizations generated, '
    'Android ($androidPackageName) and iOS ($iosBundleId) ids applied.',
  );

  final includeHarness = context.vars['include_harness'] as bool? ?? true;
  if (includeHarness) {
    final harnessProgress = context.logger.progress(
      'Scaffolding AI Agent Harness',
    );
    final harnessResult = await Process.run(
        'mason',
        [
          'make',
          'harness',
          '--project_name',
          context.vars['project_name'] as String,
          '--android_package_name',
          androidPackageName,
          '--ios_bundle_id',
          iosBundleId,
          // Never clobber a CLAUDE.md / AGENTS.md the team already edited.
          '--on-conflict',
          'skip',
        ],
        runInShell: true);

    if (harnessResult.exitCode == 0) {
      harnessProgress.complete('AI Agent Harness installed.');
    } else {
      harnessProgress.cancel();
      context.logger.warn(
        'AI Agent Harness was not scaffolded (is the `harness` brick '
        'registered with mason?). Install it anytime with `mason make harness`.',
      );
    }
  }

  // Templates are rendered through mustache, and the formatter's style
  // depends on the app's language version, so format everything generated
  // (including harness scripts) with the user's own SDK. Runs last so the
  // harness files are included; the harness quality gate checks it.
  final targets = ['lib', 'test', 'scripts'].where(
    (d) => Directory(d).existsSync(),
  );
  final formatResult = await Process.run(
      'dart',
      [
        'format',
        ...targets,
      ],
      runInShell: true);
  if (formatResult.exitCode != 0) {
    context.logger.warn('dart format failed: ${formatResult.stderr}');
  }

  context.logger.success('\n🎉 Project bootstrap complete!');
  context.logger.info(
    'Run `mason make bloc` next to scaffold your first feature module.\n',
  );
}

void _mergeGitignore() {
  final file = File('.gitignore');
  final existing = file.existsSync() ? file.readAsStringSync() : '';
  final present = existing.split('\n').map((l) => l.trim()).toSet();
  final missing = _gitignoreLines.where((l) => !present.contains(l)).toList();
  if (missing.isEmpty) return;
  final prefix = existing.isEmpty || existing.endsWith('\n') ? '' : '\n';
  file.writeAsStringSync('$existing$prefix\n${missing.join('\n')}\n');
}

/// Sets the Runner bundle id and keeps the `.RunnerTests` suffix on the
/// test target, so the two targets never share an identifier.
bool _applyIosBundleId(String bundleId) {
  final file = File('ios/Runner.xcodeproj/project.pbxproj');
  if (!file.existsSync()) return false;
  final updated = file.readAsStringSync().replaceAllMapped(
        RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = [^;]*?(\.RunnerTests)?;'),
        (m) => 'PRODUCT_BUNDLE_IDENTIFIER = $bundleId${m.group(1) ?? ''};',
      );
  file.writeAsStringSync(updated);
  return true;
}
