// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

/// Ingests API contract specifications (OpenAPI / Swagger JSON or Postman
/// Collection v2/v2.1 JSON) to prevent AI hallucination of response shapes,
/// endpoint paths, and model parsing bugs.
///
/// Usage:
///   `dart run scripts/agent/ingest_contract.dart [contract.json] [options]`
///
/// Options:
///   --list                     List all endpoints found in the specification
///   --scaffold [endpoint]      Generate model with defensive parsing & test fixture
///   --fixtures                 Extract all response examples into test/fixtures/
///   --help                     Show this help message
void main(List<String> args) {
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final filePath = args.first;
  final file = File(filePath);
  if (!file.existsSync()) {
    stderr.writeln('Error: Contract file "$filePath" not found.');
    exit(1);
  }

  final dynamic rootJson;
  try {
    rootJson = jsonDecode(file.readAsStringSync());
  } catch (e) {
    stderr.writeln('Error: Failed to parse JSON from "$filePath": $e');
    exit(1);
  }

  if (rootJson is! Map<String, dynamic>) {
    stderr.writeln('Error: Expected a JSON object at root of "$filePath".');
    exit(1);
  }

  final endpoints = _extractEndpoints(rootJson);
  if (endpoints.isEmpty) {
    print('No API endpoints found in "$filePath".');
    return;
  }

  final scaffoldIdx = args.indexOf('--scaffold');
  if (scaffoldIdx != -1 && scaffoldIdx + 1 < args.length) {
    final query = args[scaffoldIdx + 1].toLowerCase();
    final target = endpoints.firstWhere(
      (e) =>
          e.path.toLowerCase().contains(query) ||
          e.name.toLowerCase().contains(query),
      orElse: () => endpoints.first,
    );
    _scaffoldEndpoint(target);
    return;
  }

  if (args.contains('--fixtures')) {
    _exportFixtures(endpoints);
    return;
  }

  // Default behavior or --list:
  print('\n=== Endpoints discovered in ${file.path} (${endpoints.length}) ===\n');
  for (final ep in endpoints) {
    final hasSample = ep.sampleResponse != null ? ' [Has Sample]' : '';
    print('  [${ep.method.padRight(6)}] ${ep.path.padRight(40)} ${ep.name}$hasSample');
  }
  print('\nRun with --scaffold <endpoint> to generate a defensive Model & test fixture.');
}

void _printUsage() {
  print('''
API Contract Ingestion Tool (Flutter-RxDart-Base)
=================================================
Ingests OpenAPI / Swagger or Postman Collections to eliminate model parsing bugs.

Usage:
  dart run scripts/agent/ingest_contract.dart [path/to/spec.json] [flags]

Flags:
  --list                     List all endpoints in the contract (default)
  --scaffold <path_or_name>  Generate defensive model code and test fixture
  --fixtures                 Export all response examples to test/fixtures/
  --help, -h                 Display help information
''');
}

class _EndpointInfo {
  _EndpointInfo({
    required this.name,
    required this.method,
    required this.path,
    this.sampleResponse,
    this.queryParams = const [],
  });

  final String name;
  final String method;
  final String path;
  final dynamic sampleResponse;
  final List<String> queryParams;
}

List<_EndpointInfo> _extractEndpoints(Map<String, dynamic> root) {
  // 1. Postman Collection v2 / v2.1
  if (root.containsKey('info') && root.containsKey('item')) {
    final out = <_EndpointInfo>[];
    final items = root['item'];
    if (items is List) {
      _walkPostmanItems(items, out);
    }
    return out;
  }

  // 2. OpenAPI / Swagger (v2 or v3)
  final paths = root['paths'];
  if (paths is Map<String, dynamic>) {
    return _walkOpenApiPaths(paths);
  }

  return [];
}

