import 'dart:io';

import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  final androidPackageName = context.vars['android_package_name'] as String;
  final iosBundleId = context.vars['ios_bundle_id'] as String;

  context.logger.info(
    '\n🚀 Bootstrapping project architecture...\n'
    '   Package resolution and setup are starting. This step may take 30–60 seconds.\n',
  );

  /// Runs a shell command, logs progress, and exits on failure.
  Future<void> runCmd(
    String executable,
    List<String> args,
    String description,
  ) async {
    final progress = context.logger.progress(description);
    final result = await Process.run(
      executable,
      args,
      runInShell: true,
    );

    if (result.exitCode != 0) {
      progress.fail();
      context.logger.err('$description failed:\n${result.stderr}');
      exit(1);
    }
    progress.complete();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Step 1: Add change_app_package_name and run rename
  // ═══════════════════════════════════════════════════════════════════════
  await runCmd(
    'flutter',
    ['pub', 'add', '--dev', 'change_app_package_name'],
    '[1/6] Installing package rename utility',
  );

  await runCmd(
    'dart',
    ['run', 'change_app_package_name:main', androidPackageName],
    '[2/6] Renaming app package to $androidPackageName',
  );

  if (iosBundleId != androidPackageName) {
    context.logger.info(
      'iOS bundle ID ($iosBundleId) differs from Android package name. '
      'You may need to manually update the iOS bundle identifier in '
      'ios/Runner.xcodeproj/project.pbxproj if change_app_package_name '
      'does not support per-platform overrides.',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Step 3: Add core dependencies in logical groups with step progress
  // ═══════════════════════════════════════════════════════════════════════
  await runCmd(
    'flutter',
    [
      'pub', 'add',
      'dio',
      'dio_smart_retry',
      'dio_http2_adapter',
      'connectivity_plus',
      'rxdart',
      'rxdart_flutter',
      'redux',
      'flutter_redux',
      'meta',
    ],
    '[3/6] Adding networking & state management packages',
  );

  await runCmd(
    'flutter',
    [
      'pub', 'add',
      'firebase_core',
      'firebase_crashlytics',
      'firebase_messaging',
      'flutter_local_notifications',
      'snug_logger',
      'device_info_plus',
    ],
    '[4/6] Adding Firebase & device services',
  );

  await runCmd(
    'flutter',
    [
      'pub', 'add',
      'flutter_screenutil',
      'shared_preferences',
      'cached_network_image',
      'flutter_svg',
      'url_launcher',
      'share_plus',
      'path_provider',
      'permission_handler',
      'file_picker',
      'intl',
      'characters',
      'overlay_support',
    ],
    '[5/6] Adding UI, storage & utility dependencies',
  );

  // ═══════════════════════════════════════════════════════════════════════
  // Step 4: Add flutter_localizations (SDK package — manual pubspec edit)
  // ═══════════════════════════════════════════════════════════════════════
  {
    final pubspecFile = File('pubspec.yaml');
    var content = pubspecFile.readAsStringSync();

    if (!content.contains('flutter_localizations')) {
      final sdkLine = RegExp(
        r'(  flutter:\n    sdk: flutter\n)',
      );
      content = content.replaceFirstMapped(
        sdkLine,
        (m) =>
            '${m.group(1)}'
            '  flutter_localizations:\n'
            '    sdk: flutter\n',
      );
    }

    if (!content.contains('generate: true')) {
      content = content.replaceFirstMapped(
        RegExp(r'^(flutter:\s*)$', multiLine: true),
        (m) => '${m.group(1)}\n  generate: true',
      );
    }

    pubspecFile.writeAsStringSync(content);
    context.logger.success(
      'Updated pubspec.yaml with flutter_localizations & generate: true',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Step 5: Add dev dependencies & run pub get
  // ═══════════════════════════════════════════════════════════════════════
  await runCmd(
    'flutter',
    ['pub', 'add', '--dev', 'flutter_native_splash'],
    '[6/6] Adding dev dependencies & finalizing pub resolution',
  );

  await runCmd(
    'flutter',
    ['pub', 'get'],
    'Running final flutter pub get',
  );

  context.logger.success('\n🎉 Project bootstrap complete!');
  context.logger.info(
    'Run `mason make bloc` next to scaffold your first feature module.\n',
  );
}
