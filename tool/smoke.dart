import 'dart:io';

import 'package:path/path.dart' as p;

import 'harness_recipes.dart';

final _gitPluginPattern = RegExp(
  r'plugins:\s+redux_rxdart_lints:\s+git:\s+url:\s+https://github\.com/[\w.-]+/Flutter-RxDart-Base\.git\s+path:\s+packages/redux_rxdart_lints\s+ref:\s+\w+',
);

bool _useFvm() {
  if (Platform.environment['CI'] == 'true' ||
      Platform.environment['GITHUB_ACTIONS'] == 'true') {
    return false;
  }
  if (!Directory('.fvm').existsSync() && !File('.fvmrc').existsSync()) {
    return false;
  }
  final check = Process.runSync(
    Platform.isWindows ? 'where' : 'which',
    ['fvm'],
    runInShell: true,
  );
  return check.exitCode == 0;
}

class _SmokeFailure implements Exception {
  _SmokeFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Runs a command and throws [_SmokeFailure] (never `exit`) on a non-zero
/// exit code, so the `finally` cleanup in [main] always runs.
Future<ProcessResult> _run(
  String description,
  String executable,
  List<String> args, {
  String? workingDirectory,
  Duration timeout = const Duration(minutes: 15),
}) async {
  print('$description...');
  final useFvm = _useFvm();
  final String exe;
  final List<String> cmdArgs;
  if (useFvm) {
    if (executable == 'flutter' || executable == 'dart') {
      exe = 'fvm';
      cmdArgs = [executable, ...args];
    } else if (executable == 'mason') {
      exe = 'fvm';
      cmdArgs = ['dart', 'pub', 'global', 'run', 'mason_cli:mason', ...args];
    } else {
      exe = executable;
      cmdArgs = args;
    }
  } else {
    exe = executable;
    cmdArgs = args;
  }
  final result = await Process.run(
    exe,
    cmdArgs,
    workingDirectory: workingDirectory,
    runInShell: true,
  ).timeout(timeout, onTimeout: () {
    throw _SmokeFailure('$description timed out after $timeout');
  });
  if (result.exitCode != 0) {
    throw _SmokeFailure(
        '$description failed (exit ${result.exitCode}).\n${result.stdout}\n${result.stderr}');
  }
  return result;
}

Future<void> main() async {
  print('--- Starting cross-platform smoke test ---');
  if (_useFvm()) {
    print('FVM detected — using `fvm dart` / `fvm flutter` for testing.');
  }

  final rootDir = Directory.current.path;
  final tempDir = Directory(p.join(rootDir, 'temp_smoke_test'));

  try {
    await _run('Activating mason_cli', 'dart',
        ['pub', 'global', 'activate', 'mason_cli']);
    await _run('Resolving workspace bricks via mason get', 'mason', ['get']);

    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }

    await _run(
        'Creating fresh Flutter app', 'flutter', ['create', 'temp_smoke_test']);

    if (_useFvm() && File(p.join(rootDir, '.fvmrc')).existsSync()) {
      File(p.join(tempDir.path, '.fvmrc')).writeAsStringSync(
        File(p.join(rootDir, '.fvmrc')).readAsStringSync(),
      );
    }

    await _run('Running mason make project', 'mason', [
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
    ]);

    // Point the generated app's analysis_options.yaml at the local lints
    // package with an absolute path so the branch under test is validated
    // (a git ref: main would fetch the old version before merge).
    final generatedOptions =
        File(p.join(tempDir.path, 'analysis_options.yaml'));
    if (!generatedOptions.existsSync()) {
      throw _SmokeFailure('Generated analysis_options.yaml not found.');
    }
    final optionsContent = generatedOptions.readAsStringSync();
    final localPackagePath =
        p.join(rootDir, 'packages', 'redux_rxdart_lints').replaceAll(r'\', '/');
    if (!_gitPluginPattern.hasMatch(optionsContent)) {
      throw _SmokeFailure(
        'Could not find the redux_rxdart_lints git plugin in generated '
        'analysis_options.yaml; the smoke test would otherwise validate '
        'GitHub main instead of this checkout.',
      );
    }
    final localPluginYaml =
        'plugins:\n  redux_rxdart_lints:\n    path: $localPackagePath';
    generatedOptions.writeAsStringSync(
      optionsContent.replaceFirst(_gitPluginPattern, localPluginYaml),
    );

    await _run(
      'Running mason make bloc',
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
    );

    await _run('Checking generated code is formatted', 'dart',
        ['format', '--set-exit-if-changed', '.'],
        workingDirectory: tempDir.path);

    // The harness skills' code must keep compiling, passing the lints and
    // behaving as documented: analyze (which runs the analyzer plugin) and test
    // below cover it.
    print('Pasting the harness BLoC recipes into the app...');
    pasteRecipes(tempDir.path, 'temp_smoke_test');
    await _run(
        'Generating localizations for the recipes', 'flutter', ['gen-l10n'],
        workingDirectory: tempDir.path);
    await _run(
        'Running flutter analyze', 'flutter', ['analyze', '--fatal-infos'],
        workingDirectory: tempDir.path);
    final testRes = await _run(
        'Running flutter test',
        'flutter',
        [
          'test',
          '--reporter',
          'expanded',
        ],
        workingDirectory: tempDir.path);
    final testLines = (testRes.stdout as String).trim().split('\n');
    print('  ${testLines.last.trim()}');

    await _run('Checking the harness lessons store', 'dart',
        ['run', 'scripts/agent/learn.dart', 'check'],
        workingDirectory: tempDir.path);

    print('--- Smoke test completed successfully! ---');
  } on _SmokeFailure catch (e) {
    stderr.writeln('Smoke test failed: $e');
    exitCode = 1;
  } finally {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }
}
