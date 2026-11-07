import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../lib_path.dart';

/// Golden Rule #1 (AGENTS.md): Repository is Transport ONLY.
/// Repository files MUST ONLY call `ApiBaseHelper` and return raw
/// `Map<String, dynamic>`. NEVER parse models in a Repository.
///
/// A repository file is any file under a `repo/` or `repository/` directory
/// in `lib/`, or named `*_repo.dart` / `*_repository.dart`.
/// Flags calls *and* tear-offs of `fromJson` / `fromMap`.
class RepoTransportOnly extends AnalysisRule {
  RepoTransportOnly()
    : super(
        name: 'repo_transport_only',
        description: 'Repositories return raw maps; BLoCs parse models.',
      );

  static const LintCode code = LintCode(
    'repo_transport_only',
    'Repository must not parse models. Call .fromJson() in the BLoC, '
        'not in repo/ files (AGENTS.md Golden Rule #1).',
    severity: DiagnosticSeverity.ERROR,
  );

  static const _parsers = {'fromJson', 'fromMap'};

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, context);
    // `Model.fromJson(x)` resolves to an InstanceCreationExpression for a
    // factory/named constructor, or a MethodInvocation for a static method.
    registry
      ..addMethodInvocation(this, visitor)
      ..addInstanceCreationExpression(this, visitor)
      ..addConstructorReference(this, visitor)
      ..addPrefixedIdentifier(this, visitor);
  }

  static bool isRepoFile(List<String> segments) {
    final file = segments.last;
    return segments.contains('repo') ||
        segments.contains('repository') ||
        file.endsWith('_repo.dart') ||
        file.endsWith('_repository.dart');
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  void _check(String? name, AstNode node) {
    if (!RepoTransportOnly._parsers.contains(name)) return;
    final segments = libSegments(context);
    if (segments == null || !RepoTransportOnly.isRepoFile(segments)) return;
    rule.reportAtNode(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) =>
      _check(node.methodName.name, node);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) =>
      _check(node.constructorName.name?.name, node);

  /// Tear-offs: `.map(Model.fromJson)`.
  @override
  void visitConstructorReference(ConstructorReference node) =>
      _check(node.constructorName.name?.name, node);

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.parent is MethodInvocation) return;
    _check(node.identifier.name, node);
  }
}
