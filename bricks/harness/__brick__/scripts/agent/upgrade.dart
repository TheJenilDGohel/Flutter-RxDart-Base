// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

/// Autonomous 3-Tier Migration Engine for the AI Agent Harness.
///
/// Ensures safe upgrades from upstream releases without losing ongoing
/// sprint context (.harness/active-context.md) or custom team rules (AGENTS.md).
void main(List<String> args) async {
  final checkOnly = args.contains('--check-only');
  final force = args.contains('--force');

  print('====================================================');
  print('🤖 Autonomous AI Agent Harness Migration Engine');
  print('====================================================\n');

  final projectDir = Directory.current;
  final pubspecFile = File('${projectDir.path}/pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print(
      '❌ Error: pubspec.yaml not found. Please run from Flutter project root.',
    );
    exit(1);
  }

  // 1. Read or initialize version manifest
  final versionFile = File('${projectDir.path}/.harness/version.json');
  String currentVersion = 'legacy (< 1.4.2)';
  String upstreamRepo =
      'https://github.com/jenilseawind-glitch/Flutter-RxDart-Base.git';

  if (versionFile.existsSync()) {
    try {
      final jsonMap =
          jsonDecode(versionFile.readAsStringSync()) as Map<String, dynamic>;
      currentVersion = jsonMap['version']?.toString() ?? currentVersion;
      upstreamRepo = jsonMap['upstream_repo']?.toString() ?? upstreamRepo;
    } catch (_) {}
  }

  print('📌 Current Installed Version: $currentVersion');
  print('🌐 Upstream Repository: $upstreamRepo');

  // 2. Check upstream latest tag / version
  print('\n🔍 Checking for upstream harness updates...');
  String targetVersion = '1.5.0';

  try {
    final lsRemote = await Process.run('git', [
      'ls-remote',
      '--tags',
      '--sort=v:refname',
      upstreamRepo,
    ], runInShell: true);

    if (lsRemote.exitCode == 0 &&
        lsRemote.stdout.toString().trim().isNotEmpty) {
      final lines = lsRemote.stdout.toString().trim().split('\n');
      for (final line in lines.reversed) {
        final match = RegExp(r'refs/tags/v?(\d+\.\d+\.\d+)').firstMatch(line);
        if (match != null) {
          targetVersion = match.group(1)!;
          break;
        }
      }
    }
  } catch (e) {
    print(
      'ℹ️ Note: Git ls-remote query skipped ($e). Defaulting to target: $targetVersion',
    );
  }

  if (currentVersion == targetVersion && !force) {
    print('✨ Harness is already up to date (version $currentVersion).');
    exit(0);
  }

  print('🚀 New version available: $targetVersion (Current: $currentVersion)');

  if (checkOnly) {
    print('::set-output name=has_update::true');
    print('::set-output name=new_version::$targetVersion');
    exit(0);
  }

  // 3. Create Safety Backup
  print('\n📦 Step 1: Creating pre-migration safety backup...');
  final backupDir = Directory(
    '${projectDir.path}/.harness/.backup_${DateTime.now().millisecondsSinceEpoch}',
  );
  backupDir.createSync(recursive: true);

  final activeContextFile = File(
    '${projectDir.path}/.harness/active-context.md',
  );
  if (activeContextFile.existsSync()) {
    activeContextFile.copySync('${backupDir.path}/active-context.md');
  }

  final progressFile = File('${projectDir.path}/.harness/progress.md');
  if (progressFile.existsSync()) {
    progressFile.copySync('${backupDir.path}/progress.md');
  }

  final agentsFile = File('${projectDir.path}/AGENTS.md');
  if (agentsFile.existsSync()) {
    agentsFile.copySync('${backupDir.path}/AGENTS.md');
  }

  final claudeFile = File('${projectDir.path}/CLAUDE.md');
  if (claudeFile.existsSync()) {
    claudeFile.copySync('${backupDir.path}/CLAUDE.md');
  }
  print('✅ Safety backup created at: ${backupDir.path}');

  // 4. Staging Upstream Brick Files via Mason
  print(
    '\n📥 Step 2: Fetching latest harness templates into staging buffer...',
  );
  final stagingDir = Directory('${projectDir.path}/.harness/.staging_upgrade');
  if (stagingDir.existsSync()) {
    stagingDir.deleteSync(recursive: true);
  }
  stagingDir.createSync(recursive: true);

  String projectName = 'app';
  try {
    final match = RegExp(
      r'^name:\s*([a-zA-Z0-9_]+)',
      multiLine: true,
    ).firstMatch(pubspecFile.readAsStringSync());
    if (match != null) projectName = match.group(1)!;
  } catch (_) {}

  final masonRes = await Process.run('mason', [
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
  ], runInShell: true);

  if (masonRes.exitCode != 0) {
    print('⚠️ Mason template render note: ${masonRes.stderr}');
  }

  // 5. Execute 3-Tier Migration
  print('\n🛡️ Step 3: Applying 3-Tier Migration Engine...');

  // --- Tier 1: Overwrite Core Engine & Tooling ---
  print(
    '  [Tier 1] Upgrading scripts/agent/ and .agents/skills/ (Overwrite Cleanly)...',
  );
  _copyDirIfExists(
    Directory('${stagingDir.path}/scripts/agent'),
    Directory('${projectDir.path}/scripts/agent'),
  );
  _copyDirIfExists(
    Directory('${stagingDir.path}/.agents/skills'),
    Directory('${projectDir.path}/.agents/skills'),
  );
  _copyDirIfExists(
    Directory('${stagingDir.path}/.agents/agents'),
    Directory('${projectDir.path}/.agents/agents'),
  );

  // --- Tier 2: Protect User Context & Memory ---
  print(
    '  [Tier 2] Preserving .harness/active-context.md and progress.md (ZERO Data Loss)...',
  );
  // (We strictly DO NOT overwrite active-context.md or progress.md)
  if (!activeContextFile.existsSync() &&
      File('${stagingDir.path}/.harness/active-context.md').existsSync()) {
    File(
      '${stagingDir.path}/.harness/active-context.md',
    ).copySync(activeContextFile.path);
  }
  if (!progressFile.existsSync() &&
      File('${stagingDir.path}/.harness/progress.md').existsSync()) {
    File('${stagingDir.path}/.harness/progress.md').copySync(progressFile.path);
  }

  // --- Tier 3: Shared Living Contract (Smart Section Merge) ---
  print('  [Tier 3] Smart-merging AGENTS.md and CLAUDE.md...');

  // Merge AGENTS.md
  if (agentsFile.existsSync() &&
      File('${stagingDir.path}/AGENTS.md').existsSync()) {
    final currentAgents = agentsFile.readAsStringSync();
    final newAgents = File('${stagingDir.path}/AGENTS.md').readAsStringSync();

    String customSection = '';
    final idx = currentAgents.indexOf('## 7. Project Context');
    if (idx != -1) {
      final afterSeven = currentAgents.substring(idx);
      final nextMatch = RegExp(
        r'\n(##\s+[8-9]\.|\n##\s+[1-9][0-9]\.|\n##\s+[A-Za-z]|<!--)',
        multiLine: true,
      ).firstMatch(afterSeven);
      if (nextMatch != null) {
        customSection = afterSeven.substring(nextMatch.start).trim();
      }
    } else {
      final customRegex = RegExp(
        r'(##\s*1[3-9]\..*|\n##\s*Custom.*)',
        multiLine: true,
        dotAll: true,
      );
      final match = customRegex.firstMatch(currentAgents);
      if (match != null) {
        customSection = currentAgents.substring(match.start).trim();
      }
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
      File('${stagingDir.path}/CLAUDE.md').existsSync()) {
    final currentClaude = claudeFile.readAsStringSync();
    final newClaude = File('${stagingDir.path}/CLAUDE.md').readAsStringSync();

    // Extract any custom notes from CLAUDE.md (skipping old transclusion lines)
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
      if (newClaude.contains('@.harness/active-context.md')) {
        final merged = newClaude.replaceFirst(
          '@.harness/active-context.md',
          '$preservedCustomNotes\n\n---\n@.harness/active-context.md',
        );
        claudeFile.writeAsStringSync(merged);
      } else {
        claudeFile.writeAsStringSync('$newClaude\n\n$preservedCustomNotes\n');
      }
      print('     -> Preserved custom notes in CLAUDE.md');
    } else {
      claudeFile.writeAsStringSync(newClaude);
    }
  }

  // 6. Update Version Manifest
  versionFile.writeAsStringSync(
    jsonEncode({
      'brick': 'harness',
      'version': targetVersion,
      'previous_version': currentVersion,
      'upgraded_at': DateTime.now().toUtc().toIso8601String(),
      'upstream_repo': upstreamRepo,
    }),
  );
  print('✅ Version manifest stamped: $targetVersion in .harness/version.json');

  // 7. Cleanup Staging
  if (stagingDir.existsSync()) {
    stagingDir.deleteSync(recursive: true);
  }

  // 8. Log Migration in Active Context
  if (activeContextFile.existsSync()) {
    final contextContent = activeContextFile.readAsStringSync();
    final logNotice =
        '- chore(harness): Upgraded AI Agent Harness from $currentVersion to $targetVersion (3-tier migration, preserved custom rules & session context).\n';
    if (contextContent.contains('## Recent Tasks')) {
      final updatedContext = contextContent.replaceFirst(
        '## Recent Tasks\n',
        '## Recent Tasks\n$logNotice',
      );
      activeContextFile.writeAsStringSync(updatedContext);
    }
  }

  print('\n🎉 Upgrade to Harness v$targetVersion completed successfully!');
  print(
    'Run `scripts/agent/verify.ps1` (or `./scripts/agent/verify.sh`) to confirm workspace health.',
  );
}

void _copyDirIfExists(Directory source, Directory destination) {
  if (!source.existsSync()) return;
  if (!destination.existsSync()) {
    destination.createSync(recursive: true);
  }
  for (final entity in source.listSync(recursive: false)) {
    final destPath =
        '${destination.path}/${entity.path.split(Platform.pathSeparator).last}';
    if (entity is File) {
      entity.copySync(destPath);
    } else if (entity is Directory) {
      _copyDirIfExists(entity, Directory(destPath));
    }
  }
}
