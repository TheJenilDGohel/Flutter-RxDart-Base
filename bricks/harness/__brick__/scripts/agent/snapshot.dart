import 'dart:io';

Future<void> main() async {
  final snapshotFile = File('.harness/system-snapshot.md');
  if (!snapshotFile.existsSync()) {
    snapshotFile.createSync(recursive: true);
  }

  final buffer = StringBuffer();
  buffer.writeln('# Project Snapshot');
  buffer.writeln('Generated: ${DateTime.now().toUtc().toIso8601String()}');
  buffer.writeln();

  // 1. Features
  final featuresDir = Directory('lib/features');
  final features = <String>[];
  if (featuresDir.existsSync()) {
    for (final entity in featuresDir.listSync()) {
      if (entity is Directory) {
        features.add(entity.path.split(Platform.pathSeparator).last);
      }
    }
  }
  buffer.writeln('## Features (${features.length})');
  if (features.isEmpty) {
    buffer.writeln('_None yet._');
  } else {
    buffer.writeln(features.join(', '));
  }
  buffer.writeln();

  // 2. Routes
  final routes = <String>[];
  final routesFile = File('lib/utils/router/routes.dart');
  if (routesFile.existsSync()) {
    final content = routesFile.readAsStringSync();
    final routeRegex = RegExp(r"static const String (\w+) = '([^']+)';");
    for (final match in routeRegex.allMatches(content)) {
      routes.add('${match.group(1)} → ${match.group(2)}');
    }
  }
  buffer.writeln('## Routes (${routes.length})');
  if (routes.isEmpty) {
    buffer.writeln('_None mapped in routes.dart._');
  } else {
    buffer.writeln(routes.join(' | '));
  }
  buffer.writeln();

  // 3. Git Commits
  buffer.writeln('## Recent Commits');
  try {
    final result = Process.runSync('git', ['log', '--oneline', '-5']);
    if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
      buffer.writeln(result.stdout.toString().trim());
    } else {
      buffer.writeln('_No git history available._');
    }
  } catch (e) {
    buffer.writeln('_Git not available or not a repository._');
  }
  buffer.writeln();

  // 4. Analysis Status
  buffer.writeln('## Analysis');
  try {
    // Run analyzer, but we don't want to show the full output, just the summary
    final result = Process.runSync('flutter', ['analyze', '--no-fatal-infos']);
    if (result.exitCode == 0) {
      buffer.writeln('Clean ✅');
    } else {
      // Try to extract the issue count from the last line
      final lines = result.stdout.toString().trim().split('\n');
      if (lines.isNotEmpty) {
        final lastLine = lines.last;
        if (lastLine.contains('issue')) {
          buffer.writeln('Issues found: $lastLine');
        } else {
          buffer.writeln('Issues found (see `flutter analyze` for details)');
        }
      } else {
        buffer.writeln('Issues found (see `flutter analyze` for details)');
      }
    }
  } catch (e) {
    buffer.writeln('_Analysis failed to run._');
  }

  snapshotFile.writeAsStringSync(buffer.toString());
}
