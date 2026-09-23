import 'dart:io';

/// Validates that links and paths in documentation files are not broken.
void main() {
  print('Running docs check...');

  final readmeFile = File('README.md');
  if (!readmeFile.existsSync()) {
    print('README.md is missing!');
    exit(1);
  }

  // Simple validation to ensure that any local links in the README actually exist
  final content = readmeFile.readAsStringSync();
  final RegExp linkRegex = RegExp(r'\[.+?\]\((.+?)\)');

  final matches = linkRegex.allMatches(content);
  bool hasErrors = false;

  for (final match in matches) {
    final link = match.group(1);
    // Ignore external URLs and hash links
    if (link != null && !link.startsWith('http') && !link.startsWith('#')) {
      final linkedFile = File(link);
      final linkedDir = Directory(link);

      if (!linkedFile.existsSync() && !linkedDir.existsSync()) {
        print('Broken link in README.md: $link');
        hasErrors = true;
      }
    }
  }

  if (hasErrors) {
    print('Docs check failed.');
    exit(1);
  }

  print('Docs check passed.');
  exit(0);
}
