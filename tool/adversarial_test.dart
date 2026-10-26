import 'dart:io';

import 'package:path/path.dart' as p;

final _gitPluginPattern = RegExp(
  r'plugins:\s+redux_rxdart_lints:\s+git:\s+url:\s+https://github\.com/[\w.-]+/Flutter-RxDart-Base\.git\s+path:\s+packages/redux_rxdart_lints\s+ref:\s+\w+',
);

class _AdversarialFailure implements Exception {
  _AdversarialFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

Future<ProcessResult> _run(
  String description,
  String executable,
  List<String> args, {
  String? workingDirectory,
  bool failOnError = true,
  Duration timeout = const Duration(minutes: 5),
}) async {
  print('$description...');
  final String exe = executable == 'dart' ? Platform.executable : executable;
  final List<String> cmdArgs = args;
  final result = await Process.run(
    exe,
    cmdArgs,
    workingDirectory: workingDirectory,
    runInShell: true,
  ).timeout(timeout, onTimeout: () {
    throw _AdversarialFailure('$description timed out after $timeout');
  });
  if (failOnError && result.exitCode != 0) {
    throw _AdversarialFailure(
        '$description failed (exit ${result.exitCode}).\n${result.stdout}\n${result.stderr}');
  }
  return result;
}

Future<void> main() async {
  print('===========================================================');
  print(' BRUTAL ADVERSARIAL TEST: Non-Live Disposable Flutter App');
  print('===========================================================\n');

  final rootDir = Directory.current.path;
  final tempDir = Directory(p.join(rootDir, 'temp_adversarial_test'));

  final failures = <String>[];
  void check(String name, bool ok, [String detail = '']) {
    final status = ok ? '\x1B[32mPASS\x1B[0m' : '\x1B[31mFAIL\x1B[0m';
    print('$status  $name');
    if (!ok) {
      failures.add(name);
      if (detail.isNotEmpty) print('      $detail');
    }
  }

  try {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);

    // 1. Scaffold disposable app
    print('[Step 1] Creating fresh disposable Flutter app...');
    await _run(
        'flutter create', 'flutter', ['create', 'temp_adversarial_test']);

    print('[Step 2] Running mason make project with harness...');
    await _run('mason make project', 'mason', [
      'make',
      'project',
      '--project_name',
      'temp_adversarial_test',
      '--android_package_name',
      'com.example.temp_adversarial_test',
      '--ios_bundle_id',
      'com.example.temp_adversarial_test',
      '--include_harness',
      'true',
      '--include_secure_storage',
      'true',
      '--on-conflict',
      'overwrite',
      '-o',
      'temp_adversarial_test',
    ]);

    // Link local plugin in analysis_options.yaml
    final generatedOptions =
        File(p.join(tempDir.path, 'analysis_options.yaml'));
    final optionsContent = generatedOptions.readAsStringSync();
    final localPackagePath =
        p.join(rootDir, 'packages', 'redux_rxdart_lints').replaceAll(r'\', '/');
    final localPluginYaml =
        'plugins:\n  redux_rxdart_lints:\n    path: $localPackagePath';
    generatedOptions.writeAsStringSync(
      optionsContent.replaceFirst(_gitPluginPattern, localPluginYaml),
    );

    await _run('flutter gen-l10n', 'flutter', ['gen-l10n'],
        workingDirectory: tempDir.path);

    print('[Step 3] Scaffolding feature with mason make bloc...');
    await _run(
        'mason make bloc',
        'mason',
        [
          'make',
          'bloc',
          '--feature_name',
          'adversarial_feature',
          '--on-conflict',
          'overwrite',
        ],
        workingDirectory: tempDir.path);

    print('[Step 4] Checking initial format and verify --fast...');
    final initialFast = await _run(
        'initial verify --fast',
        'dart',
        [
          'run',
          'scripts/agent/verify.dart',
          '--fast',
        ],
        workingDirectory: tempDir.path);
    check('Initial scaffold passes verify --fast', initialFast.exitCode == 0);

    // ── ADVERSARIAL CHECK 1: Cursor Rules Portability ───────────
    print(
        '\n[Adversarial 1] Checking Cursor path-scoped rules in generated app...');
    const cursorRules = ['bloc.mdc', 'endpoints.mdc', 'ui.mdc', 'testing.mdc'];
    for (final rule in cursorRules) {
      final f = File(p.join(tempDir.path, '.cursor/rules', rule));
      check('App has .cursor/rules/$rule',
          f.existsSync() && f.readAsStringSync().contains('globs:'));
    }

    // ── ADVERSARIAL CHECK 2: Circuit Breaker on Real Lint Error ─
    print(
        '\n[Adversarial 2] Testing Anti-Loop Circuit Breaker on real compile violation...');
    final pageFile = File(p.join(tempDir.path,
        'lib/features/adversarial_feature/adversarial_feature_page.dart'));
    final originalPage = pageFile.readAsStringSync();

    // Inject compile violation: type mismatch
    final violatedPage = originalPage.replaceFirst(
      'super.dispose();',
      'int invalidType = "this is not an int";\n    super.dispose();',
    );
    if (violatedPage == originalPage) {
      throw StateError('Failed to inject compile error into page!');
    }
    pageFile.writeAsStringSync(violatedPage);

    // Turn 1
    final onEdit1 = await _run(
        'on_edit turn 1',
        'dart',
        [
          'run',
          'scripts/agent/on_edit.dart',
          'lib/features/adversarial_feature/adversarial_feature_page.dart',
        ],
        workingDirectory: tempDir.path,
        failOnError: false);

    final guardFile = File(p.join(tempDir.path, '.harness/.loop_guard.json'));
    check('on_edit catches code violation (exitCode != 0)',
        onEdit1.exitCode != 0);
    check('on_edit writes .harness/.loop_guard.json', guardFile.existsSync());

    // Turn 2
    await _run(
        'on_edit turn 2',
        'dart',
        [
          'run',
          'scripts/agent/on_edit.dart',
          'lib/features/adversarial_feature/adversarial_feature_page.dart',
        ],
        workingDirectory: tempDir.path,
        failOnError: false);

    // Turn 3: Trips circuit breaker!
    final onEdit3 = await _run(
        'on_edit turn 3',
        'dart',
        [
          'run',
          'scripts/agent/on_edit.dart',
          'lib/features/adversarial_feature/adversarial_feature_page.dart',
        ],
        workingDirectory: tempDir.path,
        failOnError: false);

    final out3 = '${onEdit3.stdout}\n${onEdit3.stderr}';
    check(
      'Circuit breaker trips with exit code 2 and halts retry loop',
      onEdit3.exitCode == 2 && out3.contains('CIRCUIT BREAKER'),
      out3.trim(),
    );

    // Reset guard and revert page
    await _run(
        'reset guard',
        'dart',
        [
          'run',
          'scripts/agent/on_edit.dart',
          '--reset-guard',
        ],
        workingDirectory: tempDir.path);
    pageFile.writeAsStringSync(originalPage);

    // ── ADVERSARIAL CHECK 3: Compact Error & Framework Stack Trace Pruning
    print('\n[Adversarial 3] Testing Compact Failure output on test crash...');
    final testFile = File(p.join(tempDir.path,
        'test/features/adversarial_feature/bloc/adversarial_feature_bloc_test.dart'));
    final originalTest = testFile.readAsStringSync();

    // Inject a failing expectation
    final brokenTest = originalTest.replaceFirst(
      "test('starts in InitialResponse', () {",
      "test('starts in InitialResponse', () {\n    expect(1, equals(2), reason: 'Injected failure');",
    );
    if (brokenTest == originalTest) {
      throw StateError('Failed to inject test failure into test!');
    }
    testFile.writeAsStringSync(brokenTest);
    await Process.run(Platform.executable, ['format', testFile.path],
        runInShell: true);

    final verifyFail = await _run(
        'verify on failing test',
        'dart',
        [
          'run',
          'scripts/agent/verify.dart',
        ],
        workingDirectory: tempDir.path,
        failOnError: false);

    final verifyOut = '${verifyFail.stdout}\n${verifyFail.stderr}';
    check('verify fails on broken test', verifyFail.exitCode != 0,
        verifyOut.trim());
    check(
      'verify output prunes Flutter framework stack traces (no flutter/src/)',
      !verifyOut.contains('package:flutter/src/') &&
          !verifyOut.contains('package:test_api/'),
      verifyOut.trim(),
    );
    check(
      'verify output retains actionable test failure summary and location',
      verifyOut.contains('Test failure summary:') &&
          verifyOut.contains('Expected:') &&
          verifyOut.contains('adversarial_feature_bloc_test.dart'),
      verifyOut.trim(),
    );
    final hookStderr = File(p.join(tempDir.path,
        '.dart_tool/hooks_runner/objective_c/8e04c28b44/stderr.txt'));
    if (hookStderr.existsSync()) {
      print('HOOK STDERR:\n${hookStderr.readAsStringSync()}');
    }

    // Revert test
    testFile.writeAsStringSync(originalTest);

    // ── ADVERSARIAL CHECK 4: Route Wiring ───────────────────────
    print('\n[Adversarial 4] Testing scripts/agent/wire_route.dart...');
    final wireResult = await _run(
        'wire_route profile',
        'dart',
        [
          'run',
          'scripts/agent/wire_route.dart',
          'profile',
          '/profile',
        ],
        workingDirectory: tempDir.path);

    final routesContent =
        File(p.join(tempDir.path, 'lib/utils/router/routes.dart'))
            .readAsStringSync();
    final routerContent =
        File(p.join(tempDir.path, 'lib/utils/router/app_router.dart'))
            .readAsStringSync();
    check('wire_route runs successfully', wireResult.exitCode == 0);
    check('Routes.profile constant declared',
        routesContent.contains('profile = \'/profile\''));
    check('AppRouter handles Routes.profile',
        routerContent.contains('Routes.profile'));

    // ── ADVERSARIAL CHECK 5: Team Swarm Mailbox & Human Blocker ──
    print(
        '\n[Adversarial 5] Testing scripts/team/ coordination & human blocker...');
    // Create task
    final createRes = await _run(
        'team create task',
        'dart',
        [
          'run',
          'scripts/team/task_handoff.dart',
          'create',
          '--title',
          'Implement Payments',
          '--assignee',
          'bloc-specialist',
        ],
        workingDirectory: tempDir.path);
    final taskIdMatch =
        RegExp(r'Task created: (T-\d+)').firstMatch('${createRes.stdout}');
    final taskId = taskIdMatch?.group(1) ?? 'T-1';

    // Claim
    await _run(
        'team claim task',
        'dart',
        [
          'run',
          'scripts/team/task_handoff.dart',
          'claim',
          '--id',
          taskId,
          '--assignee',
          'bloc-specialist',
        ],
        workingDirectory: tempDir.path);

    // Wait on human
    await _run(
        'team wait-human',
        'dart',
        [
          'run',
          'scripts/team/task_handoff.dart',
          'wait-human',
          '--id',
          taskId,
          '--reason',
          'Need Stripe public API key',
        ],
        workingDirectory: tempDir.path);

    // Heartbeat check
    final heartbeatRes = await _run(
        'team heartbeat',
        'dart',
        [
          'run',
          'scripts/team/heartbeat.dart',
        ],
        workingDirectory: tempDir.path);
    final hbOut = '${heartbeatRes.stdout}';
    check(
      'Heartbeat detects human blocker and reports reason',
      hbOut.contains('waiting_human') &&
          hbOut.contains('Need Stripe public API key'),
      hbOut.trim(),
    );

    // Send inter-agent message
    await _run(
        'team send message',
        'dart',
        [
          'run',
          'scripts/team/task_handoff.dart',
          'send',
          '--to',
          'bloc-specialist',
          '--subject',
          'Key Provided',
          '--body',
          'API key added to .env.test',
        ],
        workingDirectory: tempDir.path);

    // Inbox check
    final inboxRes = await _run(
        'team inbox check',
        'dart',
        [
          'run',
          'scripts/team/task_handoff.dart',
          'inbox',
          '--agent',
          'bloc-specialist',
          '--mark-read',
        ],
        workingDirectory: tempDir.path);
    check('Inbox receives message for agent',
        inboxRes.stdout.toString().contains('Key Provided'));

    // Resume and complete
    await _run(
        'team resume task',
        'dart',
        [
          'run',
          'scripts/team/task_handoff.dart',
          'resume',
          '--id',
          taskId,
        ],
        workingDirectory: tempDir.path);

    await _run(
        'team complete task',
        'dart',
        [
          'run',
          'scripts/team/task_handoff.dart',
          'complete',
          '--id',
          taskId,
          '--summary',
          'Completed payment layer',
        ],
        workingDirectory: tempDir.path);

    // ── ADVERSARIAL CHECK 6: Full Pre-Commit Quality Gate ───────
    print(
        '\n[Adversarial 6] Running full scripts/agent/verify.dart quality gate...');
    final fullVerify = await _run(
        'full verify.dart',
        'dart',
        [
          'run',
          'scripts/agent/verify.dart',
        ],
        workingDirectory: tempDir.path,
        failOnError: false);
    final fullOut = '${fullVerify.stdout}\n${fullVerify.stderr}';
    check('Full verify.dart passes on app after all adversarial operations',
        fullVerify.exitCode == 0, fullOut.trim());

    print('\n===========================================================');
    if (failures.isEmpty) {
      print('\x1B[32mALL ADVERSARIAL LIVE TESTS PASSED (100% SUCCESS)\x1B[0m');
      print('===========================================================');
    } else {
      print('\x1B[31m${failures.length} ADVERSARIAL TEST(S) FAILED:\x1B[0m');
      for (final f in failures) {
        print('  - $f');
      }
      print('===========================================================');
      exitCode = 1;
    }
  } on _AdversarialFailure catch (e) {
    stderr.writeln('Adversarial test aborted: $e');
    exitCode = 1;
  } finally {
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  }
}
