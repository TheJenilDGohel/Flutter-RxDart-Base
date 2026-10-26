import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// flutter_screenutil (5.9.x) does not rebuild widgets whose type name starts
/// with `_` when the window size changes (and its `SU` mixin does not fix it).
/// A private widget using `.w/.h/.r/.sp` therefore keeps stale sizes after
/// rotation, split-screen or tablet resize. Make the widget public instead.
class NoScreenutilInPrivateWidget extends AnalysisRule {
  NoScreenutilInPrivateWidget()
    : super(
        name: 'no_screenutil_in_private_widget',
        description: 'ScreenUtil sizes are used only in public widgets.',
      );

  static const LintCode code = LintCode(
    'no_screenutil_in_private_widget',
    'ScreenUtil size extensions (.w .h .r .sp ...) in a private widget '
        'are not rebuilt on resize. Make the widget public (no leading _).',
    severity: DiagnosticSeverity.ERROR,
  );

  static const _extensions = <String>{
    'w',
    'h',
    'r',
    'sp',
    'sw',
    'sh',
    'dg',
    'dm',
    'spMin',
    'spMax',
  };

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _ClassVisitor(this));
  }
}

class _ClassVisitor extends SimpleAstVisitor<void> {
  _ClassVisitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (_isPrivateWidget(node)) node.accept(_Finder(rule));
  }

  /// A private widget class (any Widget subtype: StatelessWidget,
  /// StatefulWidget, ConsumerWidget, HookWidget, ...) or the State of a
  /// private StatefulWidget. Resolved through the type hierarchy, not by
  /// the name of the direct superclass.
  bool _isPrivateWidget(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) return false;
    final private = element.name?.startsWith('_') ?? false;
    for (final type in element.allSupertypes) {
      final name = type.element.name;
      if (name == 'Widget' && private) return true;
      if (name == 'State' && type.typeArguments.isNotEmpty) {
        final widget = type.typeArguments.first.element?.name;
        if (widget != null && widget.startsWith('_')) return true;
      }
    }
    return false;
  }
}

class _Finder extends RecursiveAstVisitor<void> {
  _Finder(this.rule);

  final AnalysisRule rule;

  /// True when [id] resolves to an extension member declared in
  /// flutter_screenutil — a user extension also named `.w` is ignored.
  bool _isScreenUtil(SimpleIdentifier id) {
    if (!NoScreenutilInPrivateWidget._extensions.contains(id.name)) {
      return false;
    }
    final uri = id.element?.library?.uri.toString() ?? '';
    return uri.startsWith('package:flutter_screenutil/');
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (_isScreenUtil(node.propertyName)) rule.reportAtNode(node);
    super.visitPropertyAccess(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (_isScreenUtil(node.identifier)) rule.reportAtNode(node);
    super.visitPrefixedIdentifier(node);
  }
}
