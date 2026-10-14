// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

/// Fast (<1.5s) in-flight quality gate for recently modified Dart files.
///
/// Features:
/// - Compact Error Stripping: Filters out analyzer boilerplate to preserve token context.
/// - Anti-Loop Circuit Breaker: Detects 3 consecutive identical failure loops and halts
///   runaway agent retries.
///
/// Usage:
///   dart run scripts/agent/on_edit.dart [file1.dart file2.dart ...]
///   dart run scripts/agent/on_edit.dart --reset-guard
Future<void> main(List<String> args) async {
  final guardFile = File('.harness/.loop_guard.json');

  if (args.contains('--reset-guard')) {
    if (guardFile.existsSync()) guardFile.deleteSync();
    print('on_edit: loop guard reset.');
    return;
  }

  final files = <String>{};

  if (args.isNotEmpty) {
    files.addAll(args.where((f) => f.endsWith('.dart') && File(f).existsSync()));
  } else {
    final status = Process.runSync('git', ['status', '--porcelain'], runInShell: true);
    if (status.exitCode == 0) {
      for (final rawLine in (status.stdout as String).split('\n')) {
        if (rawLine.length < 4) continue;
        var path = rawLine.substring(3).trim();
        if (path.startsWith('"') && path.endsWith('"')) {
          path = path.substring(1, path.length - 1);
        }
        if (path.contains(' -> ')) {
          path = path.split(' -> ').last.trim();
        }
        if (path.endsWith('.dart') && File(path).existsSync()) {
          files.add(path);
        }
      }
    }
  }

  final targetFiles = files
      .where((f) => !f.endsWith('.g.dart') && !f.endsWith('.freezed.dart'))
      .toList();

  if (targetFiles.isEmpty) {
    print('on_edit: no modified Dart files to check.');
    return;
  }

  // Always use the active Dart runtime (inherited from FVM or system PATH)
  // to avoid nested wrapper collisions and kernel binary format mismatches.
  final dartExe = Platform.executable;

  print('on_edit: checking ${targetFiles.length} file(s)...');

  // 1. Format check
  final formatResult = await Process.run(
    dartExe,
    ['format', '--output=none', '--set-exit-if-changed', ...targetFiles],
    runInShell: true,
  );
  if (formatResult.exitCode != 0) {
    final formatErrors = _extractFormatErrors(formatResult.stdout.toString(), formatResult.stderr.toString());
    _handleFailure(guardFile, 'format', formatErrors, targetFiles);
    print('on_edit: formatting failed. Run `dart format` on:');
    for (final err in formatErrors.take(5)) {
      print('  - $err');
    }
    exit(formatResult.exitCode != 0 ? formatResult.exitCode : 1);
  }

  // 2. Analyze check
  final analyzeResult = await Process.run(
    dartExe,
    ['analyze', '--fatal-infos', ...targetFiles],
    runInShell: true,
  );
  final analyzeStdout = analyzeResult.stdout.toString();
  final analyzeStderr = analyzeResult.stderr.toString();
  final hasErrors = analyzeResult.exitCode != 0 ||
      analyzeStdout.contains('error - ') ||
      analyzeStdout.contains('issues found') ||
      analyzeStdout.contains('issue found');

  if (hasErrors) {
    final analyzeErrors = _extractAnalyzeErrors(analyzeStdout, analyzeStderr);
    _handleFailure(guardFile, 'analyze', analyzeErrors, targetFiles);
    print('on_edit: analysis failed (${analyzeErrors.length} issues):');
    for (final err in analyzeErrors.take(5)) {
      print('  - $err');
    }
    if (analyzeErrors.length > 5) {
      print('  ...and ${analyzeErrors.length - 5} more issue(s).');
    }
    exit(analyzeResult.exitCode != 0 ? analyzeResult.exitCode : 1);
  }

  // Success: Clear loop guard
  if (guardFile.existsSync()) {
    try {
      guardFile.deleteSync();
    } catch (_) {}
  }

  print('on_edit: clean (format + analyze passed).');
}

void _handleFailure(File guardFile, String stage, List<String> errors, List<String> files) {
  final signature = '$stage:${errors.join('|')}';
  var count = 1;
  final history = <String>[];

  if (guardFile.existsSync()) {
    try {
      final data = jsonDecode(guardFile.readAsStringSync()) as Map<String, dynamic>;
      if (data['signature'] == signature) {
        count = (data['count'] as int? ?? 1) + 1;
      }
      final rawHistory = data['history'] as List<dynamic>? ?? [];
      history.addAll(rawHistory.map((e) => e.toString()));
    } catch (_) {}
  }

  history.add(signature);
  if (history.length > 6) {
    history.removeRange(0, history.length - 6);
  }

  final occurrences = history.where((s) => s == signature).length;
  final effectiveCount = count > occurrences ? count : occurrences;

  try {
    guardFile.parent.createSync(recursive: true);
    guardFile.writeAsStringSync(jsonEncode({
      'signature': signature,
      'stage': stage,
      'count': effectiveCount,
      'history': history,
      'files': files,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }));
  } catch (_) {}

  if (effectiveCount >= 3) {
    stderr.writeln('\n⚠️  CIRCUIT BREAKER: Repeated $stage failure loop detected ($effectiveCount attempts)!');
    stderr.writeln('Halting correction loop to prevent runaway token exhaustion.');
    stderr.writeln('Target files: ${files.join(', ')}');
    stderr.writeln('Recommended: Revert changes (`git checkout <file>`) or pause to clarify requirements with user.');
    stderr.writeln('Reset with: dart run scripts/agent/on_edit.dart --reset-guard\n');
    exit(2);
  }
}

List<String> _extractFormatErrors(String stdout, String stderr) {
  final combined = '$stdout\n$stderr';
  return combined
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.endsWith('.dart') || l.contains('Changed '))
      .toList();
}

List<String> _extractAnalyzeErrors(String stdout, String stderr) {
  final combined = '$stdout\n$stderr';
  return combined
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty &&
          !l.startsWith('Analyzing') &&
          !l.contains('issue found') &&
          !l.contains('issues found'))
      .toList();
}
