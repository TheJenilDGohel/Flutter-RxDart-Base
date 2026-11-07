// ignore_for_file: avoid_print

import 'dart:io';

/// The project's quality gate. Cross-platform; `verify.sh` / `verify.ps1`
/// are thin wrappers around it.
///
///   dart scripts/agent/verify.dart            # full gate
///   dart scripts/agent/verify.dart --fast     # budget + format + analyze only
///   dart scripts/agent/verify.dart --no-snapshot
///
/// Steps stop at the first failure and print compact, actionable failure output,
/// stripping internal framework stack traces and boilerplate to protect agent token context.
///
/// FVM: when `.fvm/` or `.fvmrc` exists, all subprocess calls use
/// `fvm dart` / `fvm flutter` instead of bare `dart` / `flutter`.
Future<void> main(List<String> args) async {
  final fast = args.contains('--fast');
  final snapshot = !args.contains('--no-snapshot') && !fast;
  final fvm = _useFvm();
  if (fvm) print('FVM detected — using `fvm dart` / `fvm flutter`.\n');
  final lintGap = _lintPluginGap();
  if (lintGap != null) {
    print(
      'WARNING: golden-rule lints are NOT running: $lintGap.\n'
      'The 🔒 rules in AGENTS.md are unchecked until this is fixed: pin a '
      'newer SDK for this project with FVM (`fvm use 3.47.9`) or upgrade '
      'Flutter.\n',
    );
  }
  if (_belowTlsFix()) {
    print(
      'WARNING: Dart ${Platform.version.split(' ').first} (Flutter < 3.47.8) '
      'builds Android, Windows and Linux apps whose dart:io TLS trusts the '
      'compromised eMudhra intermediate CAs (GHSA-frr6-h895-5pxp). Ship '
      'release builds from Flutter 3.47.8+: `fvm use 3.47.9`.\n',
    );
  }

  final sources = ['lib', 'test'].where((d) => Directory(d).existsSync());
  final steps = <_Step>[
    if (File('scripts/agent/budget.dart').existsSync())
      const _Step('Budget', 'dart', ['scripts/agent/budget.dart']),
    _Step('Formatting', 'dart', [
      'format',
      '--set-exit-if-changed',
      ...sources,
    ]),
    // Also runs the redux_rxdart_lints analyzer plugin (analysis_options.yaml).
    const _Step('Analyzer', 'flutter', ['analyze', '--fatal-infos']),
    if (!fast && Directory('test').existsSync())
      const _Step('Tests', 'flutter', [
        'test',
        '--no-test-assets',
        '--reporter',
        'failures-only',
      ]),
    if (!fast && File('scripts/agent/learn.dart').existsSync())
      const _Step('Lessons', 'dart', [
        'scripts/agent/learn.dart',
        'check',
      ], echo: true),
    if (snapshot)
      const _Step('Snapshot', 'dart', ['scripts/agent/snapshot.dart']),
  ];

  for (var i = 0; i < steps.length; i++) {
    final step = steps[i];
    stdout.write('[${i + 1}/${steps.length}] ${step.label}... ');
    final sw = Stopwatch()..start();
    final result = await _run(fvm, step.exe, step.args);
    if (result.exitCode != 0) {
      print('FAILED');
      final cmd = fvm ? 'fvm ${step.exe}' : step.exe;
      print('\$ $cmd ${step.args.join(' ')}');
      _printCompactFailure(
        step.label,
        result.stdout.toString(),
        result.stderr.toString(),
      );
      exitCode = 1;
      return;
    }
    print('ok (${(sw.elapsedMilliseconds / 1000).toStringAsFixed(1)}s)');
    if (step.echo) print('      ${(result.stdout as String).trim()}');
  }
  print(
    lintGap == null
        ? 'All quality gates passed.'
        : 'Quality gates passed WITHOUT the golden-rule lints ($lintGap).',
  );
}

/// Why the `redux_rxdart_lints` analyzer plugin cannot run here, or null.
///
/// `flutter analyze` skips a git-sourced plugin on Dart < 3.13 without an
/// error, so a green analyzer step alone does not prove the rules ran.
String? _lintPluginGap() {
  final options = File('analysis_options.yaml');
  if (!options.existsSync()) return 'no analysis_options.yaml';
  final text = options.readAsStringSync();
  if (!text.contains('redux_rxdart_lints:')) {
    return 'analysis_options.yaml does not enable redux_rxdart_lints';
  }
  if (!RegExp(r'redux_rxdart_lints:\s*\n\s+git:').hasMatch(text)) return null;
  final v = RegExp(r'^(\d+)\.(\d+)\.\d+').firstMatch(Platform.version);
  if (v == null) return null;
  final major = int.parse(v[1]!);
  final minor = int.parse(v[2]!);
  if (major > 3 || (major == 3 && minor >= 13)) return null;
  return 'Dart ${v[0]} skips git-sourced analyzer plugins '
      '(needs Dart 3.13 / Flutter 3.47 or newer)';
}

