// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Incremental background diagnostics daemon for AI agents and developers.
///
/// Watches `lib/` and `test/` for changes, runs format and static analysis
/// on modified Dart files in-flight, and maintains a live `.harness/diagnostics.json`.
///
/// AI agents can read `.harness/diagnostics.json` instantly with zero execution overhead.
///
/// Usage:
///   dart run scripts/agent/watch.dart
void main() {
  final roots = ['lib', 'test'].map(Directory.new).where((d) => d.existsSync()).toList();

  if (roots.isEmpty) {
    stderr.writeln('watch: neither lib/ nor test/ directory found.');
    exit(1);
  }

  final fvm = Directory('.fvm').existsSync() || File('.fvmrc').existsSync();
  final cmd = fvm ? 'fvm' : 'dart';
  final prefix = fvm ? ['dart'] : <String>[];

  final diagFile = File('.harness/diagnostics.json');
  diagFile.parent.createSync(recursive: true);

  _saveDiagnostics(diagFile, {
    'status': 'idle',
    'started_at': DateTime.now().toUtc().toIso8601String(),
    'last_file': null,
    'diagnostics': <String>[],
  });

  print('watch: watching ${roots.map((d) => d.path).join(', ')} for changes (FVM: $fvm)...');

  Timer? debounceTimer;
  final pendingFiles = <String>{};

  for (final root in roots) {
    root.watch(recursive: true).listen((event) {
      final path = event.path;
      if (!path.endsWith('.dart')) return;
      if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) return;
      if (path.contains('.dart_tool') || path.contains('build/')) return;
      if (!File(path).existsSync()) return;

      pendingFiles.add(path);
      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(milliseconds: 400), () async {
        final targets = List<String>.from(pendingFiles);
        pendingFiles.clear();

        for (final file in targets) {
          if (!File(file).existsSync()) continue;
          final time = _timestamp();
          final errors = <String>[];

          // 1. Format check
          final formatRes = await Process.run(
            cmd,
            [...prefix, 'format', '--output=none', '--set-exit-if-changed', file],
            runInShell: true,
          );
          if (formatRes.exitCode != 0) {
            errors.add('Format violation: run `dart format $file`');
          }

          // 2. Analyze check
          final analyzeRes = await Process.run(
            cmd,
            [...prefix, 'analyze', '--fatal-infos', file],
            runInShell: true,
          );
          if (analyzeRes.exitCode != 0) {
            final output = '${analyzeRes.stdout}${analyzeRes.stderr}'.trim();
            errors.addAll(
              output
                  .split('\n')
                  .map((l) => l.trim())
                  .where((l) => l.isNotEmpty && !l.startsWith('Analyzing')),
            );
          }

          final isClean = errors.isEmpty;
          _saveDiagnostics(diagFile, {
            'status': isClean ? 'clean' : 'has_issues',
            'checked_at': DateTime.now().toUtc().toIso8601String(),
            'last_file': file,
            'diagnostics': errors,
          });

          if (isClean) {
            print('[$time] $file -> clean');
          } else {
            print('[$time] $file -> ${errors.length} issue(s):');
            for (final err in errors.take(3)) {
              print('  - $err');
            }
          }
        }
      });
    });
  }
}

String _timestamp() {
  final now = DateTime.now();
  return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
}

void _saveDiagnostics(File file, Map<String, dynamic> data) {
  try {
    file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data), flush: true);
  } catch (_) {}
}
