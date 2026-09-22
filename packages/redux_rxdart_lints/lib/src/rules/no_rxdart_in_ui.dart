import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart' show ErrorReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Golden Rule #4 (AGENTS.md): Zero RxDart Outside BLoC.
/// UI widgets must never import RxDart (`BehaviorSubject`, `PublishSubject`).
/// UI widgets only consume standard `Stream<T>` / `ApiResponse<T>`.
class NoRxdartInUi extends DartLintRule {
  NoRxdartInUi() : super(code: _code);

  static const _code = LintCode(
    name: 'no_rxdart_in_ui',
    problemMessage:
        'RxDart must not be imported outside bloc/ files. UI widgets consume '
        'Stream<T> / ApiResponse<T> only (AGENTS.md Golden Rule #4).',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = resolver.source.fullName.replaceAll('\\', '/');
    if (_isAllowedRxdartFile(path)) return;

    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue ?? '';
      if (uri == 'package:rxdart/rxdart.dart' ||
          uri.startsWith('package:rxdart/')) {
        reporter.atNode(node, _code);
      }
    });
  }

  bool _isAllowedRxdartFile(String path) {
    return path.contains('/bloc/') ||
        path.endsWith('_bloc.dart') ||
        path.contains('/utils/') ||
        path.contains('/redux/');
  }
}
