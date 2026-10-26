import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../lib_path.dart';

/// Golden Rule #3 (AGENTS.md): Zero `setState`.
/// Drive UI from BLoC streams (`AppResponseBuilder`, `StreamBuilder`).
///
/// Only Flutter's `State.setState` is flagged (resolved, not by name), so
/// unrelated methods called `setState` are fine. The low-level design-system
/// primitives in `lib/utils/widgets/ui/` are exempt: they may hold purely
/// visual state (focus, obscured text) that never touches business logic.
class NoSetStateInWidget extends AnalysisRule {
  NoSetStateInWidget()
    : super(
        name: 'no_setstate_in_widget',
        description: 'Feature widgets follow BLoC streams, not setState.',
      );

  static const LintCode code = LintCode(
    'no_setstate_in_widget',
    'setState is forbidden. Drive UI from BLoC streams via '
        'AppResponseBuilder / StreamBuilder (AGENTS.md Golden Rule #3).',
    severity: DiagnosticSeverity.ERROR,
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

  /// Design-system primitives in `lib/utils/widgets/ui/`.
  static bool isExempt(List<String>? segments) =>
      segments != null &&
      segments.length > 2 &&
      segments[0] == 'utils' &&
      segments[1] == 'widgets' &&
      segments[2] == 'ui';
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'setState') return;
    final element = node.methodName.element;
    final owner = element?.enclosingElement;
    final fromFlutter =
        element?.library?.uri.toString().startsWith('package:flutter/') ??
        false;
    if (owner?.name != 'State' || !fromFlutter) return;
    if (NoSetStateInWidget.isExempt(libSegments(context))) return;
    rule.reportAtNode(node);
  }
}