void _walkPostmanItems(List<dynamic> items, List<_EndpointInfo> out) {
  for (final item in items) {
    if (item is! Map) continue;
    final childItems = item['item'];
    if (childItems is List) {
      _walkPostmanItems(childItems, out);
      continue;
    }
    final name = item['name']?.toString() ?? 'Unnamed';
    final request = item['request'];
    if (request is! Map) continue;

    final method = request['method']?.toString().toUpperCase() ?? 'GET';
    String path = '';
    final url = request['url'];
    final queryParams = <String>[];

    if (url is String) {
      path = url;
    } else if (url is Map) {
      final raw = url['raw']?.toString();
      final pathParts = url['path'];
      if (raw != null) {
        path = raw;
      } else if (pathParts is List) {
        path = pathParts.join('/');
      }
      final query = url['query'];
      if (query is List) {
        for (final q in query) {
          if (q is Map && q['key'] != null) {
            queryParams.add(q['key'].toString());
          }
        }
      }
    }

    dynamic sampleResponse;
    final responses = item['response'];
    if (responses is List) {
      for (final r in responses) {
        if (r is Map && r['body'] != null) {
          try {
            sampleResponse = jsonDecode(r['body'].toString());
            break;
          } catch (_) {}
        }
      }
    }

    out.add(_EndpointInfo(
      name: name,
      method: method,
      path: path,
      sampleResponse: sampleResponse,
      queryParams: queryParams,
    ));
  }
}

List<_EndpointInfo> _walkOpenApiPaths(Map<String, dynamic> paths) {
  final out = <_EndpointInfo>[];
  paths.forEach((pathKey, methodsObj) {
    final pathStr = pathKey;
    if (methodsObj is! Map) return;
    methodsObj.forEach((methodKey, opObj) {
      if (opObj is! Map) return;
      final method = methodKey.toString().toUpperCase();
      if (!const {'GET', 'POST', 'PUT', 'DELETE', 'PATCH'}.contains(method)) {
        return;
      }
      final name = opObj['summary']?.toString() ??
          opObj['operationId']?.toString() ??
          pathStr;

      dynamic sampleResponse;
      final responses = opObj['responses'];
      if (responses is Map) {
        final okResp = responses['200'] ?? responses['201'] ?? responses['default'];
        if (okResp is Map) {
          final content = okResp['content'];
          if (content is Map) {
            final appJson = content['application/json'];
            if (appJson is Map) {
              final example = appJson['example'];
              final examples = appJson['examples'];
              if (example != null) {
                sampleResponse = example;
              } else if (examples is Map && examples.isNotEmpty) {
                final firstVal = examples.values.first;
                if (firstVal is Map) {
                  sampleResponse = firstVal['value'];
                }
              }
            }
          }
        }
      }

      out.add(_EndpointInfo(
        name: name,
        method: method,
        path: pathStr,
        sampleResponse: sampleResponse,
      ));
    });
  });
  return out;
}

void _scaffoldEndpoint(_EndpointInfo ep) {
  final cleanName = ep.name
      .replaceAll(RegExp(r'[^a-zA-Z0-9]'), ' ')
      .trim()
      .split(' ')
      .where((s) => s.isNotEmpty)
      .map((s) => s[0].toUpperCase() + s.substring(1).toLowerCase())
      .join();
  final modelName = cleanName.isEmpty ? 'ApiModel' : '${cleanName}Model';
  final slug = cleanName.isEmpty
      ? 'api_model'
      : RegExp(r'[A-Z][a-z0-9]*')
          .allMatches(cleanName)
          .map((m) => m.group(0)!.toLowerCase())
          .join('_');

  print('\n=== Scaffolding for [${ep.method}] ${ep.path} ===\n');

  // 1. ApiConstants snippet
  final constName = '${slug.split('_').map((s) => s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1)).join()}Endpoint';
  final constCamel = constName[0].toLowerCase() + constName.substring(1);
  print('// 1. Add to lib/networking/api_constants.dart:');
  print("static const String $constCamel = '${ep.path}';\n");

  // 2. Test Fixture
  if (ep.sampleResponse != null) {
    final fixtureDir = Directory('test/fixtures');
    if (!fixtureDir.existsSync()) {
      fixtureDir.createSync(recursive: true);
    }
    final fixtureFile = File('test/fixtures/${slug}_response.json');
    fixtureFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(ep.sampleResponse),
    );
    print('// 2. Saved test fixture to ${fixtureFile.path}\n');
  }

  // 3. Model code with Golden Rule #12 defensive parsing
  print('// 3. Generated Model (Golden Rule #12 Defensive Parsing):');
  Map<String, dynamic> sample = <String, dynamic>{'id': 1, 'name': 'Sample'};
  final rawSample = ep.sampleResponse;
  if (rawSample is Map<String, dynamic>) {
    sample = rawSample;
  } else if (rawSample is Map) {
    sample = rawSample.cast<String, dynamic>();
  } else if (rawSample is List && rawSample.isNotEmpty) {
    final first = rawSample[0];
    if (first is Map<String, dynamic>) {
      sample = first;
    } else if (first is Map) {
      sample = first.cast<String, dynamic>();
    }
  }

  print(_generateModelCode(modelName, sample));
}

