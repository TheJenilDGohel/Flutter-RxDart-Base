import 'dart:io';

import 'package:path/path.dart' as p;

/// End-to-end test of the harness size gate (`scripts/agent/budget.dart`).
///
/// Run from the repository root: `dart run tool/test_harness_budget.dart`.
Future<void> main() async {
  final root = Directory.current.path;
  const brick = 'bricks/harness/__brick__';
  final app = Directory(p.join(root, 'temp_budget_test'));
  if (app.existsSync()) app.deleteSync(recursive: true);
  app.createSync(recursive: true);

  final failures = <String>[];
  void check(String name, bool ok, [String detail = '']) {
    print('${ok ? 'PASS' : 'FAIL'}  $name');
    if (!ok) {
      failures.add(name);
      if (detail.isNotEmpty) print(detail);
    }
  }

  void write(String rel, String content) => File(p.join(app.path, rel))
    ..createSync(recursive: true)
    ..writeAsStringSync(content);

  Future<String> budget(int expectedExit, String name) async {
    final r = await Process.run(
        'dart',
        [
          p.join(root, brick, 'scripts/agent/budget.dart'),
          app.path,
        ],
        runInShell: true);
    final text = '${r.stdout}${r.stderr}';
    check(name, r.exitCode == expectedExit, text);
    return text;
  }

  try {
    // Within budget.
    write('CLAUDE.md', 'a' * 1000);
    write('AGENTS.md', 'b' * 8000);
    write('.harness/active-context.md', 'c' * 2000);
    write('.claude/rules/ui.md', 'd' * 2000);
    write('.harness/lessons.md', List.filled(60, 'x').join('\n'));
    await budget(0, 'at the limits passes');

    // Always-loaded context over 12k: names the overshoot and the files.
    write('AGENTS.md', 'b' * 9500);
    var text = await budget(1, 'always-loaded context over 12k fails');
    check(
      'names the overshoot and AGENTS.md',
      text.contains('500 over 12000') && text.contains('AGENTS.md 9500'),
      text,
    );
    write('AGENTS.md', 'b' * 8000);

    // Multi-byte text counts characters, not bytes.
    write('AGENTS.md', 'ગ' * 9000);
    await budget(0, 'Gujarati text is counted in characters, not bytes');
    write('AGENTS.md', 'b' * 8000);

    // One rule over 2k.
    write('.claude/rules/network.md', 'e' * 2300);
    text = await budget(1, 'a rule over 2k fails');
    check(
      'names the rule and the overshoot',
      text.contains('.claude/rules/network.md') && text.contains('300 over'),
      text,
    );
    write('.claude/rules/network.md', 'e' * 100);

    // lessons.md over 60 lines.
    write('.harness/lessons.md', List.filled(65, 'x').join('\n'));
    text = await budget(1, 'lessons.md over 60 lines fails');
    check(
        'names lessons.md and 5 lines over', text.contains('5 over 60'), text);

    // Missing files are not a failure.
    app.deleteSync(recursive: true);
    app.createSync(recursive: true);
    await budget(0, 'an empty project passes');
  } finally {
    if (app.existsSync()) app.deleteSync(recursive: true);
  }

  if (failures.isEmpty) {
    print('\nAll budget checks passed.');
  } else {
    print('\n${failures.length} budget check(s) failed.');
    exit(1);
  }
}
