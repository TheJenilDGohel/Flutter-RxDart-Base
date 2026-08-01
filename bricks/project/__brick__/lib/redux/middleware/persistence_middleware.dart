import 'dart:convert';

import 'package:redux/redux.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:{{project_name}}/redux/app_state.dart';
import 'package:{{project_name}}/redux/actions.dart';

/// Syncs authToken, userData, and locale to SharedPreferences on every
/// relevant mutation. Fire-and-forget — does not block the dispatch chain.
void persistenceMiddleware(
  Store<AppState> store,
  Object action,
  NextDispatcher next,
) {
  next(action);

  // Only persist on AppAction mutations
  if (action is AppAction) {
    _syncToPrefs(store.state);
  }
}

Future<void> _syncToPrefs(AppState state) async {
  final prefs = await SharedPreferences.getInstance();

  // authToken
  if (state.authToken != null) {
    await prefs.setString('auth_token', state.authToken!);
  } else {
    await prefs.remove('auth_token');
  }

  // userData
  if (state.userData != null) {
    await prefs.setString('user_data', json.encode(state.userData));
  } else {
    await prefs.remove('user_data');
  }

  // locale
  await prefs.setString('locale', state.locale);
}
