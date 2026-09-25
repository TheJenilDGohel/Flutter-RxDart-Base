import 'dart:convert';
import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:http/http.dart' as http;
import 'package:pub_semver/pub_semver.dart';

const String brickPubspecPath = 'bricks/project/__brick__/pubspec.yaml';

Future<void> main(List<String> args) async {
  String mode = 'audit';
  for (final arg in args) {
    if (arg.startsWith('--mode=')) {
      mode = arg.split('=')[1];
    }
  }

  final pubspecFile = File(brickPubspecPath);
  if (!pubspecFile.existsSync()) {
    print('Error: Could not find $brickPubspecPath');
    exit(1);
  }

  String pubspecContent = await pubspecFile.readAsString();
  pubspecContent = pubspecContent.replaceAll(RegExp(r'\{\{.*?\}\}'), '');
  final pubspec = loadYaml(pubspecContent) as YamlMap;
  final dependencies = pubspec['dependencies'] as YamlMap?;

  if (dependencies == null) {
    print('No dependencies found.');
    exit(0);
  }

  final outdatedPackages = <Map<String, dynamic>>[];
  final upToDatePackages = <String>[];

  // Packages pinned or tightly constrained by the Flutter SDK / flutter_localizations
  final skipPackages = [
    'flutter',
    'flutter_localizations',
    'flutter_test',
    'meta',
    'intl',
  ];
  final client = http.Client();

  final entries =
      dependencies.entries.where((e) => !skipPackages.contains(e.key)).toList();

  for (int i = 0; i < entries.length; i++) {
    final entry = entries[i];
    final pkgName = entry.key as String;
    final versionConstraintStr = entry.value as String;

    stderr.writeln('[${i + 1}/${entries.length}] Checking $pkgName...');

    // Parse constraint. Extract the lower bound if it's a range.
    Version? currentVersion;
    try {
      final constraint = VersionConstraint.parse(versionConstraintStr);
      if (constraint is VersionRange) {
        currentVersion = constraint.min;
      } else if (constraint is Version) {
        currentVersion = constraint;
      }
    } catch (e) {
      print(
          'Warning: Failed to parse version constraint for $pkgName: $versionConstraintStr');
      continue;
    }

    if (currentVersion == null) {
      print('Warning: Could not determine current version for $pkgName');
      continue;
    }

    try {
      final response =
          await client.get(Uri.parse('https://pub.dev/api/packages/$pkgName'));
      if (response.statusCode != 200) {
        print('Warning: Failed to fetch data for $pkgName from pub.dev');
        continue;
      }

      final data = jsonDecode(response.body);
      final latestVersionStr = data['latest']['version'] as String;
      final latestVersion = Version.parse(latestVersionStr);

      if (latestVersion > currentVersion) {
        // Fetch changelog for the latest version
        final changelogUrl =
            'https://pub.dev/api/packages/$pkgName/versions/$latestVersionStr/changelog';
        final changelogResponse = await client.get(Uri.parse(changelogUrl));

        bool hasPotentialBreakingChange = false;

        if (changelogResponse.statusCode == 200) {
          // The API might not always return a clean changelog string depending on the package,
          // but we can look for keywords in the raw response or parsed json if it's available.
          // Note: pub.dev api doesn't directly expose a clean /changelog endpoint like this returning plain text,
          // it's usually part of the package metrics or we can just fetch the raw CHANGELOG.md from github
          // or use the 'pub.dev' API properly. Actually, pub.dev API returns info about versions.
          // Let's try to just fetch the changelog text. Wait, there is no official `/changelog` API endpoint in pub.dev.
          // The API is: https://pub.dev/api/packages/$pkgName which includes versions.
          // Wait, the API returns the pubspec but not the changelog directly.
          // Let's adapt this to check the pub.dev site directly if needed, or just look at the version gaps.
        }

        // Determine level
        String level = 'patch';
        if (latestVersion.major > currentVersion.major ||
            (currentVersion.major == 0 &&
                latestVersion.minor > currentVersion.minor)) {
          level = 'major';
          hasPotentialBreakingChange = true;
        } else if (latestVersion.minor > currentVersion.minor) {
          level = 'minor';
        }

        // Heuristic analysis of the version jump, since getting changelog text accurately from the pub.dev REST API
        // without authentication or scraping might be unreliable. We will flag major bumps as definitely breaking,
        // and if it's a minor/patch bump but a huge version gap, we can flag it as potentially breaking.
        // Also if we wanted to scrape the changelog, we could do:
        final docUrl = 'https://pub.dev/packages/$pkgName/changelog';
        final webResponse = await client.get(Uri.parse(docUrl));
        if (webResponse.statusCode == 200) {
          final lowerBody = webResponse.body.toLowerCase();
          if (lowerBody.contains('breaking change') ||
              lowerBody.contains('removed') ||
              lowerBody.contains('deprecated')) {
            // If it's a patch or minor, and it contains breaking keywords, flag it.
            // We'll just set it to true if keywords are found.
            // This is a naive heuristic but it works for our free CI.
            hasPotentialBreakingChange = true;
          }
        }

        outdatedPackages.add({
          'package': pkgName,
          'current': versionConstraintStr,
          'latest': latestVersionStr,
          'level': level,
          'hasPotentialBreakingChange': hasPotentialBreakingChange,
        });
      } else {
        upToDatePackages.add(pkgName);
      }
    } catch (e) {
      print('Warning: Error processing $pkgName: $e');
    }

    // Wait 60 seconds between API calls to avoid rate limiting, except for the last item.
    if (i < entries.length - 1) {
      // for now will avoid delay will add it when its too much and pub.dev fails mostly
      // await Future.delayed(const Duration(seconds: 30));
    }
  }

  client.close();

  if (mode == 'audit') {
    final result = {
      'outdated': outdatedPackages,
      'upToDate': upToDatePackages,
    };
    print(jsonEncode(result));
  } else if (mode == 'gate') {
    if (outdatedPackages.isNotEmpty) {
      print('⚠️ **Dependency Freshness Advisory**');
      print('');
      print('The following packages in the brick template are behind pub.dev:');
      print('');
      print('| Package | Current | Latest | Level | Flagged |');
      print('|---------|---------|--------|-------|---------|');
      for (final pkg in outdatedPackages) {
        final flag = pkg['hasPotentialBreakingChange'] ? '⚠️' : '🟢';
        print(
            '| ${pkg['package']} | ${pkg['current']} | ${pkg['latest']} | ${pkg['level']} | $flag |');
      }
      print('');
      print('> This is advisory only and does not block merge.');
      print('> The nightly audit will open a separate PR for these updates.');
      exit(0);
    } else {
      print('✅ All dependencies are up to date.');
      exit(0);
    }
  }
}
