import 'package:rxdart/rxdart.dart';
import 'package:{{project_name}}/networking/api_exceptions.dart';
import 'package:{{project_name}}/networking/api_response.dart';
import 'package:{{project_name}}/utils/extensions/exception_ext.dart';
import '../repo/{{feature_name.snakeCase()}}_repo.dart';

/// BLoC for {{feature_name.titleCase()}}.
///
/// **Architecture Rules & Conventions:**
/// - Use [BehaviorSubject] for persistent state snapshots or [PublishSubject] for one-off events (toasts/navigation).
/// - Store stream subscriptions in [subscriptions] and cancel them in [dispose].
/// - Guard post-await emissions with `if (!subject.isClosed)`.
/// - Wrap UI states in [ApiResponse<T>] (`initial()`, `loading()`, `completed()`, `error()`).
/// - Use `exception.userFacingMessage` from `exception_ext.dart` for UI error display.
final class {{feature_name.pascalCase()}}Bloc {
  final {{feature_name.pascalCase()}}Repo _repo;

  /// Holds stream subscriptions for clean disposal.
  final CompositeSubscription subscriptions = CompositeSubscription();

  {{feature_name.pascalCase()}}Bloc({ {{feature_name.pascalCase()}}Repo? repo})
      : _repo = repo ?? {{feature_name.pascalCase()}}Repo();

  /// Cancels all subscriptions and closes RxDart subjects.
  void dispose() {
    subscriptions.dispose();
  }
}
