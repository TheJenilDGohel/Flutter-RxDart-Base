import 'package:rxdart/rxdart.dart';

/// Manages local UI state for [AppDialog] async-confirm variant.
///
/// Owns the loading flag so the dialog widget stays setState-free.
final class AppDialogBloc {
  final BehaviorSubject<bool> _isLoading = BehaviorSubject.seeded(false);

  /// Whether an async confirmation is in progress.
  Stream<bool> get isLoading$ => _isLoading.stream;

  /// Synchronous read for [StreamBuilder.initialData].
  bool get currentIsLoading => _isLoading.value;

  /// Runs [action] while keeping [isLoading$] in sync.
  ///
  /// Returns `true` when the action succeeds so callers can pop the dialog.
  Future<bool> runAsync(Future<bool> Function() action) async {
    if (_isLoading.value) return false;

    _isLoading.add(true);
    try {
      return await action();
    } catch (_) {
      return false;
    } finally {
      if (!_isLoading.isClosed) {
        _isLoading.add(false);
      }
    }
  }

  void dispose() => _isLoading.close();
}
