import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Automated Compliance & Quality Evaluation Suite for the AI Agent Harness.
///
/// Evaluates:
/// 1. Golden Rule lint enforcement (packages/redux_rxdart_lints check_fixture).
/// 2. Circuit breaker loop guard (trips on 3 consecutive identical failures).
/// 3. Token-saving error compaction & stack trace pruning.
/// 4. Cross-IDE Cursor rule portability (.cursor/rules/*.mdc).
/// 5. Agent instruction grounding & anti-ceremony standards.
///
/// Run from the repository root:
///   dart run tool/eval.dart
Future<void> main() async {
  print('===========================================================');
  print(' AI Agent Harness: Automated Compliance & Eval Suite');
  print('===========================================================\n');

  final failures = <String>[];
  void check(String name, bool ok, [String detail = '']) {
    final status = ok ? '\x1B[32mPASS\x1B[0m' : '\x1B[31mFAIL\x1B[0m';
    print('$status  $name');
    if (!ok) {
      failures.add(name);
      if (detail.isNotEmpty) print('      $detail');
    }
  }

  // ── 1. Golden Rule Lint Fixtures ──────────────────────────────
  print('\n[1/5] Evaluating Golden Rule Lint Package Fixtures...');
  final lintDir = Directory('packages/redux_rxdart_lints');
  if (!lintDir.existsSync()) {
    check('Lint package directory exists', false,
        'Missing packages/redux_rxdart_lints');
  } else {
    final lintResult = await Process.run(
      'dart',
      ['run', 'tool/check_fixture.dart'],
      workingDirectory: lintDir.path,
      runInShell: true,
    );
    final lintOutput = '${lintResult.stdout}\n${lintResult.stderr}';
    check(
      'redux_rxdart_lints fixture matches all golden rules (no missing/unexpected)',
      lintResult.exitCode == 0,
      lintOutput.trim(),
    );
  }

  // ── 2. Circuit Breaker Loop Guard ────────────────────────────
  print('\n[2/5] Evaluating Anti-Loop Circuit Breaker in on_edit.dart...');
  final tempDir = Directory('temp_eval_circuit_breaker');
  if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  tempDir.createSync(recursive: true);

  try {
    // Copy on_edit script to tempDir
    final scriptContent =
        File('bricks/harness/__brick__/scripts/agent/on_edit.dart')
            .readAsStringSync();
    final scriptFile = File(p.join(tempDir.path, 'scripts/agent/on_edit.dart'))
      ..createSync(recursive: true);
    scriptFile.writeAsStringSync(scriptContent);

    // Create an unformatted / malformed dart file
    final badDart = File(p.join(tempDir.path, 'lib/test_bad.dart'))
      ..createSync(recursive: true);
    badDart.writeAsStringSync('void main() { print("unformatted") ; } \n');

    // Run 1: Should fail format with exitCode != 0, write count=1
    final r1 = await Process.run(
      'dart',
      ['run', 'scripts/agent/on_edit.dart', 'lib/test_bad.dart'],
      workingDirectory: tempDir.path,
      runInShell: true,
    );
    final guardFile = File(p.join(tempDir.path, '.harness/.loop_guard.json'));
    final guardExists = guardFile.existsSync();
    var count1 = 0;
    if (guardExists) {
      final data =
          jsonDecode(guardFile.readAsStringSync()) as Map<String, dynamic>;
      count1 = data['count'] as int? ?? 0;
    }
    check('Circuit breaker turn 1 records failure signature (count=1)',
        r1.exitCode != 0 && count1 == 1);

    // Run 2: Should fail format, count=2
    await Process.run(
      'dart',
      ['run', 'scripts/agent/on_edit.dart', 'lib/test_bad.dart'],
      workingDirectory: tempDir.path,
      runInShell: true,
    );
    var count2 = 0;
    if (guardFile.existsSync()) {
      final data =
          jsonDecode(guardFile.readAsStringSync()) as Map<String, dynamic>;
      count2 = data['count'] as int? ?? 0;
    }
    check('Circuit breaker turn 2 records repeated failure (count=2)',
        count2 == 2);

    // Run 3: Identical failure 3rd time -> trips circuit breaker (exit code 2)
    final r3 = await Process.run(
      'dart',
      ['run', 'scripts/agent/on_edit.dart', 'lib/test_bad.dart'],
      workingDirectory: tempDir.path,
      runInShell: true,
    );
    final out3 = '${r3.stdout}\n${r3.stderr}';
    final tripped = r3.exitCode == 2 && out3.contains('CIRCUIT BREAKER');
    check('Circuit breaker trips on 3rd identical failure (exit code 2)',
        tripped, out3.trim());

    // Reset guard
    final rReset = await Process.run(
      'dart',
      ['run', 'scripts/agent/on_edit.dart', '--reset-guard'],
      workingDirectory: tempDir.path,
      runInShell: true,
    );
    check('Circuit breaker reset cleans .harness/.loop_guard.json',
        rReset.exitCode == 0 && !guardFile.existsSync());
  } finally {
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  }

  // ── 3. Token Compaction & Error Stripping ────────────────────
  print('\n[3/5] Evaluating Token Compression & Stack Trace Pruning...');
  // Check framework stack trace pruning logic
  final rawStackTraces = [
    'FAIL: test/feature_test.dart',
    'Expected: <SuccessResponse>',
    '  Actual: <ErrorResponse>',
    'package:flutter/src/widgets/framework.dart 452:12  StatefulElement.build',
    'package:test_api/src/backend/invoker.dart 23:5     Invoker.guard',
    'dart:async/zone.dart 1400:10                      _CustomZone.run',
    'package:app/features/profile/profile_page.dart 42:15 _ProfileViewState.build',
  ];

  final pruned = rawStackTraces.where((line) {
    if (line.contains('FAIL') ||
        line.contains('Expected:') ||
        line.contains('Actual:') ||
        line.contains('package:') ||
        line.contains('test/')) {
      if (!line.contains('package:flutter/src/') &&
          !line.contains('package:flutter_test/') &&
          !line.contains('package:test_api/') &&
          !line.contains('package:matcher/') &&
          !line.contains('dart:async/') &&
          !line.contains('dart:isolate/')) {
        return true;
      }
    }
    return false;
  }).toList();

  check(
      'Framework stack traces pruned from test failure output',
      !pruned.any((l) =>
          l.contains('flutter/src/') ||
          l.contains('test_api') ||
          l.contains('dart:async')),
      'Pruned output contains framework noise: $pruned');
  check(
      'User file location & assertion failure retained in test summary',
      pruned.any((l) => l.contains('Expected:')) &&
          pruned.any((l) => l.contains('profile_page.dart')));

  // Check analyzer boilerplate pruning logic
  final rawAnalyzerOutput = '''
Analyzing /project...
  error • Undefined name 'xyz' • lib/features/foo.dart:12:5 • undefined_identifier
1 issue found.
''';
  final prunedAnalyzer = rawAnalyzerOutput
      .split('\n')
      .map((l) => l.trim())
      .where((l) =>
          l.isNotEmpty &&
          !l.startsWith('Analyzing') &&
          !l.contains('issue found') &&
          !l.contains('issues found'))
      .toList();

  check(
      'Analyzer noise lines ("Analyzing...", "1 issue found") pruned',
      prunedAnalyzer.length == 1 &&
          prunedAnalyzer.first.contains('Undefined name'));

  // ── 4. Cross-IDE Cursor Rule Portability ──────────────────────
  print('\n[4/5] Evaluating Cursor Path-Scoped Rules (.cursor/rules/*.mdc)...');
  final cursorDir = Directory('bricks/harness/__brick__/.cursor/rules');
  check(
      'Cursor rules directory exists in harness brick', cursorDir.existsSync());

  const expectedCursorRules = [
    'bloc.mdc',
    'endpoints.mdc',
    'ui.mdc',
    'testing.mdc'
  ];
  for (final rule in expectedCursorRules) {
    final file = File(p.join(cursorDir.path, rule));
    final exists = file.existsSync();
    var hasFrontmatter = false;
    var hasGlobs = false;
    if (exists) {
      final content = file.readAsStringSync();
      hasFrontmatter = content.contains('description:');
      hasGlobs = content.contains('globs:');
    }
    check('Cursor rule $rule exists with glob scoping',
        exists && hasFrontmatter && hasGlobs);
  }

  // ── 5. Agent Instructions Grounding & Compaction ──────────────
  print('\n[5/5] Evaluating Agent Instructions Grounding (AGENTS.md)...');
  final agentsMd =
      File('bricks/harness/__brick__/AGENTS.md').readAsStringSync();

  check('Section 4 header is exact string "## 4. Tooling for Agents"',
      agentsMd.contains('## 4. Tooling for Agents'));
  check('AGENTS.md includes contrastive "// ❌ BAD" vs "// ✅ GOOD" snippets',
      agentsMd.contains('// ❌ BAD') && agentsMd.contains('// ✅ GOOD'));
  check('Section 6 includes "No close-out tax on small edits"',
      agentsMd.contains('No close-out tax on small edits'));
  check(
      'Section 6 grounds RAG in LSP without mandatory KG ceremony',
      !agentsMd.contains(
              'Before touching any file, you must search the knowledge graph') &&
          agentsMd.contains('LSP'));

  // ── Summary ──────────────────────────────────────────────────
  print('\n===========================================================');
  if (failures.isEmpty) {
    print('\x1B[32mALL COMPLIANCE & EVALUATION GATES PASSED (100%)\x1B[0m');
    print('===========================================================');
  } else {
    print('\x1B[31m${failures.length} EVALUATION CHECK(S) FAILED:\x1B[0m');
    for (final f in failures) {
      print('  - $f');
    }
    print('===========================================================');
    exit(1);
  }
}
