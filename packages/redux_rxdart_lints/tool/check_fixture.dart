// Checks the example/ fixture against the plugin in this package.
//
// Every line that must be flagged carries `// expect_lint: <rule>` on the
// line above it. The check fails when an expected diagnostic is missing or a
// plugin diagnostic appears anywhere else.
//
//   dart run tool/check_fixture.dart
import 'dart:io';

const _rules = {
  'no_rxdart_in_ui',
  'no_setstate_in_widget',
  'no_exception_tostring',
  'no_screenutil_in_private_widget',
  'repo_transport_only',
  'no_with_opacity',
  'no_unclosed_subject',
  'no_fetch_without_token',
};

Future<void> main() async {
  final package = Directory.current.absolute.path.replaceAll('\\', '/');
  final example = Directory('$package/example');
  if (!example.existsSync()) {
    stderr.writeln('Run from the package root (example/ not found).');
    exit(64);
  }

  final options = File('${example.path}/analysis_options.yaml');
  final original = options.readAsStringSync();
  options.writeAsStringSync(
    '$original\nplugins:\n  redux_rxdart_lints:\n    path: $package\n',
  );

  final ProcessResult result;
  try {
    await _run('flutter', ['pub', 'get'], example.path);
    result = await Process.run(
      'dart',
      ['analyze', '--format=machine'],
      workingDirectory: example.path,
      runInShell: true,
    );
  } finally {
    options.writeAsStringSync(original);
  }

  final expected = _expected(example);
  final actual = <String>{};
  // SEVERITY|TYPE|CODE|FILE|LINE|COLUMN|LENGTH|MESSAGE
  for (final line in '${result.stdout}\n${result.stderr}'.split('\n')) {
    final parts = line.split('|');
    if (parts.length < 8) continue;
    final code = parts[2].toLowerCase().split('/').last;
    if (!_rules.contains(code)) continue;
    final file = _relative(parts[3], example.path);
    actual.add('$file:${parts[4]}:$code');
  }

  final missing = expected.difference(actual);
  final unexpected = actual.difference(expected);
  for (final m in missing) {
    stderr.writeln('missing    $m');
  }
  for (final u in unexpected) {
    stderr.writeln('unexpected $u');
  }
  if (missing.isEmpty && unexpected.isEmpty) {
    stdout.writeln('Fixture OK: ${expected.length} expected diagnostics.');
    return;
  }
  exit(1);
}

/// `file:line:rule` for the line after each `// expect_lint: rule`.
Set<String> _expected(Directory example) {
  final marker = RegExp(r'//\s*expect_lint:\s*(\w+)');
  final out = <String>{};
  final lib = Directory('${example.path}/lib');
  for (final entity in lib.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final match = marker.firstMatch(lines[i]);
      if (match == null) continue;
      final file = _relative(entity.path, example.path);
      out.add('$file:${i + 2}:${match.group(1)}');
    }
  }
  return out;
}

String _relative(String path, String root) {
  // `--format=machine` escapes each backslash as `\\`.
  final p = path.replaceAll(r'\\', '/').replaceAll('\\', '/');
  final r = root.replaceAll('\\', '/');
  final index = p.toLowerCase().indexOf(r.toLowerCase());
  return index == -1 ? p : p.substring(index + r.length + 1);
}

Future<void> _run(String exe, List<String> args, String dir) async {
  final r = await Process.run(
    exe,
    args,
    workingDirectory: dir,
    runInShell: true,
  );
  if (r.exitCode != 0) {
    stderr
      ..writeln('$exe ${args.join(' ')} failed:')
      ..writeln(r.stdout)
      ..writeln(r.stderr);
    exit(r.exitCode);
  }
}
