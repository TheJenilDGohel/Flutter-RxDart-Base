import 'dart:io';

/// Enforces AGENTS.md maintainer rule 1 for every versioned unit:
///
/// * if a unit's shipped files changed since [base], its version must have
///   increased (semver, not just "a +version: line exists"), and
/// * its CHANGELOG.md must contain a heading for the new version.
///
/// Also checks that the harness `.harness/version.json` stamp always
/// matches `bricks/harness/brick.yaml`.
///
/// Usage: `dart run tool/version_gate.dart <base-ref>`
/// (e.g. `origin/main`). Run from the repository root.
void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('usage: dart run tool/version_gate.dart <base-ref>');
    exit(64);
  }
  final base = args.single;
  final changed = _git(['diff', '--name-only', '$base...HEAD'])
      .split('\n')
      .where((l) => l.isNotEmpty)
      .toList();

  final failures = <String>[];

  for (final unit in _units) {
    final touched = changed.any(unit.ships);
    if (!touched) continue;

    final before = _versionAt(base, unit.versionFile, unit.versionPattern);
    final after = _versionIn(
      File(unit.versionFile).readAsStringSync(),
      unit.versionPattern,
    );
    if (after == null) {
      failures.add('${unit.name}: no version found in ${unit.versionFile}.');
      continue;
    }
    if (before != null && _compare(after, before) <= 0) {
      failures.add(
        '${unit.name}: shipped files changed but version $after is not '
        'greater than $before (${unit.versionFile}).',
      );
    }
    final changelog = File(unit.changelog);
    final heading =
        RegExp('^## \\[?${RegExp.escape(after)}\\]?\\b', multiLine: true);
    if (!changelog.existsSync() ||
        !heading.hasMatch(changelog.readAsStringSync())) {
      failures.add(
        '${unit.name}: ${unit.changelog} has no "## $after" entry.',
      );
    }
  }

  final harnessVersion = _versionIn(
    File('bricks/harness/brick.yaml').readAsStringSync(),
    _yamlVersion,
  );
  final stamp = RegExp(r'"version":\s*"([^"]+)"').firstMatch(
    File('bricks/harness/__brick__/.harness/version.json').readAsStringSync(),
  );
  if (stamp?.group(1) != harnessVersion) {
    failures.add(
      'harness: .harness/version.json says ${stamp?.group(1)} but '
      'brick.yaml says $harnessVersion.',
    );
  }

  if (failures.isEmpty) {
    print('Version gate passed.');
    return;
  }
  for (final f in failures) {
    // GitHub Actions annotation; harmless elsewhere.
    print('::error::$f');
  }
  exit(1);
}

final _yamlVersion = RegExp(r'^version:\s*([0-9][^\s]*)', multiLine: true);

class _Unit {
  const _Unit(this.name, this.root, this.versionFile, this.changelog);
  final String name;
  final String root;
  final String versionFile;
  final String changelog;
  RegExp get versionPattern => _yamlVersion;

  /// Files that end up in a generated app (or in the published package).
  /// Docs-only edits (README, CHANGELOG) do not require a bump.
  bool ships(String path) {
    if (!path.startsWith('$root/')) return false;
    final rel = path.substring(root.length + 1);
    if (rel == 'README.md' || rel == 'CHANGELOG.md') return false;
    if (rel.startsWith('example/') || rel.startsWith('test/')) return false;
    return true;
  }
}

const _units = [
  _Unit('project', 'bricks/project', 'bricks/project/brick.yaml',
      'bricks/project/CHANGELOG.md'),
  _Unit('bloc', 'bricks/bloc', 'bricks/bloc/brick.yaml',
      'bricks/bloc/CHANGELOG.md'),
  _Unit('harness', 'bricks/harness', 'bricks/harness/brick.yaml',
      'bricks/harness/CHANGELOG.md'),
  _Unit(
      'redux_rxdart_lints',
      'packages/redux_rxdart_lints',
      'packages/redux_rxdart_lints/pubspec.yaml',
      'packages/redux_rxdart_lints/CHANGELOG.md'),
];

String _git(List<String> args) {
  final result = Process.runSync('git', args);
  if (result.exitCode != 0) {
    stderr.writeln('git ${args.join(' ')} failed: ${result.stderr}');
    exit(2);
  }
  return result.stdout as String;
}

String? _versionAt(String ref, String path, RegExp pattern) {
  final result = Process.runSync('git', ['show', '$ref:$path']);
  if (result.exitCode != 0) return null; // new unit
  return _versionIn(result.stdout as String, pattern);
}

String? _versionIn(String content, RegExp pattern) =>
    pattern.firstMatch(content)?.group(1);

/// Compares `major.minor.patch` (pre-release/build suffixes ignored).
int _compare(String a, String b) {
  List<int> parts(String v) => v
      .split(RegExp(r'[-+]'))
      .first
      .split('.')
      .map((p) => int.tryParse(p) ?? 0)
      .toList();
  final pa = parts(a), pb = parts(b);
  for (var i = 0; i < 3; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}
