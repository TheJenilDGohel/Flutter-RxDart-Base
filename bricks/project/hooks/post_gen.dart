import 'dart:io';

import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  final androidPackageName = context.vars['android_package_name'] as String;
  final rawIosBundleId = (context.vars['ios_bundle_id'] as String?)?.trim() ?? '';
  final iosBundleId = rawIosBundleId.isEmpty ? androidPackageName : rawIosBundleId;

  final progress = context.logger.progress('Resolving dependencies');

  if (!Directory('android').existsSync() || !Directory('ios').existsSync()) {
    progress.fail();
    context.logger.err(
      'No Flutter project detected in current directory (missing android/ or ios/).\n'
      'Please run `flutter create <app_name>` first, `cd` into the project directory, and re-run `mason make project`.',
    );
    exit(1);
  }

  // 1. Single instant pub get
  final pubGetResult = await Process.run(
    'flutter',
    ['pub', 'get'],
    runInShell: true,
  );

  if (pubGetResult.exitCode != 0) {
    progress.fail();
    context.logger.err('flutter pub get failed:\n${pubGetResult.stderr}');
    exit(1);
  }

  // 2. Package rename execution
  await Process.run(
    'dart',
    ['run', 'change_app_package_name:main', androidPackageName],
    runInShell: true,
  );

  progress.complete('Dependencies configured & package renamed in seconds!');

  if (iosBundleId != androidPackageName) {
    context.logger.info(
      'iOS bundle ID ($iosBundleId) differs from Android package name. '
      'You may need to update ios/Runner.xcodeproj/project.pbxproj if needed.',
    );
  }

  context.logger.success('\n🎉 Project bootstrap complete!');
  context.logger.info(
    'Run `mason make bloc` next to scaffold your first feature module.\n',
  );
}
