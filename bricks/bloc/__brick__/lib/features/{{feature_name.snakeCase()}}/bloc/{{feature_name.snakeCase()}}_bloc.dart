import 'package:rxdart/rxdart.dart';
import 'package:{{project_name}}/networking/cancel_token_owner.dart';
import 'package:{{project_name}}/features/{{feature_name.snakeCase()}}/repo/{{feature_name.snakeCase()}}_repo.dart';
import 'package:{{project_name}}/features/{{feature_name.snakeCase()}}/model/{{feature_name.snakeCase()}}_model.dart';
import 'package:{{project_name}}/networking/api_exceptions.dart';
import 'package:{{project_name}}/networking/api_response.dart';

/// BLoC for {{feature_name.titleCase()}}.
///
/// **Architecture Rules & Invariants (AGENTS.md):**
/// - Public streams end in `$` (`data$`). Widgets see plain [Stream]s only.
/// - [BehaviorSubject] for state snapshots, [PublishSubject] for one-off
///   events (toasts, navigation).
/// - Parse the repo's raw `Map` here via `Model.fromJson` (Golden Rule #1).
/// - Every emission goes through [_emit], which is a no-op once disposed.
/// - [fetch] calls `createNewToken()` first, so a newer fetch cancels the
///   older one; [dispose] cancels in-flight requests (Golden Rule #8).
final class {{feature_name.pascalCase()}}Bloc with CancelTokenOwner {
  {{feature_name.pascalCase()}}Bloc({ {{feature_name.pascalCase()}}Repo? repo})
      : _repo = repo ?? {{feature_name.pascalCase()}}Repo();

  final {{feature_name.pascalCase()}}Repo _repo;

  /// Holds stream subscriptions for clean disposal.
  final CompositeSubscription subscriptions = CompositeSubscription();

  final BehaviorSubject<ApiResponse<{{feature_name.pascalCase()}}Model>> _data =
      BehaviorSubject.seeded(const ApiResponse.initial());

  /// Main data state for the UI.
  Stream<ApiResponse<{{feature_name.pascalCase()}}Model>> get data$ => _data.stream;

  /// Loads the feature data.
  ///
  /// With [refresh] (pull-to-refresh) the current content stays on screen
  /// instead of being replaced by a loading state.
  Future<void> fetch({bool refresh = false}) async {
    final token = createNewToken();
    if (!(refresh && _data.valueOrNull is SuccessResponse)) {
      _emit(const ApiResponse.loading());
    }
    try {
      final json = await _repo.fetch{{feature_name.pascalCase()}}(cancelToken: token);
      _emit(ApiResponse.completed({{feature_name.pascalCase()}}Model.fromJson(json)));
    } on RequestCancelledException {
      // Superseded by a newer fetch or the screen was closed: not an error.
    } on ApiException catch (e) {
      _emit(ApiResponse.error(e, retry: fetch));
    } on Object catch (e) {
      // Parsing bug or unexpected shape. Never show e.toString() to users.
      _emit(ApiResponse.error(
        MalformedResponseException('{{feature_name.pascalCase()}}: $e'),
        retry: fetch,
      ));
    }
  }

  void _emit(ApiResponse<{{feature_name.pascalCase()}}Model> state) {
    if (!_data.isClosed) _data.add(state);
  }

  /// Cancels in-flight requests and subscriptions, then closes subjects.
  void dispose() {
    cancelRequests();
    subscriptions.dispose();
    _data.close();
  }
}
