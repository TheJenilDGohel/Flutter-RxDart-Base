import 'dart:io';

/// Validates that links and paths in documentation files are not broken.
void main() {
  print('Running docs check...');

  final Set<String> checkedFiles = {};
  bool hasErrors = false;

  final filesToCheck = <File>[
    File('README.md'),
    ...Directory('docs')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.md')),
    ...Directory('bricks')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('README.md')),
    File('packages/redux_rxdart_lints/README.md'),
  ];

  final RegExp linkRegex = RegExp(r'\[.+?\]\((.+?)\)');

  for (final file in filesToCheck) {
    if (!file.existsSync()) continue;
    checkedFiles.add(file.path);

    final content = file.readAsStringSync();
    final matches = linkRegex.allMatches(content);

    for (final match in matches) {
      final link = match.group(1);
      if (link == null) continue;

      // Ignore external URLs, anchors, mailto, and templated mustache links
      if (link.startsWith('http') ||
          link.startsWith('#') ||
          link.startsWith('mailto:') ||
          link.contains('{{')) {
        continue;
      }

      // Strip query parameters and anchors
      final cleanLink = link.split('?').first.split('#').first;
      if (cleanLink.isEmpty) continue;

      // Resolve path relative to the markdown file's directory
      final fileDir = file.parent.path;
      final targetPath = cleanLink.startsWith('/')
          ? cleanLink.substring(1)
          : '$fileDir/$cleanLink';

      final linkedFile = File(targetPath);
      final linkedDir = Directory(targetPath);

      if (!linkedFile.existsSync() && !linkedDir.existsSync()) {
        print('Broken link in ${file.path}: $link (resolved: $targetPath)');
        hasErrors = true;
      }
    }
  }

  print('Checked ${checkedFiles.length} documentation files.');

  if (hasErrors) {
    print('Docs check failed.');
    exit(1);
  }

  print('Docs check passed.');
  exit(0);
}
