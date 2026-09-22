import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart' show ErrorReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Golden Rule #1 (AGENTS.md): Repository is Transport ONLY.
/// Repository files MUST ONLY call `ApiBaseHelper` and return raw
/// `Map<String, dynamic>`. NEVER call `Model.fromJson` in Repository.
class RepoTransportOnly extends DartLintRule {
  RepoTransportOnly() : super(code: _code);

  static const _code = LintCode(
    name: 'repo_transport_only',
    problemMessage:
        'Repository must not parse models. Call .fromJson() in the BLoC, '
        'not in repo/ files (AGENTS.md Golden Rule #1).',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = resolver.source.fullName.replaceAll('\\', '/');
    if (!path.contains('/repo/')) return;

    context.registry.addMethodInvocation((node) {
      if (node.methodName.name == 'fromJson') {
        reporter.atNode(node, _code);
      }
    });
  }
}
