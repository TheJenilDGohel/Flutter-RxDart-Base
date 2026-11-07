import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../lib_path.dart';

/// Golden Rule #8 (AGENTS.md): fetch() must call createNewToken() first.
/// This guarantees a newer fetch cancels the older in-flight request.
class NoFetchWithoutToken extends AnalysisRule {
  NoFetchWithoutToken()
    : super(
        name: 'no_fetch_without_token',
        description:
            'BLoC fetch() must call createNewToken() to cancel in-flight requests.',
      );

  static const LintCode code = LintCode(
    'no_fetch_without_token',
    'fetch() must call createNewToken() first so overlapping requests are cleanly cancelled (AGENTS.md Golden Rule #8).',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodDeclaration(this, _MethodVisitor(this, context));
  }
}

class _MethodVisitor extends SimpleAstVisitor<void> {
  _MethodVisitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme != 'fetch') return;
    final parent = node.parent;
    final className = switch (parent) {
      ClassDeclaration d => d.declaredFragment?.element.name ?? '',
      ClassBody b => switch (b.parent) {
        ClassDeclaration d => d.declaredFragment?.element.name ?? '',
        _ => '',
      },
      _ => '',
    };
    if (className.isEmpty) return;

    final segments = libSegments(context);
    if (segments == null) return;
    final isBloc =
        segments.contains('bloc') ||
        segments.last.endsWith('_bloc.dart') ||
        className.endsWith('Bloc');
    if (!isBloc) return;

    // fetch() may delegate (`fetch() => _load(tab)` -> `_run(...)` ->
    // `_tokens.createNewToken(tab)` with keyed tokens): follow calls into
    // methods of the same class, a few levels deep.
    final members = <String, MethodDeclaration>{
      for (final m in _classMembers(parent)) m.name.lexeme: m,
    };
    final finder = _TokenCallFinder(members)..visited.add('fetch');
    node.body.accept(finder);

    if (!finder.hasCreateNewToken) {
      rule.reportAtNode(node);
    }
  }

  Iterable<MethodDeclaration> _classMembers(AstNode? parent) {
    final body = switch (parent) {
      ClassBody b => b,
      ClassDeclaration d => d.body,
      _ => null,
    };
    if (body is! BlockClassBody) return const [];
    return body.members.whereType<MethodDeclaration>();
  }
}

class _TokenCallFinder extends RecursiveAstVisitor<void> {
  _TokenCallFinder(this.members);

  /// Methods of the BLoC, by name.
  final Map<String, MethodDeclaration> members;

  /// Methods already followed (no cycles).
  final Set<String> visited = {};

  static const _maxDepth = 4;
  int _depth = 0;

  bool hasCreateNewToken = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (hasCreateNewToken) return;
    final name = node.methodName.name;
    // `createNewToken()` (CancelTokenOwner) or
    // `_tokens.createNewToken(key)` (KeyedCancelTokens).
    if (name == 'createNewToken') {
      hasCreateNewToken = true;
      return;
    }
    final target = node.target;
    final own = target == null || target is ThisExpression;
    final callee = members[name];
    if (own && callee != null && _depth < _maxDepth && visited.add(name)) {
      _depth++;
      callee.body.accept(this);
      _depth--;
    }
    super.visitMethodInvocation(node);
  }
}