void _exportFixtures(List<_EndpointInfo> endpoints) {
  final dir = Directory('test/fixtures');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  var count = 0;
  for (final ep in endpoints) {
    if (ep.sampleResponse == null) continue;
    final slug = ep.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final name = slug.isEmpty ? 'endpoint_$count' : slug;
    final file = File('test/fixtures/${name}_response.json');
    file.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(ep.sampleResponse),
    );
    count++;
  }
  print('Exported $count fixture(s) to test/fixtures/.');
}

String _generateModelCode(String modelName, Map<String, dynamic> sample) {
  final fields = <String>[];
  final parserLines = <String>[];
  final mapLines = <String>[];

  sample.forEach((key, val) {
    final fieldName = _toCamelCase(key);
    final fieldType = _inferType(val);

    fields.add('  final $fieldType $fieldName;');

    if (fieldType == 'int') {
      parserLines.add("      $fieldName: (json['$key'] as num?)?.toInt() ?? 0,");
    } else if (fieldType == 'double') {
      parserLines.add("      $fieldName: (json['$key'] as num?)?.toDouble() ?? 0.0,");
    } else if (fieldType == 'bool') {
      parserLines.add("      $fieldName: json['$key'] == true || json['$key'] == 'true',");
    } else if (fieldType == 'DateTime?') {
      parserLines.add("      $fieldName: DateTime.tryParse(json['$key']?.toString() ?? ''),");
    } else if (fieldType == 'List<dynamic>') {
      parserLines.add("      $fieldName: (json['$key'] as List? ?? []).toList(),");
    } else {
      parserLines.add("      $fieldName: json['$key']?.toString() ?? '',");
    }

    if (fieldType == 'DateTime?') {
      mapLines.add("      '$key': $fieldName?.toIso8601String(),");
    } else {
      mapLines.add("      '$key': $fieldName,");
    }
  });

  return '''
class $modelName {
  const $modelName({
${fields.map((f) => '  required this.${f.trim().split(' ').last.replaceAll(';', '')},').join('\n')}
  });

${fields.join('\n')}

  factory $modelName.fromJson(Map<String, dynamic> json) {
    return $modelName(
${parserLines.join('\n')}
    );
  }

  Map<String, dynamic> toJson() => {
${mapLines.join('\n')}
  };
}
''';
}

String _toCamelCase(String key) {
  final parts = key.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').split('_');
  if (parts.isEmpty) return 'field';
  final first = parts.first.toLowerCase();
  final rest = parts
      .skip(1)
      .where((p) => p.isNotEmpty)
      .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
      .join();
  final res = '$first$rest';
  return _reservedWords.contains(res) ? '${res}Field' : res;
}

String _inferType(dynamic val) {
  if (val is int) return 'int';
  if (val is double) return 'double';
  if (val is bool) return 'bool';
  if (val is List) return 'List<dynamic>';
  if (val is String) {
    if (DateTime.tryParse(val) != null && val.contains('-') && val.length >= 10) {
      return 'DateTime?';
    }
    return 'String';
  }
  return 'String';
}

const _reservedWords = {
  'assert', 'break', 'case', 'catch', 'class', 'const', 'continue',
  'default', 'do', 'else', 'enum', 'extends', 'false', 'final', 'finally',
  'for', 'if', 'in', 'is', 'new', 'null', 'rethrow', 'return', 'super',
  'switch', 'this', 'throw', 'true', 'try', 'var', 'void', 'while', 'with',
};
