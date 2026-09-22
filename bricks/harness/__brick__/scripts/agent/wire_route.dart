import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print(
      'Usage: dart run scripts/agent/wire_route.dart <feature_name> [route_path]',
    );
    print('Example: dart run scripts/agent/wire_route.dart inquiries');
    print(
      'Example: dart run scripts/agent/wire_route.dart agent_profile /agent/profile',
    );
    print(
      'If the feature does not exist yet, it is scaffolded automatically via `mason make bloc`.',
    );
    exit(1);
  }

  final rawFeature = args[0].trim();
  final featureSnake = _toSnakeCase(rawFeature);
  final featureCamel = _toCamelCase(featureSnake);
  final featurePascal = _toPascalCase(featureSnake);

  final routePath = args.length > 1
      ? args[1].trim()
      : '/${featureSnake.replaceAll('_', '-')}';

  print('🚀 Wiring route for feature: $featureSnake');
  print('   Path: $routePath');

  final pubspecFile = _findPubspec();
  if (pubspecFile == null) {
    print('❌ Could not find pubspec.yaml. Please run from project root.');
    exit(1);
  }
  final projectName = _extractProjectName(pubspecFile);
  if (projectName == null || projectName.isEmpty) {
    print('❌ Could not detect project name from pubspec.yaml.');
    exit(1);
  }
  print('   Project: $projectName');

  // Check for incompatible router packages in brownfield codebases
  if (_hasIncompatibleRouter(pubspecFile)) {
    print(
      '❌ Incompatible router detected in pubspec.yaml (e.g. go_router, auto_route).',
    );
    print(
      '   wire_route.dart is designed for onGenerateRoute architectures (Redux-RxDart-Base standard).',
    );
    print(
      '   Please manually configure the route for $featureSnake in your declarative router.',
    );
    exit(1);
  }

  _ensureFeatureScaffolded(featureSnake);

  final routesFile = _findRoutesFile();
  if (routesFile == null) {
    print(
      '❌ Could not find routes.dart (expected at lib/utils/router/routes.dart).',
    );
    exit(1);
  }

  final routerFile = _findRouterFile(routePath);
  if (routerFile == null) {
    print(
      '❌ Could not find router file (expected at lib/utils/router/app_router.dart).',
    );
    exit(1);
  }

  final constantName = _deriveConstantName(routePath, featureCamel);
  _injectRouteConstant(routesFile, constantName, routePath);

  final pageClassName = _detectPageClassName(featureSnake, featurePascal);

  _injectRouteCase(
    routerFile: routerFile,
    projectName: projectName,
    featureSnake: featureSnake,
    pageClassName: pageClassName,
    constantName: constantName,
  );

  Process.runSync('dart', [
    'format',
    routesFile.path,
    routerFile.path,
  ], runInShell: true);

  print('✅ Successfully wired route:');
  print(
    '   - Constant: Routes.$constantName = \'$routePath\' in ${routesFile.path}',
  );
  print(
    '   - Handler:  Routes.$constantName -> $pageClassName in ${routerFile.path}',
  );
}

String _toSnakeCase(String str) {
  return str
      .replaceAllMapped(
        RegExp(r'[A-Z]'),
        (m) => '_${m.group(0)!.toLowerCase()}',
      )
      .replaceAll('-', '_')
      .replaceAll(RegExp(r'^_+'), '')
      .replaceAll(RegExp(r'_+'), '_');
}