/// True on Dart SDKs before 3.13.7 (Flutter 3.47.8), which still trust the
/// compromised eMudhra intermediate CAs in dart:io (GHSA-frr6-h895-5pxp).
bool _belowTlsFix() {
  final v = RegExp(r'^(\d+)\.(\d+)\.(\d+)').firstMatch(Platform.version);
  if (v == null) return false;
  final parts = [for (var i = 1; i <= 3; i++) int.parse(v[i]!)];
  const fixed = [3, 13, 7];
  for (var i = 0; i < 3; i++) {
    if (parts[i] != fixed[i]) return parts[i] < fixed[i];
  }
  return false;
}

void _printCompactFailure(String label, String stdoutText, String stderrText) {
  final combined = '$stdoutText\n$stderrText';

  if (label == 'Formatting') {
    final files = combined
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.endsWith('.dart') || l.contains('Changed '))
        .toList();
    print('Formatting issues found. Run `dart format` on:');
    for (final f in files.take(5)) {
      print('  - $f');
    }
    return;
  }

  if (label == 'Analyzer') {
    final issueRegex = RegExp(r'^\s*(info|warning|error)\s*-');
    var issues = combined
        .split('\n')
        .map((l) => l.trim())
        .where((l) => issueRegex.hasMatch(l))
        .toList();
    if (issues.isEmpty) {
      issues = combined
          .split('\n')
          .map((l) => l.trim())
          .where(
            (l) =>
                l.isNotEmpty &&
                !l.startsWith('Analyzing') &&
                !l.startsWith('Resolving') &&
                !l.startsWith('Downloading') &&
                !l.startsWith('Got') &&
                !l.contains('issue found') &&
                !l.contains('issues found'),
          )
          .toList();
    }
    print('Analysis issues (${issues.length}):');
    for (final issue in issues.take(6)) {
      print('  - $issue');
    }
    if (issues.length > 6) {
      print('  ...and ${issues.length - 6} more issue(s).');
    }
    return;
  }

  if (label == 'Tests') {
    final lines = combined.split('\n');
    final failureLines = <String>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('FAIL') ||
          line.contains('Expected:') ||
          line.contains('Actual:') ||
          line.contains('Which:') ||
          line.contains('package:') ||
          line.contains('test/') ||
          line.contains(r'test\')) {
        // Exclude framework and test runner internals
        if (!line.contains('package:flutter/src/') &&
            !line.contains('package:flutter_test/') &&
            !line.contains('package:test_api/') &&
            !line.contains('package:matcher/') &&
            !line.contains('dart:async/') &&
            !line.contains('dart:isolate/')) {
          failureLines.add(line.trim());
        }
      }
    }
    if (failureLines.isNotEmpty) {
      print('Test failure summary:');
      for (final line in failureLines.take(12)) {
        print('  $line');
      }
      return;
    }
  }

  // Fallback trimmed output
  final trimmed = combined.trim();
  if (trimmed.length > 1500) {
    stdout.write(
      '${trimmed.substring(0, 1500)}\n... (output truncated for token efficiency)',
    );
  } else {
    stdout.write(trimmed);
  }
  print('');
}

/// Returns true when FVM manages this project's SDK.
bool _useFvm() {
  if (Platform.environment['CI'] == 'true' ||
      Platform.environment['GITHUB_ACTIONS'] == 'true') {
    return false;
  }
  return Directory('.fvm').existsSync() || File('.fvmrc').existsSync();
}

/// Runs a `dart` or `flutter` command through FVM when applicable.
Future<ProcessResult> _run(bool fvm, String exe, List<String> args) {
  if (exe == 'dart') {
    return Process.run(Platform.executable, args, runInShell: true);
  }
  if (fvm) {
    return Process.run('fvm', [exe, ...args], runInShell: true);
  }
  return Process.run(exe, args, runInShell: true);
}

class _Step {
  const _Step(this.label, this.exe, this.args, {this.echo = false});
  final String label;
  final String exe;
  final List<String> args;

  /// Print the tool's output on success too.
  final bool echo;
}
