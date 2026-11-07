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

/// One [CancelToken] per key (a tab, a report): a newer load of a key cancels
/// that key's older load while the other keys keep running. Use it in a BLoC
/// that loads several parts independently; a single-load BLoC uses
/// [CancelTokenOwner].
///
/// ```dart
/// final _tokens = KeyedCancelTokens<Tab>();
///
/// Future<void> fetch({bool refresh = false}) => _load(_tab.value);
///
/// Future<void> _load(Tab tab) async {
///   final token = _tokens.createNewToken(tab); // golden rule 8
///   ...
/// }
///
/// void dispose() => _tokens.cancelAll();
/// ```
final class KeyedCancelTokens<K> {
  final Map<K, CancelToken> _tokens = <K, CancelToken>{};

  /// Cancels the running load of [key] and returns a fresh token for it.
  CancelToken createNewToken(K key) {
    _tokens[key]?.cancel('Re-fetching data');
    return _tokens[key] = CancelToken();
  }

  /// The live token of [key] (created on first use), for follow-up calls such
  /// as the next page.
  CancelToken of(K key) => _tokens[key] ??= CancelToken();

  /// Cancels every running load; call from `dispose()`.
  void cancelAll([String reason = 'disposed']) {
    for (final CancelToken token in _tokens.values) {
      token.cancel(reason);
    }
    _tokens.clear();
  }
}
