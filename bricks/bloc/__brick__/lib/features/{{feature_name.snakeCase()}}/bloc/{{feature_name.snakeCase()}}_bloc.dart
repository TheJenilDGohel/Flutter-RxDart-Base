import 'package:rxdart/rxdart.dart';
import 'package:{{project_name}}/networking/api_exceptions.dart';
import 'package:{{project_name}}/networking/api_response.dart';
import 'package:{{project_name}}/networking/cancel_token_owner.dart';
import 'package:{{project_name}}/features/{{feature_name.snakeCase()}}/repo/{{feature_name.snakeCase()}}_repo.dart';

/// BLoC for {{feature_name.titleCase()}}.
///
/// **Architecture Rules & Invariants:**
/// - Suffix public streams with `$` (e.g. `state$`, `data$`).
/// - Use [BehaviorSubject] for persistent state snapshots or [PublishSubject] for one-off events.
/// - NEVER use RxDart subjects outside BLoC — widgets only consume standard [Stream] / [ApiResponse].
/// - Parse raw response from Repo here via `Model.fromJson(json)` and emit into [ApiResponse<T>] streams.
/// - Guard all post-await emissions with `if (!subject.isClosed)`.
/// - Always mix in [CancelTokenOwner], call `createNewToken()` before requests, and `cancelRequests()` in [dispose].
/// - Store subscriptions in [subscriptions] and cancel them in [dispose].
final class {{feature_name.pascalCase()}}Bloc with CancelTokenOwner {
  final {{feature_name.pascalCase()}}Repo _repo;

  /// Holds stream subscriptions for clean disposal.
  final CompositeSubscription subscriptions = CompositeSubscription();

  {{feature_name.pascalCase()}}Bloc({ {{feature_name.pascalCase()}}Repo? repo})
      : _repo = repo ?? {{feature_name.pascalCase()}}Repo();

  /// Cancels all subscriptions, in-flight HTTP requests, and closes RxDart subjects.
  void dispose() {
    cancelRequests();
    subscriptions.dispose();
  }
}
