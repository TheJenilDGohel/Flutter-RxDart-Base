import 'dart:io';

import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  final feature = (context.vars['feature_name'] as String).snakeCase;
  final libDir = 'lib/features/$feature';
  final testDir = 'test/features/$feature';

  // Format everything generated so `verify` passes on a fresh feature.
  final targets = [libDir, testDir].where((d) => Directory(d).existsSync());
  if (targets.isNotEmpty) {
    final result = await Process.run(
            'dart',
            [
              'format',
              ...targets,
            ],
            runInShell: true)
        .timeout(
      const Duration(seconds: 30),
      onTimeout: () => ProcessResult(0, 1, '', 'timed out'),
    );
    if (result.exitCode != 0) {
      context.logger.warn(
        'dart format did not complete (${result.stderr}). '
        'Run `dart format $libDir $testDir` manually.',
      );
    }
  }

  context.logger.success('🎉 Feature `$feature` scaffolded in `$libDir`.');
  context.logger.info(
    '\nNext steps:\n'
    '  1. Wire the route (constant + router case) in one step:\n'
    '       dart run scripts/agent/wire_route.dart $feature\n'
    '     (or add it by hand to lib/utils/router/routes.dart and '
    'app_router.dart: Routes.${feature.camelCase} → ${feature.pascalCase}Page)\n'
    '  2. Point ${feature.pascalCase}Repo at the real endpoint.\n'
    '  3. Run the quality gate: dart run scripts/agent/verify.dart\n',
  );
}
