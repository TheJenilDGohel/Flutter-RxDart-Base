import 'package:analyzer/analysis_rule/rule_context.dart';

/// Path segments of the file being analysed, relative to the package's `lib/`
/// directory, e.g. `['features', 'auth', 'repo', 'auth_repo.dart']`.
///
/// Returns `null` for files outside `lib/` (tests, tool scripts).
///
/// Matching on the lib-relative path — never the absolute path — keeps the
/// rules independent of where the project is checked out (a CI workspace
/// named `/repo/` or a home folder named `utils/` must not change results).
List<String>? libSegments(RuleContext context) {
  final unit = context.currentUnit ?? context.definingUnit;
  final path = unit.file.path.replaceAll('\\', '/');
  final index = path.lastIndexOf('/lib/');
  if (index == -1) return null;
  return path.substring(index + '/lib/'.length).split('/');
}
