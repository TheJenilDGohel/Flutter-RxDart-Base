import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../lib_path.dart';

/// Golden Rule #2 (AGENTS.md): Never display `e.toString()`.
/// Widgets must show errors with `error.userFacingMessage(context)`
/// (or let `AppResponseBuilder` do it).
class NoExceptionToString extends AnalysisRule {
  NoExceptionToString()
    : super(
        name: 'no_exception_tostring',
        description: 'UI shows errors with userFacingMessage, never toString.',
      );

  static const LintCode code = LintCode(
    'no_exception_tostring',
    'Never display e.toString() in UI. Use error.userFacingMessage(context) '
        'or AppResponseBuilder (AGENTS.md Golden Rule #2).',
    severity: DiagnosticSeverity.ERROR,
  );

  static const _errorNames = {'e', 'err', 'error', 'exception'};

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodInvocation(this, _Visitor(this, context));
  }

  /// UI code: anything in `lib/` except networking, redux, services, BLoCs
  /// and repos.
  static bool isUiCode(List<String> segments) {
    if (segments.isEmpty) return false;
    final root = segments.first;
    if (root == 'networking' || root == 'redux' || root == 'services') {
      return false;
    }
    if (segments.contains('bloc')) return false;
    if (segments.last.endsWith('_bloc.dart')) return false;
    if (segments.last.endsWith('_repo.dart')) return false;
    return true;
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'toString') return;
    final target = node.target;
    if (target is! SimpleIdentifier) return;
    final name = target.name.toLowerCase();
    if (!NoExceptionToString._errorNames.contains(name)) return;
    final segments = libSegments(context);
    if (segments == null || !NoExceptionToString.isUiCode(segments)) return;
    rule.reportAtNode(node);
  }
}
