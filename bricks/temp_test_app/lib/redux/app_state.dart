import 'package:meta/meta.dart';

/// Immutable global app state.
///
/// HARD CONSTRAINT: Redux here is scoped ONLY to authToken/userData/locale
/// persistence. Do not add other fields or treat this as a general state
/// container — this is a deliberate architectural limit, not a starting point.
@immutable
class AppState {
  const AppState({
    this.authToken,
    this.userData,
    this.locale = 'en',
  });

  /// JWT or session token. Persisted to SharedPreferences.
  final String? authToken;

  /// User profile data. Persisted to SharedPreferences as JSON.
  final Map<String, dynamic>? userData;

  /// Current locale code (e.g. 'en', 'hi'). Persisted to SharedPreferences.
  final String locale;

  /// Creates a copy with optional overrides.
  ///
  /// Nullable fields use a `Function()?` wrapper so you can explicitly set
  /// them to `null`: `copyWith(authToken: () => null)`.
  AppState copyWith({
    String? Function()? authToken,
    Map<String, dynamic>? Function()? userData,
    String? locale,
  }) {
    return AppState(
      authToken: authToken != null ? authToken() : this.authToken,
      userData: userData != null ? userData() : this.userData,
      locale: locale ?? this.locale,
    );
  }

  @override
  String toString() =>
      'AppState(authToken: ${authToken != null ? "***" : "null"}, '
      'userData: ${userData != null ? "{...}" : "null"}, locale: $locale)';
}
