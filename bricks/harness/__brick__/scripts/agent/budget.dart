// ignore_for_file: avoid_print

import 'dart:io';

/// The harness size gate: what loads on every request stays small.
///
///   dart run scripts/agent/budget.dart [root]
///
/// Fails (exit 1) and names the file and the overshoot when
/// - `CLAUDE.md` + `AGENTS.md` + `.harness/active-context.md` > 12k characters,
/// - any `.claude/rules/*.md` > 2k characters,
/// - `.harness/lessons.md` > 60 lines.
///
/// Move knowledge to a path-scoped rule, promote or delete lessons; do not
/// raise the limits. `verify.dart` runs this (also with `--fast`).
void main(List<String> args) {
  final problems = budgetProblems(args.isEmpty ? '.' : args.first);
  if (problems.isEmpty) {
    print('Harness budget OK.');
    return;
  }
  problems.forEach(stderr.writeln);
  exitCode = 1;
}

const alwaysLoadedLimit = 12000;
const ruleLimit = 2000;
const lessonsMaxLines = 60;

/// Budget violations under [root]; empty when within budget.
List<String> budgetProblems(String root) {
  final problems = <String>[];

  var loaded = 0;
  final parts = <String>[];
  for (final path in ['CLAUDE.md', 'AGENTS.md', '.harness/active-context.md']) {
    final size = _chars('$root/$path');
    loaded += size;
    parts.add('$path $size');
  }
  if (loaded > alwaysLoadedLimit) {
    problems.add(
      'Always-loaded context is $loaded chars, ${loaded - alwaysLoadedLimit} '
      'over $alwaysLoadedLimit (${parts.join(', ')}). Move detail into a '
      'path-scoped .claude/rules file or delete it.',
    );
  }

  final rules = Directory('$root/.claude/rules');
  if (rules.existsSync()) {
    final files =
        rules.listSync().whereType<File>().where((f) => f.path.endsWith('.md'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final size = _chars(file.path);
      if (size > ruleLimit) {
        final name = file.path.split(RegExp(r'[\\/]')).last;
        problems.add(
          '.claude/rules/$name is $size chars, ${size - ruleLimit} over '
          '$ruleLimit. Split it by path scope or trim it.',
        );
      }
    }
  }

  final lessons = File('$root/.harness/lessons.md');
  if (lessons.existsSync()) {
    final lines = lessons.readAsLinesSync().length;
    if (lines > lessonsMaxLines) {
      problems.add(
        '.harness/lessons.md is $lines lines, ${lines - lessonsMaxLines} over '
        '$lessonsMaxLines. Run `dart run scripts/agent/learn.dart review`, '
        'then promote or delete.',
      );
    }
  }
  return problems;
}

/// Characters, not bytes: Hindi/Gujarati or emoji must not skew the budget.
int _chars(String path) {
  final file = File(path);
  if (!file.existsSync()) return 0;
  return file.readAsStringSync().runes.length;
}
