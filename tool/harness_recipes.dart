import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const _recipes =
    'bricks/harness/__brick__/.agents/skills/manage-state/bloc-recipes.md';
const _fixture = 'tool/recipe_fixture';

/// l10n keys the recipes use, added to both ARB files of the app.
const _strings = {
  'signInTitle': 'Sign in',
  'signIn': 'Sign in',
  'invalidEmail': 'Enter a valid email address.',
  'ordersEmpty': 'No orders yet.',
  'cartAdded': 'Added to cart.',
  'cartRemoved': 'Removed from cart.',
};

/// Copies `tool/recipe_fixture/` into the generated app at [appDir] with
/// the code blocks of the harness's BLoC recipes pasted in **verbatim**, so
/// the smoke test's analyze (including the lint plugin) and test steps prove
/// the skill's code still compiles, follows the golden rules and behaves as
/// documented.
///
/// A `// recipe-block: N` line or a `recipe('N')` expression in a fixture is
/// replaced by block N (0-based, in document order). Where one block mixes
/// two kinds of code, `Na` / `Nb` name its parts.
void pasteRecipes(String appDir, String package) {
  final doc = File(_recipes).readAsStringSync().replaceAll('\r\n', '\n');
  final blocks = RegExp(r'```dart\n(.*?)```', dotAll: true)
      .allMatches(doc)
      .map(
          (m) => m.group(1)!.replaceAll('package:my_app/', 'package:$package/'))
      .toList();
  if (blocks.length != 14) {
    throw StateError('$_recipes has ${blocks.length} dart blocks; '
        'tool/recipe_fixture expects 14. Update the fixture markers.');
  }

  final pieces = <String, String>{
    for (var i = 0; i < blocks.length; i++) '$i': blocks[i],
  };
  // Recipe C's page block: State members, then the `body:` expression.
  final page = blocks[5].split('  // body:\n');
  pieces['5a'] = page.first;
  pieces['5b'] = page.last.trim();
  // Recipe D's BLoC block: a top-level enum, then BLoC members.
  final events = blocks[7].indexOf('\n\n');
  pieces['7a'] = blocks[7].substring(0, events + 1);
  pieces['7b'] = blocks[7].substring(events + 2);
  // Recipe D's page block ends with a prose comment about dispose().
  pieces['8'] = blocks[8]
      .replaceAll(RegExp(r'^\s*// dispose\(\).*\n', multiLine: true), '');
  // Recipe G's StreamBuilder elides its builder body.
  pieces['12'] = blocks[12]
      .trim()
      .replaceFirst('=> ...,', r"=> Text('${snapshot.data}'),");

  String piece(String id) =>
      pieces[id] ?? (throw StateError('No recipe block "$id"'));

  final fixture = Directory(_fixture);
  for (final file in fixture.listSync(recursive: true).whereType<File>()) {
    final rel = p.relative(file.path, from: fixture.path);
    if (!rel.endsWith('.dart')) continue;
    final source = file
        .readAsStringSync()
        .replaceAll('\r\n', '\n')
        .replaceAll('package:recipe_app/', 'package:$package/')
        .replaceAllMapped(
          RegExp(r'^[ \t]*// recipe-block: (\w+)\n', multiLine: true),
          (m) => '${piece(m.group(1)!).trimRight()}\n',
        )
        .replaceAllMapped(
          RegExp(r"recipe\('(\w+)'\)"),
          (m) => piece(m.group(1)!).trimRight(),
        );
    File(p.join(appDir, rel))
      ..createSync(recursive: true)
      ..writeAsStringSync(source);
  }

  for (final arb in ['app_en.arb', 'app_hi.arb']) {
    final file = File(p.join(appDir, 'lib', 'l10n', arb));
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    json.addAll(_strings);
    file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(json));
  }
}
