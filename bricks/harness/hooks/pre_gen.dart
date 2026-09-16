import 'dart:io';
import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  final currentProjectName =
      (context.vars['project_name'] as String?)?.trim() ?? '';

  if (currentProjectName.isEmpty) {
    final pubspecFile = File('pubspec.yaml');
    if (pubspecFile.existsSync()) {
      try {
        final content = pubspecFile.readAsStringSync();
        final match = RegExp(r'^name:\s*([a-zA-Z0-9_]+)', multiLine: true)
            .firstMatch(content);
        if (match != null) {
          final detected = match.group(1)!;
          context.vars['project_name'] = detected;
          context.logger.info('Auto-detected project_name: $detected');
        }
      } catch (e) {
        context.logger
            .warn('Could not read project name from pubspec.yaml: $e');
      }
    } else {
      context.logger.err(
        'pubspec.yaml not found in current directory. '
        'Please run `mason make harness` from the root of your Flutter project.',
      );
      exit(1);
    }
  }
}
