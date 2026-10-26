import 'dart:io';

import 'package:mason/mason.dart';

final _snakeCase = RegExp(r'^[a-z][a-z0-9_]*$');
final _androidPackage = RegExp(
  r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$',
);
final _iosBundleId = RegExp(r'^[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)+$');

/// Validates everything before Mason writes a single file, so a bad input
/// never leaves a half-scaffolded project behind.
void run(HookContext context) {
  final errors = <String>[];

  final projectName = (context.vars['project_name'] as String? ?? '').trim();
  if (!_snakeCase.hasMatch(projectName)) {
    errors.add('project_name "$projectName" must be snake_case (e.g. my_app).');
  }

  final androidPackage =
      (context.vars['android_package_name'] as String? ?? '').trim();
  if (!_androidPackage.hasMatch(androidPackage)) {
    errors.add(
      'android_package_name "$androidPackage" must be reverse-domain notation '
      '(e.g. com.example.my_app).',
    );
  }

  final rawIos = (context.vars['ios_bundle_id'] as String? ?? '').trim();
  final requestedIos = rawIos.isEmpty ? androidPackage : rawIos;
  // Apple bundle ids cannot contain underscores; normalise instead of failing.
  final iosBundleId = requestedIos.replaceAll('_', '-');
  if (iosBundleId != requestedIos) {
    context.logger.warn(
      'iOS bundle ids cannot contain "_": using "$iosBundleId".',
    );
  }
  if (!_iosBundleId.hasMatch(iosBundleId)) {
    errors.add(
      'ios_bundle_id "$iosBundleId" may only contain letters, digits, '
      'hyphens and dots (e.g. com.example.my-app).',
    );
  }

  final pubspec = File('pubspec.yaml');
  if (!Directory('android').existsSync() ||
      !Directory('ios').existsSync() ||
      !pubspec.existsSync()) {
    errors.add(
      'No Flutter project detected in the current directory '
      '(missing pubspec.yaml, android/ or ios/). Run `flutter create <app_name>`, '
      '`cd` into it and re-run `mason make project`.',
    );
  } else {
    final nameLine = RegExp(
      r'^name:\s*(\S+)',
      multiLine: true,
    ).firstMatch(pubspec.readAsStringSync());
    final existingName = nameLine?.group(1);
    if (existingName != null && existingName != projectName) {
      errors.add(
        'project_name "$projectName" does not match the existing pubspec '
        'name "$existingName". Package imports would not resolve.',
      );
    }
  }

  if (errors.isNotEmpty) {
    for (final e in errors) {
      context.logger.err(e);
    }
    exit(1);
  }

  context.vars = {
    ...context.vars,
    'project_name': projectName,
    'android_package_name': androidPackage,
    'ios_bundle_id': iosBundleId,
  };
}