String _toCamelCase(String snake) {
  final parts = snake.split('_').where((s) => s.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  final first = parts.first.toLowerCase();
  final rest = parts
      .skip(1)
      .map((s) => s[0].toUpperCase() + s.substring(1).toLowerCase())
      .join();
  return '$first$rest';
}

String _toPascalCase(String snake) {
  return snake
      .split('_')
      .where((s) => s.isNotEmpty)
      .map((s) => s[0].toUpperCase() + s.substring(1).toLowerCase())
      .join();
}

String _deriveConstantName(String routePath, String fallbackCamel) {
  final segments = routePath
      .split('/')
      .where((s) => s.isNotEmpty)
      .map((s) => s.replaceAll('-', '_'))
      .toList();
  if (segments.isEmpty) return 'root';
  if (segments.length == 1) return _toCamelCase(segments.first);
  return _toCamelCase(segments.join('_'));
}

File? _findPubspec() {
  var dir = Directory.current;
  for (var i = 0; i < 4; i++) {
    final file = File('${dir.path}${Platform.pathSeparator}pubspec.yaml');
    if (file.existsSync()) return file;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return null;
}

String? _extractProjectName(File pubspec) {
  try {
    final content = pubspec.readAsStringSync();
    final match = RegExp(
      r'^name:\s*([a-zA-Z0-9_]+)',
      multiLine: true,
    ).firstMatch(content);
    return match?.group(1);
  } catch (_) {
    return null;
  }
}

void _ensureFeatureScaffolded(String featureSnake) {
  final pageFile = File('lib/features/$featureSnake/${featureSnake}_page.dart');
  if (pageFile.existsSync()) return;

  print(
    '   ℹ️ Feature "$featureSnake" not found. Scaffolding via `mason make bloc`...',
  );
  final result = Process.runSync('mason', [
    'make',
    'bloc',
    '--feature_name',
    featureSnake,
    '-o',
    '.',
  ], runInShell: true);

  if (result.exitCode != 0 || !pageFile.existsSync()) {
    print('❌ `mason make bloc --feature_name $featureSnake` failed:');
    if ((result.stderr as String).trim().isNotEmpty) print(result.stderr);
    print(
      '   Please scaffold the feature manually, then re-run wire_route.dart.',
    );
    exit(1);
  }
  print('   ✔ Scaffolded feature: $featureSnake');
}

bool _hasIncompatibleRouter(File pubspec) {
  try {
    final content = pubspec.readAsStringSync();
    final hasGoRouter = RegExp(
      r'^\s*go_router\s*:',
      multiLine: true,
    ).hasMatch(content);
    final hasAutoRoute = RegExp(
      r'^\s*auto_route\s*:',
      multiLine: true,
    ).hasMatch(content);
    return hasGoRouter || hasAutoRoute;
  } catch (_) {
    return false;
  }
}

File? _findRoutesFile() {
  final direct = File('lib/utils/router/routes.dart');
  if (direct.existsSync()) return direct;

  final libDir = Directory('lib');
  if (!libDir.existsSync()) return null;

  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final name = entity.uri.pathSegments.last;
      if (name == 'routes.dart') return entity;
    }
  }
  return null;
}

File? _findRouterFile(String routePath) {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) return null;

  // 1. Check for delegated sub-routers matching route prefix (e.g. /agent/ -> agent_module_router.dart)
  final segments = routePath.split('/').where((s) => s.isNotEmpty).toList();
  if (segments.length > 1) {
    final prefix = segments.first.toLowerCase();
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final filename = entity.uri.pathSegments.last.toLowerCase();
        if (filename.contains(prefix) && filename.contains('router')) {
          return entity;
        }
      }
    }
  }

  // 2. Fall back to standard app_router.dart
  final appRouter = File('lib/utils/router/app_router.dart');
  if (appRouter.existsSync()) return appRouter;

  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final filename = entity.uri.pathSegments.last.toLowerCase();
      if (filename.contains('router') && !filename.contains('routes')) {
        final content = entity.readAsStringSync();
        if (content.contains('onGenerateRoute')) return entity;
      }
    }
  }
  return null;
}

