import 'package:rxdart/rxdart.dart';

/// Manages local UI state for [AppTextFormField].
///
/// Currently owns only the password-visibility toggle.
/// Follows the same RxDart BLoC pattern used across the project:
/// streams are suffixed with `$`, state lives in [BehaviorSubject].
final class AppTextFormFieldBloc {
  final BehaviorSubject<bool> _obscured;

  AppTextFormFieldBloc({required bool initialObscured})
      : _obscured = BehaviorSubject.seeded(initialObscured);

  /// Whether the text is currently obscured.
  Stream<bool> get obscured$ => _obscured.stream;

  /// Synchronous read for [StreamBuilder.initialData].
  bool get currentObscured => _obscured.value;

  /// Toggles between obscured / visible text.
  void toggleVisibility() => _obscured.add(!_obscured.value);

  void dispose() => _obscured.close();
}
