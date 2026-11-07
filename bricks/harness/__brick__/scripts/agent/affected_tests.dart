// ignore_for_file: avoid_print

import 'dart:io';

/// Runs only the tests that cover the files you changed, and prints only
/// failures. Use it after each change; the full suite (`verify.dart`) is for
/// milestones and commits that touch shared code.
///
/// Mapping: a changed `test/**_test.dart` runs itself; a changed `lib/a/b/c.dart`
/// runs the closest existing mirror folder below the top level (`test/a/b`).
/// Changes to shared code (anything in `lib/` outside `lib/features/`) affect
/// every feature: the script says so and suggests the full suite.
///
/// Usage:
///   dart run scripts/agent/affected_tests.dart            # uncommitted changes
///   dart run scripts/agent/affected_tests.dart --since main
///   dart run scripts/agent/affected_tests.dart --dry-run  # list targets only
Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final sinceIndex = args.indexOf('--since');
  final since = sinceIndex >= 0 && sinceIndex + 1 < args.length
      ? args[sinceIndex + 1]
      : null;

  final changed = _changedFiles(since);
  final targets = <String>{};
  final shared = <String>{};

  for (final path in changed) {
    if (!path.endsWith('.dart') || _isGenerated(path)) continue;
    if (path.startsWith('test/') && path.endsWith('_test.dart')) {
      if (File(path).existsSync()) targets.add(path);
      continue;
    }
    if (!path.startsWith('lib/')) continue;
    if (_isShared(path)) shared.add(path);
    final mirror = _closestMirror(path);
    if (mirror != null) targets.add(mirror);
  }

  // A folder target already covers any single test file inside it.
  final folders = targets.where((t) => !t.endsWith('.dart')).toList();
  targets.removeWhere(
    (t) => t.endsWith('.dart') && folders.any((f) => t.startsWith('$f/')),
  );

  if (shared.isNotEmpty) {
    print(
      'Shared code changed (${shared.length} files): run the full suite '
      'before committing (dart run scripts/agent/verify.dart).',
    );
  }
  if (targets.isEmpty) {
    print('affected_tests: no tests map to the changed files.');
    return;
  }
  final sorted = targets.toList()..sort();
  print('affected_tests: ${sorted.length} target(s): ${sorted.join(' ')}');
  if (dryRun) return;

  final fvm = Directory('.fvm').existsSync() || File('.fvmrc').existsSync();
  final testArgs = ['test', '--reporter', 'failures-only', ...sorted];
  final result = fvm
      ? await Process.run('fvm', ['flutter', ...testArgs], runInShell: true)
      : await Process.run('flutter', testArgs, runInShell: true);

  final out = '${result.stdout}${result.stderr}'
      .split('\n')
      .where((l) => l.trim().isNotEmpty)
      .toList();
  // `fvm` on Windows can return 0 for a failed run, so read the output too.
  final failed =
      result.exitCode != 0 ||
      out.any((l) => l.contains('Some tests failed') || _failCount.hasMatch(l));
  if (!failed) {
    print('affected_tests: PASS');
    return;
  }
  const maxLines = 80;
  final tail = out.length > maxLines ? out.sublist(out.length - maxLines) : out;
  if (out.length > maxLines) print('... ${out.length - maxLines} lines cut');
  print(tail.join('\n'));
  print('affected_tests: FAIL');
  exitCode = result.exitCode == 0 ? 1 : result.exitCode;
}

/// A test progress line with failures, e.g. `00:05 +44 -1: ...` or `+14 -1: ...`.
final _failCount = RegExp(r'(?:^|\s)\+\d+(?: ~\d+)? -\d+:');

/// Everything in `lib/` outside `lib/features/` is shared code: the folders
/// the project brick generates (`redux/`, `networking/`, `utils/`, ...) and
/// any an app adds (`core/`, `config/`, `storage/`).
bool _isShared(String path) =>
    path.startsWith('lib/') && !path.startsWith('lib/features/');

bool _isGenerated(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.freezed.dart') ||
    path.contains('/generated/');

/// `lib/a/b/c/d.dart` -> the deepest existing of `test/a/b/c`, `test/a/b`.
/// Never a top-level folder such as `test/features` (that is the full suite).
String? _closestMirror(String libPath) {
  final parts = libPath.split('/')..removeAt(0);
  parts.removeLast();
  while (parts.length >= 2) {
    final dir = 'test/${parts.join('/')}';
    if (Directory(dir).existsSync()) return dir;
    parts.removeLast();
  }
  return null;
}

List<String> _changedFiles(String? since) {
  final files = <String>{};
  if (since != null) {
    final diff = Process.runSync('git', [
      'diff',
      '--name-only',
      '$since...HEAD',
    ], runInShell: true);
    if (diff.exitCode == 0) {
      files.addAll((diff.stdout as String).split('\n').map((l) => l.trim()));
    }
  }
  final status = Process.runSync('git', [
    'status',
    '--porcelain',
  ], runInShell: true);
  if (status.exitCode == 0) {
    for (final raw in (status.stdout as String).split('\n')) {
      if (raw.length < 4) continue;
      var path = raw.substring(3).trim();
      if (path.contains(' -> ')) path = path.split(' -> ').last.trim();
      if (path.startsWith('"') && path.endsWith('"')) {
        path = path.substring(1, path.length - 1);
      }
      files.add(path);
    }
  }
  files.removeWhere((f) => f.isEmpty);
  return files.toList();
}
