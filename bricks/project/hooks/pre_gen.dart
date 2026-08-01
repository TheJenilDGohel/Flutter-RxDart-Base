import 'dart:io';

import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  final projectName = context.vars['project_name'] as String;
  final androidPackageName = context.vars['android_package_name'] as String;
  var iosBundleId = context.vars['ios_bundle_id'] as String? ?? '';

  // ── 1. Verify Flutter project exists ──────────────────────────────────
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    context.logger.err(
      'No Flutter project detected.\n'
      'pubspec.yaml not found in the current directory.\n'
      'Run `flutter create $projectName` first, then re-run this brick '
      'from inside it.',
    );
    exit(1);
  }
  final pubspecContent = pubspecFile.readAsStringSync();
  if (!pubspecContent.contains('flutter:')) {
    context.logger.err(
      'No Flutter project detected.\n'
      'pubspec.yaml exists but does not contain a `flutter:` key.\n'
      'Run `flutter create $projectName` first, then re-run this brick '
      'from inside it.',
    );
    exit(1);
  }

  // ── 2. Validate project_name is strict snake_case ─────────────────────
  final snakeCaseRegex = RegExp(r'^[a-z][a-z0-9_]*$');
  if (!snakeCaseRegex.hasMatch(projectName)) {
    context.logger.err(
      'Invalid project_name: "$projectName"\n'
      'Must be strict snake_case: lowercase letters, digits, underscores '
      'only, starting with a letter.\n'
      'Example: my_app',
    );
    exit(1);
  }

  // ── 3. Cross-check project_name against pubspec name: field ───────────
  final nameMatch =
      RegExp(r'^name:\s*(\S+)', multiLine: true).firstMatch(pubspecContent);
  if (nameMatch != null) {
    final pubspecName = nameMatch.group(1);
    if (pubspecName != projectName) {
      context.logger.warn(
        'WARNING: project_name "$projectName" does not match the `name:` '
        'field "$pubspecName" in pubspec.yaml.\n'
        'This usually means you typed the wrong name. Proceeding anyway.',
      );
    }
  }

  // ── 4. Default ios_bundle_id to android_package_name if blank ─────────
  if (iosBundleId.trim().isEmpty) {
    iosBundleId = androidPackageName;
    context.vars['ios_bundle_id'] = iosBundleId;
    context.logger.info('ios_bundle_id defaulted to: $iosBundleId');
  }

  // ── 5. Validate reverse-domain patterns ───────────────────────────────
  final reverseDomainRegex =
      RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$');

  if (!reverseDomainRegex.hasMatch(androidPackageName)) {
    context.logger.err(
      'Invalid android_package_name: "$androidPackageName"\n'
      'Must be reverse-domain format (e.g. com.example.myapp).',
    );
    exit(1);
  }
  if (!reverseDomainRegex.hasMatch(iosBundleId)) {
    context.logger.err(
      'Invalid ios_bundle_id: "$iosBundleId"\n'
      'Must be reverse-domain format (e.g. com.example.myapp).',
    );
    exit(1);
  }

  context.logger.success('All validations passed ✓');
}
