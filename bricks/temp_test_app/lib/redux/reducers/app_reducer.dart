import 'package:temp_test_app/redux/app_state.dart';
import 'package:temp_test_app/redux/actions.dart';

/// Pure reducer function. Exhaustive switch over the sealed [AppAction] type.
AppState appReducer(AppState state, dynamic action) {
  if (action is! AppAction) return state;

  return switch (action) {
    SetAuthTokenAction(:final token) => state.copyWith(
        authToken: () => token,
      ),
    SetUserDataAction(:final userData) => state.copyWith(
        userData: () => userData,
      ),
    SetLocaleAction(:final locale) => state.copyWith(
        locale: locale,
      ),
    LogoutAction() => const AppState(),
  };
}
