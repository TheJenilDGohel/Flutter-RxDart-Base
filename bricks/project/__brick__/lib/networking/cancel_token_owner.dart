import 'package:dio/dio.dart';

/// Mixin for BLoCs / Repositories that own a [CancelToken] tied to their
/// lifecycle.
///
/// Call [cancelRequests] from BLoC `dispose()` to abort any pending Dio requests
/// started with [cancelToken].
///
/// Example:
/// ```dart
/// final class MyFeatureBloc with CancelTokenOwner {
///   Future<void> loadData() async {
///     final response = await _repo.getData(cancelToken: cancelToken);
///   }
///
///   void dispose() {
///     cancelRequests();
///   }
/// }
/// ```
mixin CancelTokenOwner {
  CancelToken? _cancelToken;

  /// Token to pass into Dio requests. Lazily created.
  CancelToken get cancelToken => _cancelToken ??= CancelToken();

  /// Whether the owned token has already been cancelled.
  bool get isCancelled => _cancelToken?.isCancelled ?? false;

  /// Cancels any in-flight request using this token and clears it so a new
  /// token will be created on the next access.
  void cancelRequests([String? reason]) {
    _cancelToken?.cancel(reason ?? '$runtimeType disposed');
    _cancelToken = null;
  }

  /// Creates a fresh token, cancelling any previous one.
  ///
  /// Useful for pull-to-refresh or re-fetch flows where the old request
  /// should be abandoned.
  CancelToken createNewToken() {
    cancelRequests('Re-fetching data');
    _cancelToken = CancelToken();
    return _cancelToken!;
  }
}
