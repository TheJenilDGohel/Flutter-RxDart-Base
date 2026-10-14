// ignore_for_file: avoid_print

import 'dart:io';

/// Automates isolated Git worktree provisioning and configuration mirroring
/// for concurrent multi-agent swarms.
///
/// Usage:
/// ```bash
/// dart run scripts/team/worktree.dart create <branch_or_feature> [--session <id>] [--agent <agent>]
/// dart run scripts/team/worktree.dart list
/// dart run scripts/team/worktree.dart prune
/// ```
void main(List<String> args) {
  if (args.isEmpty) {
    _printUsage();
    return;
  }

  final command = args.first;
  switch (command) {
    case 'create':
      if (args.length < 2 || args[1].startsWith('--')) {
        stderr.writeln('Error: branch or feature name required.');
        stderr.writeln('Usage: dart run scripts/team/worktree.dart create <branch_or_feature> [--session <id>] [--agent <agent>]');
        exit(1);
      }
      final branch = args[1];
      final session = _argValue(args, '--session');
      final agent = _argValue(args, '--agent');
      _createWorktree(branch, session: session, agent: agent);
      break;

    case 'list':
      _listWorktrees();
      break;

    case 'prune':
      _pruneWorktrees();
      break;

    default:
      _printUsage();
      break;
  }
}

void _createWorktree(String branch, {String? session, String? agent}) {
  final currentDir = Directory.current;
  final repoName = currentDir.uri.pathSegments.where((s) => s.isNotEmpty).last;
  final sanitizedBranch = branch.replaceAll('/', '-');
  final targetDirName = '$repoName-$sanitizedBranch';
  final targetPath = '${currentDir.parent.path}${Platform.pathSeparator}$targetDirName';

  final targetDir = Directory(targetPath);
  if (targetDir.existsSync()) {
    stderr.writeln('Error: Target directory already exists: $targetPath');
    exit(1);
  }

  print('Creating git worktree for "$branch" at $targetPath...');

  // Check if branch already exists
  final branchCheck = Process.runSync('git', ['rev-parse', '--verify', branch], runInShell: true);
  final branchExists = branchCheck.exitCode == 0;

  final addArgs = branchExists
      ? ['worktree', 'add', targetPath, branch]
      : ['worktree', 'add', '-b', branch, targetPath];

  final addResult = Process.runSync('git', addArgs, runInShell: true);
  if (addResult.exitCode != 0) {
    stderr.writeln('git worktree add failed:');
    stderr.write(addResult.stderr);
    stderr.write(addResult.stdout);
    exit(addResult.exitCode);
  }

  print('Worktree created.');

  // Mirror files from .worktreeinclude
  final includeFile = File('.worktreeinclude');
  final patterns = <String>[];
  if (includeFile.existsSync()) {
    patterns.addAll(
      includeFile
          .readAsLinesSync()
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty && !l.startsWith('#')),
    );
  } else {
    patterns.addAll(['.env', '.claude', '.harness']);
  }

  var copiedCount = 0;
  for (final pattern in patterns) {
    if (pattern.contains('*')) {
      final matches = _globFiles(currentDir, pattern);
      for (final f in matches) {
        final rel = f.path.substring(currentDir.path.length + 1);
        _copyEntity(f, File('$targetPath${Platform.pathSeparator}$rel'), Directory('$targetPath${Platform.pathSeparator}$rel'));
        copiedCount++;
      }
    } else {
      final file = File(pattern);
      final dir = Directory(pattern);
      if (file.existsSync()) {
        _copyEntity(file, File('$targetPath${Platform.pathSeparator}$pattern'), Directory('$targetPath${Platform.pathSeparator}$pattern'));
        copiedCount++;
      } else if (dir.existsSync()) {
        _copyEntity(dir, File('$targetPath${Platform.pathSeparator}$pattern'), Directory('$targetPath${Platform.pathSeparator}$pattern'));
        copiedCount++;
      }
    }
  }

  print('Mirrored $copiedCount configuration item(s) into worktree.');

  if (session != null || agent != null) {
    final sessionId = session ?? 'session-${DateTime.now().millisecondsSinceEpoch}';
    final agentName = agent ?? 'general';
    final regResult = Process.runSync(
      'dart',
      ['run', 'scripts/team/task_handoff.dart', 'register-session', '--session', sessionId, '--agent', agentName],
      workingDirectory: targetPath,
      runInShell: true,
    );
    if (regResult.exitCode == 0) {
      print('Registered session $sessionId (@$agentName) in worktree.');
    }
  }

  print('\nWorktree ready! To enter:');
  print('  cd "$targetPath"');
}

void _listWorktrees() {
  final result = Process.runSync('git', ['worktree', 'list'], runInShell: true);
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    exit(result.exitCode);
  }
  print(result.stdout);
}

void _pruneWorktrees() {
  print('Pruning stale git worktrees...');
  final result = Process.runSync('git', ['worktree', 'prune', '-v'], runInShell: true);
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    exit(result.exitCode);
  }
  print(result.stdout.toString().isEmpty ? 'No stale worktrees to prune.' : result.stdout);
}

List<File> _globFiles(Directory root, String pattern) {
  final regexPattern = '^${RegExp.escape(pattern).replaceAll(r'\*', '.*')}\$';
  final regex = RegExp(regexPattern);
  final files = <File>[];
  try {
    for (final entity in root.listSync(recursive: false)) {
      if (entity is File) {
        final name = entity.uri.pathSegments.last;
        if (regex.hasMatch(name)) {
          files.add(entity);
        }
      }
    }
  } catch (_) {}
  return files;
}

void _copyEntity(FileSystemEntity src, File destFile, Directory destDir) {
  try {
    if (src is File) {
      destFile.parent.createSync(recursive: true);
      src.copySync(destFile.path);
    } else if (src is Directory) {
      destDir.createSync(recursive: true);
      for (final child in src.listSync(recursive: true)) {
        final rel = child.path.substring(src.path.length + 1);
        if (child is File) {
          final target = File('${destDir.path}${Platform.pathSeparator}$rel');
          target.parent.createSync(recursive: true);
          child.copySync(target.path);
        } else if (child is Directory) {
          Directory('${destDir.path}${Platform.pathSeparator}$rel').createSync(recursive: true);
        }
      }
    }
  } catch (_) {}
}

String? _argValue(List<String> args, String name) {
  final idx = args.indexOf(name);
  if (idx != -1 && idx + 1 < args.length) {
    return args[idx + 1];
  }
  return null;
}

void _printUsage() {
  print('Usage:');
  print('  dart run scripts/team/worktree.dart create <branch_or_feature> [--session <id>] [--agent <agent>]');
  print('  dart run scripts/team/worktree.dart list');
  print('  dart run scripts/team/worktree.dart prune');
}
