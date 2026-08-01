import 'dart:io';

import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  final androidPackageName = context.vars['android_package_name'] as String;
  final iosBundleId = context.vars['ios_bundle_id'] as String;

  final progress = context.logger.progress('Configuring pubspec.yaml & resolving dependencies');

  final pubspecFile = File('pubspec.yaml');
  if (pubspecFile.existsSync()) {
    var content = pubspecFile.readAsStringSync();

    // 1. Ensure generate: true is set under root-level flutter:
    if (!content.contains('generate: true')) {
      content = content.replaceFirstMapped(
        RegExp(r'^(flutter:\s*)$', multiLine: true),
        (m) => '${m.group(1)}\n  generate: true',
      );
    }

    // 2. Core dependencies to inject
    const coreDeps = '''  flutter_localizations:
    sdk: flutter
  dio: ^5.7.0
  dio_smart_retry: ^7.0.1
  dio_http2_adapter: ^2.0.0
  connectivity_plus: ^6.1.1
  rxdart: ^0.28.0
  rxdart_flutter: ^0.2.1
  redux: ^5.0.0
  flutter_redux: ^0.10.0
  meta: ^1.16.0
  flutter_screenutil: ^5.9.3
  shared_preferences: ^2.3.5
  snug_logger: ^1.0.4
  firebase_core: ^3.10.1
  firebase_crashlytics: ^4.3.1
  firebase_messaging: ^15.2.1
  flutter_local_notifications: ^18.0.1
  cached_network_image: ^3.4.1
  flutter_svg: ^2.0.17
  url_launcher: ^6.3.1
  share_plus: ^10.1.3
  path_provider: ^2.1.5
  permission_handler: ^11.3.1
  device_info_plus: ^11.2.0
  file_picker: ^8.1.7
  intl: ^0.19.0
  characters: ^1.3.0
  overlay_support: ^2.1.0
''';

    // 3. Dev dependencies to inject
    const devDeps = '''  change_app_package_name: ^1.4.0
  flutter_native_splash: ^2.4.4
''';

    if (!content.contains('dio:')) {
      content = content.replaceFirst(
        'dependencies:\n  flutter:\n    sdk: flutter\n',
        'dependencies:\n  flutter:\n    sdk: flutter\n$coreDeps',
      );
    }

    if (!content.contains('change_app_package_name:')) {
      content = content.replaceFirst(
        'dev_dependencies:\n',
        'dev_dependencies:\n$devDeps',
      );
    }

    pubspecFile.writeAsStringSync(content);
  }

  // 4. Single instant pub get
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

  // 5. Package rename execution
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
