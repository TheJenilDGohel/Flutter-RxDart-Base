import 'dart:io';

import 'package:mason/mason.dart';

final _validFeature = RegExp(r'^[a-z][a-z0-9_]*$');

Future<void> run(HookContext context) async {
  final rawFeature = (context.vars['feature_name'] as String? ?? '').trim();
  final feature = rawFeature.snakeCase;
  if (!_validFeature.hasMatch(feature)) {
    context.logger.err(
      'feature_name "$rawFeature" is not a valid Dart file/identifier name. '
      'Use snake_case, e.g. user_profile.',
    );
    exit(1);
  }
  if (Directory('lib/features/$feature').existsSync()) {
    context.logger.warn(
      'lib/features/$feature already exists; conflicting files follow '
      'mason\'s --on-conflict policy.',
    );
  }
  context.vars = {...context.vars, 'feature_name': feature};

  final currentProjectName =
      (context.vars['project_name'] as String?)?.trim() ?? '';

  if (currentProjectName.isEmpty) {
    final pubspecFile = File('pubspec.yaml');
    if (pubspecFile.existsSync()) {
      try {
        final content = pubspecFile.readAsStringSync();
        final match = RegExp(
          r'^name:\s*([a-zA-Z0-9_]+)',
          multiLine: true,
        ).firstMatch(content);
        if (match != null) {
          final detected = match.group(1)!;
          context.vars['project_name'] = detected;
          context.logger.info('Auto-detected project_name: $detected');
        }
      } catch (e) {
        context.logger.warn(
          'Could not read project name from pubspec.yaml: $e',
        );
      }
    } else {
      context.logger.err(
        'pubspec.yaml not found in current directory. '
        'Please run `mason make bloc` from the root of your Flutter project.',
      );
      exit(1);
    }
  }
}
