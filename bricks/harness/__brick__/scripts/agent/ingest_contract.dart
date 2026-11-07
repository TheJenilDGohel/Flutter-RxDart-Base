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
    bool exact(_EndpointInfo e) =>
        e.path.toLowerCase() == query || e.name.toLowerCase() == query;
    bool partial(_EndpointInfo e) =>
        e.path.toLowerCase().contains(query) ||
        e.name.toLowerCase().contains(query);
    final exactHits = endpoints.where(exact).toList();
    final hits = exactHits.isNotEmpty
        ? exactHits
        : endpoints.where(partial).toList();
    if (hits.length != 1) {
      stderr.writeln(
        hits.isEmpty
            ? 'No endpoint matches "$query". Endpoints:'
            : '"$query" matches ${hits.length} endpoints; use the full path:',
      );
      for (final e in hits.isEmpty ? endpoints : hits) {
        stderr.writeln('  [${e.method}] ${e.path}  ${e.name}');
      }
      exit(1);
    }
    _scaffoldEndpoint(hits.single);
    return;
  }

  if (args.contains('--fixtures')) {
    _exportFixtures(endpoints);
    return;
  }

  // Default behavior or --list:
  print(
    '\n=== Endpoints discovered in ${file.path} (${endpoints.length}) ===\n',
  );
  for (final ep in endpoints) {
    final hasSample = ep.sampleResponse != null ? ' [Has Sample]' : '';
    print(
      '  [${ep.method.padRight(6)}] ${ep.path.padRight(40)} ${ep.name}$hasSample',
    );
  }
  print(
    '\nRun with --scaffold <endpoint> to generate a defensive Model & test fixture.',
  );
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

    out.add(
      _EndpointInfo(
        name: name,
        method: method,
        path: path,
        sampleResponse: sampleResponse,
        queryParams: queryParams,
      ),
    );
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
      final name =
          opObj['summary']?.toString() ??
          opObj['operationId']?.toString() ??
          pathStr;

      dynamic sampleResponse;
      final responses = opObj['responses'];
      if (responses is Map) {
        final okResp =
            responses['200'] ?? responses['201'] ?? responses['default'];
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

      out.add(
        _EndpointInfo(
          name: name,
          method: method,
          path: pathStr,
          sampleResponse: sampleResponse,
        ),
      );
    });
  });
  return out;
}

void _scaffoldEndpoint(_EndpointInfo ep) {
  final words = ep.name
      .replaceAll(RegExp(r'[^a-zA-Z0-9]'), ' ')
      .trim()
      .split(' ')
      .where((s) => s.isNotEmpty)
      .toList();
  // "Get order" -> Order: the verb names the call, not the data.
  if (words.length > 1 && _verbs.contains(words.first.toLowerCase())) {
    words.removeAt(0);
  }
  final cleanName = words
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

  // 1. ApiConstants entry, in the base's style: a getter on baseUrl, or a
  //    function when the path has parameters ({id} in OpenAPI, :id in Postman).
  final constName = _camel('${slug}_endpoint');
  final params = <String>[];
  final path = ep.path
      .replaceAll(RegExp(r'^\{\{[^}]*\}\}'), '')
      .replaceAllMapped(RegExp(r'\{(\w+)\}|:(\w+)'), (m) {
        final p = _camel(m.group(1) ?? m.group(2)!);
        params.add(p);
        return '\$$p';
      });
  print('// 1. Add to lib/networking/api_constants.dart:');
  print(
    params.isEmpty
        ? "static String get $constName => '\$baseUrl$path';\n"
        : 'static String $constName(${params.map((p) => 'String $p').join(', ')}) =>'
              "\n    '\$baseUrl$path';\n",
  );

  final rawSample = ep.sampleResponse;
  if (rawSample == null) {
    print(
      '// 2. No example response for this endpoint in the contract, so no '
      'model\n//    was generated: ask for one real response (AGENTS.md §3). '
      'Never infer\n//    fields from the endpoint name.',
    );
    exitCode = 2;
    return;
  }

  // 2. Test fixture: the real example, for the BLoC and model tests.
  final fixtureDir = Directory('test/fixtures');
  if (!fixtureDir.existsSync()) fixtureDir.createSync(recursive: true);
  final fixtureFile = File('test/fixtures/${slug}_response.json');
  fixtureFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(rawSample),
  );
  print('// 2. Saved test fixture to ${fixtureFile.path}\n');

  // 3. Model(s) with Golden Rule #12 defensive parsing.
  Map<String, dynamic>? sample;
  var isList = false;
  if (rawSample is Map) {
    sample = rawSample.cast<String, dynamic>();
  } else if (rawSample is List) {
    isList = true;
    final first = rawSample.isEmpty ? null : rawSample.first;
    if (first is Map) sample = first.cast<String, dynamic>();
  }
  if (sample == null) {
    print(
      '// 3. The example is ${isList ? 'an empty list or a list of values' : 'not a JSON object'}; '
      'no model generated. Ask for an example with items.',
    );
    exitCode = 2;
    return;
  }
  print(
    '// 3. Generated model (Golden Rule #12 defensive parsing; run '
    '`dart format` after pasting):',
  );
  if (isList) {
    print(
      '//    The response is a JSON array: ApiBaseHelper returns it as '
      "{'items': [...]}.\n//    Parse with (json['items'] as List? ?? const [])"
      '.whereType<Map<String, dynamic>>().map($modelName.fromJson).toList()',
    );
  }
  print(_generateModelCode(modelName, sample));
}

const _verbs = {
  'get',
  'fetch',
  'list',
  'create',
  'add',
  'update',
  'edit',
  'delete',
  'remove',
  'post',
  'put',
  'patch',
  'retrieve',
  'search',
  'find',
};

