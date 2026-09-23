import 'package:path/path.dart' as p;
import 'dart:io';

Future<void> main() async {
  print('--- Starting cross-platform smoke test ---');

  // 1. Activate mason_cli
  print('Activating mason_cli...');
  final pubGlobal = await Process.run(
      'dart', ['pub', 'global', 'activate', 'mason_cli'],
      runInShell: true);
  if (pubGlobal.exitCode != 0) {
    print('Failed to activate mason_cli');
    print(pubGlobal.stderr);
    exit(1);
  }

  // Define paths
  final rootDir = Directory.current.path;
  final tempDir = Directory(p.join(rootDir, 'temp_smoke_test'));

  // Cleanup temp dir if exists
  if (tempDir.existsSync()) {
    tempDir.deleteSync(recursive: true);
  }

  // Backup and rewrite template pubspec to use local path
  final templatePubspec =
      File(p.join(rootDir, 'bricks', 'project', '__brick__', 'pubspec.yaml'));
  final backupPubspecContent = templatePubspec.readAsStringSync();
  try {
    var modifiedPubspec = backupPubspecContent.replaceAll(
      RegExp(
          r'git:\s+url:\s+https://github.com/TheJenilDGohel/Flutter-RxDart-Base\.git\s+path:\s+packages/redux_rxdart_lints'),
      'path: ../packages/redux_rxdart_lints',
    );
    templatePubspec.writeAsStringSync(modifiedPubspec);

    // 2. flutter create
    print('Creating fresh Flutter app...');
    final createRes = await Process.run(
        'flutter', ['create', 'temp_smoke_test'],
        runInShell: true);
    if (createRes.exitCode != 0) {
      print('flutter create failed: ${createRes.stderr}');
      exit(1);
    }

    // 3. mason make project
    print('Running mason make project...');
    final masonRes = await Process.run(
      'mason',
      [
        'make',
        'project',
        '--project_name',
        'temp_smoke_test',
        '--android_package_name',
        'com.example.temp_smoke_test',
        '--ios_bundle_id',
        'com.example.temp_smoke_test',
        '--include_harness',
        'true',
        '--include_secure_storage',
        'true',
        '--on-conflict',
        'overwrite',
        '-o',
        'temp_smoke_test'
      ],
      runInShell: true,
    );
    if (masonRes.exitCode != 0) {
      print('mason make failed: ${masonRes.stderr}');
      exit(1);
    }

    // 3.5 Rewrite generated pubspec.yaml to use local path for lints
    print('Rewriting generated pubspec.yaml to use local path for lints...');
    final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
    var pubspecContent = pubspecFile.readAsStringSync();
    pubspecContent = pubspecContent.replaceFirst(
      '    git:\n      url: https://github.com/TheJenilDGohel/Flutter-RxDart-Base.git\n      path: packages/redux_rxdart_lints',
      '    path: ../packages/redux_rxdart_lints',
    );
    pubspecFile.writeAsStringSync(pubspecContent);

    // 4. mason make bloc
    print('Running mason make bloc...');
    final masonBlocRes = await Process.run(
      'mason',
      [
        'make',
        'bloc',
        '--feature_name',
        'dummy_feature',
        '--on-conflict',
        'overwrite',
      ],
      workingDirectory: tempDir.path,
      runInShell: true,
    );
    if (masonBlocRes.exitCode != 0) {
      print('mason make bloc failed: ${masonBlocRes.stderr}');
      exit(1);
    }

    // 5. format, analyze, test
    print('Running dart format...');
    final formatRes = await Process.run('dart', ['format', '.'],
        workingDirectory: tempDir.path, runInShell: true);
    if (formatRes.exitCode != 0) {
      print('dart format failed.');
      print(formatRes.stdout);
      print(formatRes.stderr);
      exit(1);
    }

    print('Running flutter analyze...');
    final analyzeRes = await Process.run(
        'flutter', ['analyze', '--fatal-infos'],
        workingDirectory: tempDir.path, runInShell: true);
    if (analyzeRes.exitCode != 0) {
      print('flutter analyze failed.');
      print(analyzeRes.stdout);
      print(analyzeRes.stderr);
      exit(1);
    }

    print('Running flutter test...');
    final testRes = await Process.run('flutter', ['test'],
        workingDirectory: tempDir.path, runInShell: true);
    if (testRes.exitCode != 0) {
      print('flutter test failed.');
      print(testRes.stdout);
      print(testRes.stderr);
      exit(1);
    }

    print('Running custom_lint...');
    final lintRes = await Process.run('dart', ['run', 'custom_lint'],
        workingDirectory: tempDir.path, runInShell: true);
    if (lintRes.exitCode != 0) {
      final combinedOutput = '${lintRes.stdout}\n${lintRes.stderr}';
      if (combinedOutput.contains('%20')) {
        print(
            'Notice: custom_lint has a known upstream URI encoding issue (%20) with spaces in parent directories.');
        print(
            'Skipping custom_lint exit failure on local spaced directory path.');
      } else {
        print('custom_lint failed.');
        print(lintRes.stdout);
        print(lintRes.stderr);
        exit(1);
      }
    }

    print('--- Smoke test completed successfully! ---');
    exit(0);
  } finally {
    // Ensure template pubspec is always restored to canonical git dependency
    final currentText = templatePubspec.readAsStringSync();
    final restoredText = currentText.replaceAll(
      'path: ../packages/redux_rxdart_lints',
      'git:\n      url: https://github.com/TheJenilDGohel/Flutter-RxDart-Base.git\n      path: packages/redux_rxdart_lints',
    );
    templatePubspec.writeAsStringSync(restoredText);
  }
}
