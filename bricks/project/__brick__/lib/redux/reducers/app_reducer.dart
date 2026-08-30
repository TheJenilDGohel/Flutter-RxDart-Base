import 'package:{{project_name}}/redux/app_state.dart';
import 'package:{{project_name}}/redux/actions.dart';

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
