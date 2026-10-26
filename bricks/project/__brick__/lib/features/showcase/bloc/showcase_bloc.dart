import 'package:rxdart/rxdart.dart';

/// BLoC for the Showcase demo page.
///
/// Owns the simulated button-loading state so the page stays setState-free.
final class ShowcaseBloc {
  final BehaviorSubject<bool> _isButtonLoading = BehaviorSubject.seeded(false);

  /// Whether the demo submit button is in a loading state.
  Stream<bool> get isButtonLoading$ => _isButtonLoading.stream;

  /// Synchronous read for [StreamBuilder.initialData].
  bool get currentIsButtonLoading => _isButtonLoading.value;

  /// Simulates a form submission with a 2-second delay.
  ///
  /// Returns `true` when the simulated task completes.
  Future<bool> simulateSubmit() async {
    if (_isButtonLoading.value) return false;

    _isButtonLoading.add(true);
    try {
      await Future<void>.delayed(const Duration(seconds: 2));
      return true;
    } finally {
      if (!_isButtonLoading.isClosed) {
        _isButtonLoading.add(false);
      }
    }
  }

  void dispose() => _isButtonLoading.close();
}
