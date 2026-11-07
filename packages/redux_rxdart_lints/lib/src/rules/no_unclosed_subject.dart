import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../lib_path.dart';

/// Flags RxDart subjects in a BLoC that are not closed in dispose().
class NoUnclosedSubject extends AnalysisRule {
  NoUnclosedSubject()
    : super(
        name: 'no_unclosed_subject',
        description: 'RxDart subjects in BLoCs must be closed in dispose().',
      );

  static const LintCode code = LintCode(
    'no_unclosed_subject',
    'RxDart subject is not closed in dispose(). Call close() to prevent memory leaks.',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _ClassVisitor(this, context));
  }
}

class _ClassVisitor extends SimpleAstVisitor<void> {
  _ClassVisitor(this.rule, this.context);

  final AnalysisRule rule;
  final RuleContext context;

  static const _subjectTypes = {
    'BehaviorSubject',
    'PublishSubject',
    'ReplaySubject',
  };

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final segments = libSegments(context);
    if (segments == null) return;
    final className = node.declaredFragment?.element.name ?? '';
    final isBloc =
        segments.contains('bloc') ||
        segments.last.endsWith('_bloc.dart') ||
        className.endsWith('Bloc');
    if (!isBloc) return;

    final fields = node.body.childEntities.whereType<FieldDeclaration>();
    final subjectFields = <VariableDeclaration>[];
    for (final member in fields) {
      if (!member.isStatic) {
        for (final variable in member.fields.variables) {
          final typeName = member.fields.type?.toSource() ?? '';
          final initSource = variable.initializer?.toSource() ?? '';
          final isSubject = _subjectTypes.any(
            (t) => typeName.contains(t) || initSource.contains(t),
          );
          if (isSubject) {
            subjectFields.add(variable);
          }
        }
      }
    }
    if (subjectFields.isEmpty) return;

    final methods = node.body.childEntities.whereType<MethodDeclaration>();
    MethodDeclaration? disposeMethod;
    for (final member in methods) {
      if (member.name.lexeme == 'dispose') {
        disposeMethod = member;
        break;
      }
    }

    final closedFieldNames = <String>{};
    if (disposeMethod != null) {
      final body = disposeMethod.body;
      body.accept(_CloseCallFinder(closedFieldNames));
    }

    for (final field in subjectFields) {
      final name = field.name.lexeme;
      if (!closedFieldNames.contains(name)) {
        rule.reportAtNode(field);
      }
    }
  }
}

class _CloseCallFinder extends RecursiveAstVisitor<void> {
  _CloseCallFinder(this.closedFields);
  final Set<String> closedFields;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'close') {
      final target = node.target;
      if (target is SimpleIdentifier) {
        closedFields.add(target.name);
      }
    }
    super.visitMethodInvocation(node);
  }
}
