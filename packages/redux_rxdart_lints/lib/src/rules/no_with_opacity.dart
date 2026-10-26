import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../lib_path.dart';

/// Avoids `.withOpacity()` in UI widgets.
///
/// In modern Flutter, `.withOpacity()` creates performance overhead and
/// precision issues. Use `Color.withValues(alpha: ...)` or design system
/// tokens instead.
class NoWithOpacity extends AnalysisRule {
  NoWithOpacity()
    : super(
        name: 'no_with_opacity',
        description:
            'Use Color.withValues(alpha: ...) or color tokens instead of withOpacity.',
      );

  static const LintCode code = LintCode(
    'no_with_opacity',
    'Avoid withOpacity(); use Color.withValues(alpha: ...) or themed color tokens for better performance (AGENTS.md).',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodInvocation(this, _Visitor(this, context));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'withOpacity') return;
    final segments = libSegments(context);
    if (segments == null) return;
    rule.reportAtNode(node);
  }
}
