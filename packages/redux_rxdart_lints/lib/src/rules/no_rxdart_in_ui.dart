import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../lib_path.dart';

/// Golden Rule #4 (AGENTS.md): Zero RxDart Outside BLoC.
/// UI widgets must never import RxDart (`BehaviorSubject`, `PublishSubject`).
/// UI widgets only consume standard `Stream<T>` / `ApiResponse<T>`.
///
/// RxDart is allowed in:
/// - any `bloc/` directory or `*_bloc.dart` file (including the nested
///   `utils/widgets/view/<component>/bloc/` BLoCs),
/// - `redux/`, `networking/` and `services/`,
/// - `utils/` helpers, except `utils/widgets/` (which is UI).
class NoRxdartInUi extends AnalysisRule {
  NoRxdartInUi()
    : super(
        name: 'no_rxdart_in_ui',
        description: 'Only BLoCs and non-UI layers import RxDart.',
      );

  static const LintCode code = LintCode(
    'no_rxdart_in_ui',
    'RxDart must not be imported outside bloc/ files. UI widgets consume '
        'Stream<T> / ApiResponse<T> only (AGENTS.md Golden Rule #4).',
    severity: DiagnosticSeverity.ERROR,
  );

  static const _nonUiRoots = {'redux', 'networking', 'services'};

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, context);
    registry
      ..addImportDirective(this, visitor)
      ..addExportDirective(this, visitor);
  }

  /// Visible for the rule's own reasoning; [segments] is lib-relative.
  static bool isAllowed(List<String> segments) {
    if (segments.last.endsWith('_bloc.dart')) return true;
    if (segments.contains('bloc')) return true;
    final root = segments.first;
    if (_nonUiRoots.contains(root)) return true;
    if (root == 'utils') {
      return segments.length < 2 || segments[1] != 'widgets';
    }
    return false;
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  void _check(NamespaceDirective node) {
    final uri = node.uri.stringValue ?? '';
    if (!uri.startsWith('package:rxdart/')) return;
    final segments = libSegments(context);
    if (segments == null || NoRxdartInUi.isAllowed(segments)) return;
    rule.reportAtNode(node);
  }

  @override
  void visitImportDirective(ImportDirective node) => _check(node);

  @override
  void visitExportDirective(ExportDirective node) => _check(node);
}
