import 'dart:io';
import 'package:path/path.dart' as p;

void main() async {
  print('======================================================');
  print('🧪 R&D EXPERIMENT: Harness Brick Upgradation & Migration');
  print('======================================================\n');

  final rootDir = Directory.current.path;
  final testDir = Directory(p.join(rootDir, 'temp_upgrade_test'));

  if (testDir.existsSync()) {
    testDir.deleteSync(recursive: true);
  }
  testDir.createSync(recursive: true);

  try {
    // 1. Setup mock existing app
    print('📦 Step 1: Initializing mock app with Harness v1.4.2...');
    File(p.join(testDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: demo_app
description: A demo app testing harness upgrades.
version: 1.0.0
environment:
  sdk: '>=3.0.0 <4.0.0'
''');

    // Scaffold harness into temp app
    final initRes = await Process.run(
      'mason',
      [
        'make',
        'harness',
        '--project_name',
        'demo_app',
        '--android_package_name',
        'com.example.demoapp',
        '--ios_bundle_id',
        'com.example.demoapp',
        '--on-conflict',
        'overwrite',
        '-o',
        testDir.path,
      ],
      runInShell: true,
    );

    if (initRes.exitCode != 0) {
      print('❌ Failed to scaffold initial harness: ${initRes.stderr}');
      exit(1);
    }
    print('✅ Initial harness scaffolded successfully.');

    // 2. Simulate User Project Usage & Customizations
    print('\n👤 Step 2: Simulating active developer usage & customizations...');
    final activeContextFile =
        File(p.join(testDir.path, '.harness', 'active-context.md'));
    const userSessionContext = '''# Active Context

<!-- Updated by AI agents after each task. Max 5 entries in Recent Tasks. -->

## Current Focus
Migrating payment processing to Stripe PaymentSheet.

## Recent Tasks
- [x] Integrated Stripe SDK dependency (commit: a1b2c3d)
- [x] Scaffolded payment_bloc with CancelTokenOwner (commit: e4f5g6h)
- [x] Configured webhook listener for charge.succeeded (commit: j7k8l9m)

## Key Decisions
- Use Stripe PaymentIntents API instead of legacy Charges API.
- Wrap all checkout actions in async AppDialog.showAsyncConfirm.

## Known Issues
- Sandbox 3DS verification takes 4s on Android emulator.
''';
    activeContextFile.writeAsStringSync(userSessionContext);

    final agentsFile = File(p.join(testDir.path, 'AGENTS.md'));
    final initialAgentsContent = agentsFile.readAsStringSync();
    const userCustomRules = '''

## 13. Project-Specific Tenant Constraints
- All outgoing Dio requests must inject `X-Tenant-ID` header.
- Never log customer credit card or PII tokens to console.
- Production environment must verify SSL fingerprint before handshake.
''';
    agentsFile.writeAsStringSync(initialAgentsContent + userCustomRules);
    print(
        '✅ Added active session context (Stripe tasks) and custom team rules (Section 13).');

    // 3. Empirically Demonstrate Failure of Naive Mason Overwrite
    print(
        '\n⚠️ Step 3: Testing Case A — What happens with naive `mason make harness --on-conflict overwrite`?');
    // Save backup to test both
    final savedContext = activeContextFile.readAsStringSync();
    final savedAgents = agentsFile.readAsStringSync();

    final naiveRes = await Process.run(
      'mason',
      [
        'make',
        'harness',
        '--project_name',
        'demo_app',
        '--android_package_name',
        'com.example.demoapp',
        '--ios_bundle_id',
        'com.example.demoapp',
        '--on-conflict',
        'overwrite',
        '-o',
        testDir.path,
      ],
      runInShell: true,
    );
    if (naiveRes.exitCode != 0) {
      print('naiveRes stderr: ${naiveRes.stderr}');
    }

    final overwrittenContext = activeContextFile.readAsStringSync();
    final overwrittenAgents = agentsFile.readAsStringSync();

    final bool contextWiped =
        overwrittenContext.contains('_None yet - first agent session._');
    final bool customRulesWiped =
        !overwrittenAgents.contains('13. Project-Specific Tenant Constraints');

    if (contextWiped && customRulesWiped) {
      print('💥 CONFIRMED: Naive overwrite DESTROYS user data:');
      print(
          '   ❌ .harness/active-context.md was wiped back to default empty template!');
      print('   ❌ AGENTS.md custom team rules (Section 13) were erased!');
    } else {
      print(
          '❓ Unexpected result in naive overwrite test. contextWiped=$contextWiped, customRulesWiped=$customRulesWiped');
    }

    // Restore user files for Case B
    activeContextFile.writeAsStringSync(savedContext);
    agentsFile.writeAsStringSync(savedAgents);

    // 4. Test Case B: The 3-Tier Migration Engine
    print('\n🛡️ Step 4: Testing Case B — The 3-Tier Migration Engine...');

    // Simulate Upstream New Release (v1.5.0) in staging buffer
    print('📦 Upstream released v1.5.0 with:');
    print('   - New feature in scripts/agent/wire_route.dart (Tier 1)');
    print('   - New performance rule in .agents/skills/ (Tier 1)');
    print('   - Updated Golden Rule #1 in AGENTS.md (Tier 3)');
    print('   - Empty active-context.md template in upstream (Tier 2)');

    // Create a mock upstream staging directory simulating new brick files
    final stagingDir = Directory(p.join(testDir.path, '.staging_upgrade_v150'));
    stagingDir.createSync(recursive: true);

    // Render new upstream version to staging
    final stagingRes = await Process.run(
      'mason',
      [
        'make',
        'harness',
        '--project_name',
        'demo_app',
        '--android_package_name',
        'com.example.demoapp',
        '--ios_bundle_id',
        'com.example.demoapp',
        '--on-conflict',
        'overwrite',
        '-o',
        stagingDir.path,
      ],
      runInShell: true,
    );
    if (stagingRes.exitCode != 0) {
      print('stagingRes stderr: ${stagingRes.stderr}');
      exit(1);
    }

    // Inject simulated upstream enhancements into staging
    final stagedWireRoute =
        File(p.join(stagingDir.path, 'scripts', 'agent', 'wire_route.dart'));
    stagedWireRoute.writeAsStringSync(
        '// [UPGRADE v1.5.0] Enhanced router support with nested routes\n${stagedWireRoute.readAsStringSync()}');

    final stagedSkillArch = File(p.join(stagingDir.path, '.agents', 'skills',
        'flutter-senior-dev', 'architecture.md'));
    stagedSkillArch.writeAsStringSync(
        '${stagedSkillArch.readAsStringSync()}\n<!-- [UPGRADE v1.5.0] New Image Caching Directive -->\n');

    final stagedAgents = File(p.join(stagingDir.path, 'AGENTS.md'));
    var stagedAgentsContent = stagedAgents.readAsStringSync();
    stagedAgentsContent = stagedAgentsContent.replaceFirst(
      '# AI Agent Contract & Architecture Standards',
      '# AI Agent Contract & Architecture Standards (v1.5.0-upgraded)',
    );
    stagedAgents.writeAsStringSync(stagedAgentsContent);

    // Run Migration Engine
    final migrationReport = runThreeTierMigration(
      projectDir: testDir,
      stagingDir: stagingDir,
      fromVersion: '1.4.2',
      toVersion: '1.5.0',
    );

    print('\n📊 Migration Report:');
    print(migrationReport);

    // 5. Assertions & Proof
    print('\n🔍 Step 5: Verifying Assertions...');

    // Assertion 1: Tier 1 Overwrite
    final updatedWireRoute =
        File(p.join(testDir.path, 'scripts', 'agent', 'wire_route.dart'))
            .readAsStringSync();
    final updatedSkill = File(p.join(testDir.path, '.agents', 'skills',
            'flutter-senior-dev', 'architecture.md'))
        .readAsStringSync();
    final bool tier1Success =
        updatedWireRoute.contains('// [UPGRADE v1.5.0]') &&
            updatedSkill.contains('Image Caching Directive');
    print(
        'Assertion 1 (Tier 1 Engine & Tools Upgraded): ${tier1Success ? '✅ PASSED' : '❌ FAILED'}');

    // Assertion 2: Tier 2 Protection (Zero Data Loss in Active Context)
    final preservedContext =
        File(p.join(testDir.path, '.harness', 'active-context.md'))
            .readAsStringSync();
    final bool tier2Success = preservedContext
            .contains('Migrating payment processing to Stripe PaymentSheet.') &&
        preservedContext.contains('Stripe PaymentIntents API') &&
        !preservedContext.contains('_None yet - first agent session._');
    print(
        'Assertion 2 (Tier 2 User Session Memory 100% Preserved): ${tier2Success ? '✅ PASSED' : '❌ FAILED'}');

    // Assertion 3: Tier 3 Smart Merge (Upstream updates merged + Local rules retained)
    final mergedAgents =
        File(p.join(testDir.path, 'AGENTS.md')).readAsStringSync();
    final bool tier3Success = mergedAgents.contains('(v1.5.0-upgraded)') &&
        mergedAgents.contains('13. Project-Specific Tenant Constraints') &&
        mergedAgents.contains('X-Tenant-ID');
    print(
        'Assertion 3 (Tier 3 Shared Contract Merged Intelligently): ${tier3Success ? '✅ PASSED' : '❌ FAILED'}');

    // Assertion 4: Manifest & Version Tracking
    final versionFile = File(p.join(testDir.path, '.harness', 'version.json'));
    final bool versionSuccess = versionFile.existsSync() &&
        versionFile.readAsStringSync().contains('"version": "1.5.0"');
    print(
        'Assertion 4 (Version Manifest Updated to 1.5.0): ${versionSuccess ? '✅ PASSED' : '❌ FAILED'}');

    // Clean up staging
    stagingDir.deleteSync(recursive: true);

    if (tier1Success && tier2Success && tier3Success && versionSuccess) {
      print(
          '\n🎉 CONCLUSION: The 3-Tier Migration Theory is 100% EMPIRICALLY VERIFIED!');
      print(
          'The upgrade succeeded with ZERO context loss and FULL upstream capability gain.');
    } else {
      print('\n❌ One or more assertions failed.');
      exit(1);
    }
  } finally {
    // Cleanup testDir
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
  }
}

/// The 3-Tier Migration Engine
String runThreeTierMigration({
  required Directory projectDir,
  required Directory stagingDir,
  required String fromVersion,
  required String toVersion,
}) {
  final log = StringBuffer();

  // Tier 1: Overwrite Core Engine & Tooling
  log.writeln('  [Tier 1] Overwriting core CLI tooling (scripts/agent/)...');
  _copyDirectorySync(
    Directory(p.join(stagingDir.path, 'scripts', 'agent')),
    Directory(p.join(projectDir.path, 'scripts', 'agent')),
  );

  log.writeln('  [Tier 1] Overwriting senior-dev skills (.agents/skills/)...');
  _copyDirectorySync(
    Directory(p.join(stagingDir.path, '.agents', 'skills')),
    Directory(p.join(projectDir.path, '.agents', 'skills')),
  );

  log.writeln('  [Tier 1] Overwriting QA reviewer agent (.agents/agents/)...');
  _copyDirectorySync(
    Directory(p.join(stagingDir.path, '.agents', 'agents')),
    Directory(p.join(projectDir.path, '.agents', 'agents')),
  );

  // Tier 2: Protected User State
  log.writeln(
      '  [Tier 2] Preserving .harness/active-context.md and progress.md (SKIPPED overwrite).');
  // (We deliberately do not copy .harness/ from stagingDir to projectDir)

  // Tier 3: Shared Contract Merge (AGENTS.md)
  log.writeln(
      '  [Tier 3] Performing intelligent section-merge on AGENTS.md...');
  final targetAgents = File(p.join(projectDir.path, 'AGENTS.md'));
  final stagedAgents = File(p.join(stagingDir.path, 'AGENTS.md'));

  final currentContent = targetAgents.readAsStringSync();
  final newTemplateContent = stagedAgents.readAsStringSync();

  // Extract user-custom sections (sections >= 13 or marked custom)
  final customSectionRegex = RegExp(r'(##\s*1[3-9]\..*|\n##\s*Custom.*)',
      multiLine: true, dotAll: true);
  final customMatch = customSectionRegex.firstMatch(currentContent);
  String customContent = '';
  if (customMatch != null) {
    customContent = currentContent.substring(customMatch.start).trim();
  }

  // Merge: take new upstream template and append preserved custom sections
  final mergedContent = '$newTemplateContent\n\n$customContent\n';
  targetAgents.writeAsStringSync(mergedContent);

  // Update .harness/version.json
  final versionFile = File(p.join(projectDir.path, '.harness', 'version.json'));
  versionFile.writeAsStringSync('''{
  "brick": "harness",
  "version": "$toVersion",
  "previous_version": "$fromVersion",
  "upgraded_at": "${DateTime.now().toUtc().toIso8601String()}"
}''');

  log.writeln(
      '  [Manifest] Updated .harness/version.json to version $toVersion.');

  return log.toString();
}

void _copyDirectorySync(Directory source, Directory destination) {
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
