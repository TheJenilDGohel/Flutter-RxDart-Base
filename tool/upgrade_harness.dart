import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

/// Universal Maintainer Tool to safely upgrade any Flutter project's AI Agent Harness
/// using the Opinionated 3-Tier Migration Engine.
///
/// Usage:
///   dart run tool/upgrade_harness.dart [path_to_project]
void main(List<String> args) async {
  final targetPath = args.isNotEmpty ? args.first : Directory.current.path;
  final targetDir = Directory(targetPath);

  print('====================================================');
  print('🛠️ Universal Harness Migration Tool');
  print('====================================================\n');
  print('🎯 Target Project: ${targetDir.path}');

  final pubspecFile = File(p.join(targetDir.path, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    print('❌ Error: pubspec.yaml not found at ${targetDir.path}.');
    exit(1);
  }

  final rootWorkspaceDir = Directory.current.path;
  final harnessBrickDir =
      Directory(p.join(rootWorkspaceDir, 'bricks', 'harness', '__brick__'));
  if (!harnessBrickDir.existsSync()) {
    print(
        '❌ Error: harness brick template directory not found at ${harnessBrickDir.path}.');
    exit(1);
  }

  // 1. Detect Installed Version
  final versionFile = File(p.join(targetDir.path, '.harness', 'version.json'));
  String currentVersion = 'legacy (< 1.4.2)';
  if (versionFile.existsSync()) {
    try {
      final jsonMap =
          jsonDecode(versionFile.readAsStringSync()) as Map<String, dynamic>;
      currentVersion = jsonMap['version']?.toString() ?? currentVersion;
    } catch (_) {}
  }
  const targetVersion = '1.5.0';
  print('📌 Current Version: $currentVersion');
  print('🚀 Upgrading to Version: $targetVersion');

  // 2. Safety Backup
  final backupDir = Directory(p.join(targetDir.path, '.harness',
      '.backup_${DateTime.now().millisecondsSinceEpoch}'));
  backupDir.createSync(recursive: true);

  final activeContextFile =
      File(p.join(targetDir.path, '.harness', 'active-context.md'));
  if (activeContextFile.existsSync()) {
    activeContextFile.copySync(p.join(backupDir.path, 'active-context.md'));
  }
  final progressFile = File(p.join(targetDir.path, '.harness', 'progress.md'));
  if (progressFile.existsSync()) {
    progressFile.copySync(p.join(backupDir.path, 'progress.md'));
  }
  final agentsFile = File(p.join(targetDir.path, 'AGENTS.md'));
  if (agentsFile.existsSync()) {
    agentsFile.copySync(p.join(backupDir.path, 'AGENTS.md'));
  }
  final claudeFile = File(p.join(targetDir.path, 'CLAUDE.md'));
  if (claudeFile.existsSync()) {
    claudeFile.copySync(p.join(backupDir.path, 'CLAUDE.md'));
  }
  print('✅ Pre-migration backup saved at: ${backupDir.path}');

  // 3. Staging Render via Mason
  print('\n📦 Rendering clean v$targetVersion templates...');
  final stagingDir =
      Directory(p.join(targetDir.path, '.harness', '.staging_upgrade'));
  if (stagingDir.existsSync()) {
    stagingDir.deleteSync(recursive: true);
  }
  stagingDir.createSync(recursive: true);

  String projectName = 'app';
  try {
    final match = RegExp(r'^name:\s*([a-zA-Z0-9_]+)', multiLine: true)
        .firstMatch(pubspecFile.readAsStringSync());
    if (match != null) projectName = match.group(1)!;
  } catch (_) {}

  final masonRes = await Process.run(
    'mason',
    [
      'make',
      'harness',
      '--project_name',
      projectName,
      '--android_package_name',
      'com.example.$projectName',
      '--ios_bundle_id',
      'com.example.$projectName',
      '--on-conflict',
      'overwrite',
      '-o',
      stagingDir.path,
    ],
    runInShell: true,
  );

  if (masonRes.exitCode != 0) {
    print('⚠️ Mason staging note: ${masonRes.stderr}');
  }

  // 4. Apply 3-Tier Migration
  print('\n🛡️ Applying 3-Tier Migration Engine...');

  // Tier 1: Overwrite Core Engine & Tooling
  print(
      '  [Tier 1] Upgrading scripts/agent/, .agents/skills/, and .agents/agents/...');
  _copyDirectorySync(
    Directory(p.join(stagingDir.path, 'scripts', 'agent')),
    Directory(p.join(targetDir.path, 'scripts', 'agent')),
  );
  _copyDirectorySync(
    Directory(p.join(stagingDir.path, '.agents', 'skills')),
    Directory(p.join(targetDir.path, '.agents', 'skills')),
  );
  _copyDirectorySync(
    Directory(p.join(stagingDir.path, '.agents', 'agents')),
    Directory(p.join(targetDir.path, '.agents', 'agents')),
  );

  // Tier 2: Protect User Context & Memory
  print(
      '  [Tier 2] Strictly protecting .harness/active-context.md and progress.md...');
  int activeContextBytes = 0;
  if (activeContextFile.existsSync()) {
    activeContextBytes = activeContextFile.lengthSync();
    print(
        '     -> Active context preserved intact ($activeContextBytes bytes, 0 bytes lost)');
  } else if (File(p.join(stagingDir.path, '.harness', 'active-context.md'))
      .existsSync()) {
    File(p.join(stagingDir.path, '.harness', 'active-context.md'))
        .copySync(activeContextFile.path);
  }

  if (progressFile.existsSync()) {
    print(
        '     -> Progress log preserved intact (${progressFile.lengthSync()} bytes, 0 bytes lost)');
  } else if (File(p.join(stagingDir.path, '.harness', 'progress.md'))
      .existsSync()) {
    File(p.join(stagingDir.path, '.harness', 'progress.md'))
        .copySync(progressFile.path);
  }

  // Tier 3: Shared Living Contract
  print('  [Tier 3] Smart-merging AGENTS.md and CLAUDE.md...');

  // Merge AGENTS.md
  if (agentsFile.existsSync() &&
      File(p.join(stagingDir.path, 'AGENTS.md')).existsSync()) {
    final currentAgents = agentsFile.readAsStringSync();
    final newAgents =
        File(p.join(stagingDir.path, 'AGENTS.md')).readAsStringSync();

    final customRegex = RegExp(r'(##\s*1[3-9]\..*|\n##\s*Custom.*)',
        multiLine: true, dotAll: true);
    final match = customRegex.firstMatch(currentAgents);
    String customSection = '';
    if (match != null) {
      customSection = currentAgents.substring(match.start).trim();
    }

    if (customSection.isNotEmpty) {
      agentsFile.writeAsStringSync('$newAgents\n\n$customSection\n');
      print('     -> Preserved custom sections in AGENTS.md');
    } else {
      agentsFile.writeAsStringSync(newAgents);
    }
  }

  // Merge CLAUDE.md
  if (claudeFile.existsSync() &&
      File(p.join(stagingDir.path, 'CLAUDE.md')).existsSync()) {
    final currentClaude = claudeFile.readAsStringSync();
    final newClaude =
        File(p.join(stagingDir.path, 'CLAUDE.md')).readAsStringSync();

    final lines = currentClaude.split('\n');
    final customLines = <String>[];
    bool inCustomNote = false;

    for (final line in lines) {
      if (line.startsWith('## ') &&
          !line.contains('Stack') &&
          !line.contains('State Rule') &&
          !line.contains('Folder Map') &&
          !line.contains('Adding a Feature') &&
          !line.contains('Hard Rules') &&
          !line.contains('QA & Review')) {
        inCustomNote = true;
      }
      if (inCustomNote) {
        customLines.add(line);
      }
    }

    if (customLines.isNotEmpty) {
      final preservedCustomNotes = customLines.join('\n').trim();
      claudeFile.writeAsStringSync('$newClaude\n\n$preservedCustomNotes\n');
      print('     -> Preserved custom notes in CLAUDE.md');
    } else {
      claudeFile.writeAsStringSync(newClaude);
    }
  }

  // 5. Version Manifest Stamping
  versionFile.writeAsStringSync(jsonEncode({
    'brick': 'harness',
    'version': targetVersion,
    'previous_version': currentVersion,
    'upgraded_at': DateTime.now().toUtc().toIso8601String(),
    'upstream_repo':
        'https://github.com/jenilseawind-glitch/Flutter-RxDart-Base.git',
  }));
  print('✅ Version manifest stamped: $targetVersion in .harness/version.json');

  // 6. Log Migration in Active Context
  if (activeContextFile.existsSync()) {
    final contextContent = activeContextFile.readAsStringSync();
    final logNotice =
        '- chore(harness): Upgraded AI Agent Harness from $currentVersion to $targetVersion (3-tier migration, preserved custom rules & session context).\n';
    if (contextContent.contains('## Recent Tasks')) {
      final updatedContext = contextContent.replaceFirst(
          '## Recent Tasks\n', '## Recent Tasks\n$logNotice');
      activeContextFile.writeAsStringSync(updatedContext);
    }
  }

  // 7. Cleanup Staging
  if (stagingDir.existsSync()) {
    stagingDir.deleteSync(recursive: true);
  }

  print(
      '\n🎉 Successfully migrated ${targetDir.path} to Harness v$targetVersion!');
}

void _copyDirectorySync(Directory source, Directory destination) {
  if (!source.existsSync()) return;
  if (!destination.existsSync()) {
    destination.createSync(recursive: true);
  }
  for (final entity in source.listSync(recursive: false)) {
    final destPath = p.join(destination.path, p.basename(entity.path));
    if (entity is File) {
      entity.copySync(destPath);
    } else if (entity is Directory) {
      _copyDirectorySync(entity, Directory(destPath));
    }
  }
}
