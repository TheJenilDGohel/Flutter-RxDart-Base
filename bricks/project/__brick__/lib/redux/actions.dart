/// Sealed action hierarchy for Redux.
///
/// HARD CONSTRAINT: Only auth/session/locale actions belong here.
/// Do not add feature-specific or screen-local actions — that state
/// belongs in a per-screen RxDart BLoC, not in Redux.
sealed class AppAction {
  const AppAction();
}

/// Sets or clears the auth token (JWT / session token).
final class SetAuthTokenAction extends AppAction {
  const SetAuthTokenAction(this.token);
  final String? token;
}

/// Sets or clears the user profile data.
final class SetUserDataAction extends AppAction {
  const SetUserDataAction(this.userData);
  final Map<String, dynamic>? userData;
}

/// Changes the current locale (e.g. 'en', 'hi').
final class SetLocaleAction extends AppAction {
  const SetLocaleAction(this.locale);
  final String locale;
}

/// Clears all persisted state and resets to defaults.
final class LogoutAction extends AppAction {
  const LogoutAction();
}
