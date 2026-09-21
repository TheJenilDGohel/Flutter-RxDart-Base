import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart' show ErrorReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Golden Rule #3 (AGENTS.md): Zero `setState`.
/// Strictly forbidden in all widgets. Use stream builders
/// (`ApiResponseBuilder`, `StreamBuilder`) instead.
class NoSetStateInWidget extends DartLintRule {
  NoSetStateInWidget() : super(code: _code);

  static const _code = LintCode(
    name: 'no_setstate_in_widget',
    problemMessage: 'setState is forbidden. Drive UI from BLoC streams via '
        'ApiResponseBuilder / StreamBuilder (AGENTS.md Golden Rule #3).',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name == 'setState') {
        final normalizedPath = resolver.path.replaceAll('\\', '/');
        if (normalizedPath.contains('lib/utils/widgets/ui/')) {
          return;
        }
        reporter.atNode(node, _code);
      }
    });
  }
}
