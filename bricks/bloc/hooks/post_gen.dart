import 'dart:io';
import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  final featureName = context.vars['feature_name'] as String;

  // Format generated feature code
  final targetDir = 'lib/features/$featureName';
  if (Directory(targetDir).existsSync()) {
    await Process.run('dart', ['format', targetDir], runInShell: true);
  }

  context.logger.success('🎉 Feature module `$featureName` scaffolded successfully in `$targetDir`!');
  context.logger.info(
    '\nNext steps to wire this feature:\n'
    '1. Register route in `lib/utils/router/routes.dart`:\n'
    '   static const String $featureName = \'/$featureName\';\n\n'
    '2. Add case to `lib/utils/router/app_router.dart`:\n'
    '   case Routes.$featureName:\n'
    '     return _build(settings, (_) => const ${featureName.pascalCase}Page());\n',
  );
}