String _camel(String snake) {
  final parts = snake
      .split(RegExp(r'[^a-zA-Z0-9]+'))
      .where((p) => p.isNotEmpty);
  if (parts.isEmpty) return 'value';
  return parts.first.toLowerCase() +
      parts
          .skip(1)
          .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
          .join();
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

/// The model for [sample], followed by one class per nested object, typed
/// from the example: nested objects become their own models, lists are typed
/// by their first item, and a field that is null in the example stays
/// `Object?` instead of a guessed type.
String _generateModelCode(String modelName, Map<String, dynamic> sample) {
  final classes = <String>[];
  _modelClass(modelName, sample, classes);
  return classes.join('\n');
}

void _modelClass(String name, Map<String, dynamic> sample, List<String> out) {
  final fields = <String>[];
  final parse = <String>[];
  final toJson = <String>[];
  final nested = <MapEntry<String, Map<String, dynamic>>>[];
  final stem = name.replaceAll(RegExp(r'Model$'), '');

  sample.forEach((key, val) {
    final f = _toCamelCase(key);
    final j = "json['$key']";
    var toJsonExpr = f;
    final String type;
    final String parser;
    if (val is Map) {
      final child = '$stem${_pascal(key)}Model';
      nested.add(MapEntry(child, val.cast<String, dynamic>()));
      type = child;
      // A bare `as Map?` throws on a wrong type; the switch falls back.
      parser =
          '$child.fromJson(switch ($j) { final Map<Object?, Object?> v => v.cast<String, dynamic>(), '
          '_ => const <String, dynamic>{} })';
      toJsonExpr = '$f.toJson()';
    } else if (val is List) {
      final first = val.isEmpty ? null : val.first;
      final list =
          '(switch ($j) { final List<Object?> v => v, _ => const <Object?>[] })';
      if (first is Map) {
        final child = '$stem${_pascal(_singular(key))}Model';
        nested.add(MapEntry(child, first.cast<String, dynamic>()));
        type = 'List<$child>';
        parser =
            '$list.whereType<Map<String, dynamic>>().map($child.fromJson).toList()';
        toJsonExpr = '$f.map((e) => e.toJson()).toList()';
      } else if (first is String) {
        type = 'List<String>';
        parser = '$list.whereType<Object>().map((e) => e.toString()).toList()';
      } else if (first is int) {
        type = 'List<int>';
        parser = '$list.whereType<num>().map((e) => e.toInt()).toList()';
      } else if (first is double) {
        type = 'List<double>';
        parser = '$list.whereType<num>().map((e) => e.toDouble()).toList()';
      } else if (first is bool) {
        type = 'List<bool>';
        parser = '$list.whereType<bool>().toList()';
      } else {
        // Empty in the example: type it once a real response shows items.
        type = 'List<Object?>';
        parser = '$list.toList()';
      }
    } else if (val == null) {
      // Null in the example: the type is unknown, so don't guess one.
      type = 'Object?';
      parser = j;
    } else {
      switch (_inferType(val)) {
        case 'int':
          type = 'int';
          parser =
              'switch ($j) { final num v => v.toInt(), '
              'final String v => num.tryParse(v)?.toInt() ?? 0, _ => 0 }';
        case 'double':
          type = 'double';
          parser =
              'switch ($j) { final num v => v.toDouble(), '
              'final String v => double.tryParse(v) ?? 0.0, _ => 0.0 }';
        case 'bool':
          type = 'bool';
          parser = "$j == true || $j == 'true'";
        case 'DateTime?':
          type = 'DateTime?';
          parser = "DateTime.tryParse($j?.toString() ?? '')";
          toJsonExpr = '$f?.toIso8601String()';
        default:
          type = 'String';
          parser = "$j?.toString() ?? ''";
      }
    }
    fields.add('  final $type $f;');
    parse.add('      $f: $parser,');
    toJson.add("        '$key': $toJsonExpr,");
  });

  final ctorArgs = fields
      .map(
        (f) =>
            '    required this.${f.trim().split(' ').last.replaceAll(';', '')},',
      )
      .join('\n');
  out.add('''
class $name {
  const $name({
$ctorArgs
  });

${fields.join('\n')}

  factory $name.fromJson(Map<String, dynamic> json) {
    return $name(
${parse.join('\n')}
    );
  }

  Map<String, dynamic> toJson() => {
${toJson.join('\n')}
      };
}
''');
  for (final child in nested) {
    _modelClass(child.key, child.value, out);
  }
}

String _pascal(String key) {
  final c = _toCamelCase(key);
  return c.isEmpty ? 'Item' : c[0].toUpperCase() + c.substring(1);
}

/// `lines` -> `line`, `categories` -> `category`; good enough for class names.
String _singular(String key) {
  if (key.endsWith('ies') && key.length > 4) {
    return '${key.substring(0, key.length - 3)}y';
  }
  if (key.endsWith('s') && !key.endsWith('ss') && key.length > 3) {
    return key.substring(0, key.length - 1);
  }
  return '${key}_item';
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
    if (DateTime.tryParse(val) != null &&
        val.contains('-') &&
        val.length >= 10) {
      return 'DateTime?';
    }
    return 'String';
  }
  return 'String';
}

const _reservedWords = {
  'assert',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'default',
  'do',
  'else',
  'enum',
  'extends',
  'false',
  'final',
  'finally',
  'for',
  'if',
  'in',
  'is',
  'new',
  'null',
  'rethrow',
  'return',
  'super',
  'switch',
  'this',
  'throw',
  'true',
  'try',
  'var',
  'void',
  'while',
  'with',
};