String _detectPageClassName(String featureSnake, String fallbackPascal) {
  final pageFile = File('lib/features/$featureSnake/${featureSnake}_page.dart');
  if (pageFile.existsSync()) {
    try {
      final content = pageFile.readAsStringSync();
      final match = RegExp(
        r'class\s+([A-Za-z0-9_]+Page)\s+extends\s+State',
      ).firstMatch(content);
      if (match != null) return match.group(1)!;
    } catch (_) {}
  }
  return '${fallbackPascal}Page';
}

void _injectRouteConstant(
  File routesFile,
  String constantName,
  String routePath,
) {
  final content = routesFile.readAsStringSync();
  if (RegExp('\\b$constantName\\s*=').hasMatch(content)) {
    print(
      '   ℹ️ Route constant Routes.$constantName already exists in ${routesFile.path}',
    );
    return;
  }

  final lastBraceIndex = content.lastIndexOf('}');
  if (lastBraceIndex == -1) {
    print('❌ Could not parse closing brace in ${routesFile.path}');
    exit(1);
  }

  final updated =
      content.substring(0, lastBraceIndex) +
      '  static const String $constantName = \'$routePath\';\n' +
      content.substring(lastBraceIndex);

  routesFile.writeAsStringSync(updated);
  print('   ✔ Added route constant Routes.$constantName');
}

void _injectRouteCase({
  required File routerFile,
  required String projectName,
  required String featureSnake,
  required String pageClassName,
  required String constantName,
}) {
  var content = routerFile.readAsStringSync();

  // 1. Add import
  final importStatement =
      "import 'package:$projectName/features/$featureSnake/${featureSnake}_page.dart';";
  if (!content.contains(importStatement)) {
    final lastImportMatch = RegExp(
      r'''^import\s+['"][^'"]+['"];''',
      multiLine: true,
    ).allMatches(content).lastOrNull;

    if (lastImportMatch != null) {
      final insertPos = lastImportMatch.end;
      content =
          content.substring(0, insertPos) +
          '\n$importStatement' +
          content.substring(insertPos);
    } else {
      content = '$importStatement\n$content';
    }
  }

  // 2. Add route case in onGenerateRoute
  if (RegExp('\\bcase\\s+Routes\\.$constantName\\s*:').hasMatch(content)) {
    print(
      '   ℹ️ Route case Routes.$constantName already present in ${routerFile.path}',
    );
    routerFile.writeAsStringSync(content);
    return;
  }

  final hasBuildHelper = content.contains('_build(');
  final caseCode = hasBuildHelper
      ? '      case Routes.$constantName:\n        return _build(settings, (_) => const $pageClassName());\n\n'
      : '      case Routes.$constantName:\n        return MaterialPageRoute(settings: settings, builder: (_) => const $pageClassName());\n\n';

  bool injected = false;
  final defaultMatch = RegExp(
    r'^\s*default\s*:',
    multiLine: true,
  ).firstMatch(content);
  if (defaultMatch != null) {
    final insertPos = defaultMatch.start;
    content =
        content.substring(0, insertPos) +
        caseCode +
        content.substring(insertPos);
    injected = true;
  } else {
    // If no default: found, find the closing brace of switch (settings.name)
    final switchMatch = RegExp(
      r'switch\s*\([^\)]*settings\.name[^\)]*\)\s*\{',
    ).firstMatch(content);
    if (switchMatch != null) {
      final switchStart = switchMatch.end;
      final switchClose = content.indexOf('}', switchStart);
      if (switchClose != -1) {
        content =
            content.substring(0, switchClose) +
            caseCode +
            content.substring(switchClose);
        injected = true;
      }
    }
  }

  if (!injected) {
    print(
      '❌ Could not locate a valid `switch (settings.name)` or `default:` in ${routerFile.path}.',
    );
    print('   Please manually wire the route handler:');
    print('   case Routes.$constantName:');
    print(
      '     return MaterialPageRoute(settings: settings, builder: (_) => const $pageClassName());',
    );
    exit(1);
  }

  routerFile.writeAsStringSync(content);
  print('   ✔ Injected switch case for Routes.$constantName');
}
