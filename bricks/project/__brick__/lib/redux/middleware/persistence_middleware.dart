import 'dart:convert';

import 'package:redux/redux.dart';
import 'package:shared_preferences/shared_preferences.dart';
{{#include_secure_storage}}
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
{{/include_secure_storage}}
import 'package:{{project_name}}/redux/app_state.dart';
import 'package:{{project_name}}/redux/actions.dart';

/// Syncs authToken, userData, and locale to SharedPreferences on every
/// relevant mutation. Fire-and-forget — does not block the dispatch chain.
void persistenceMiddleware(
  Store<AppState> store,
  dynamic action,
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
  {{#include_secure_storage}}
  const secureStorage = FlutterSecureStorage();
  {{/include_secure_storage}}

  // authToken
  if (state.authToken != null) {
    {{#include_secure_storage}}
    await secureStorage.write(key: 'auth_token', value: state.authToken!);
    {{/include_secure_storage}}
    {{^include_secure_storage}}
    await prefs.setString('auth_token', state.authToken!);
    {{/include_secure_storage}}
  } else {
    {{#include_secure_storage}}
    await secureStorage.delete(key: 'auth_token');
    {{/include_secure_storage}}
    {{^include_secure_storage}}
    await prefs.remove('auth_token');
    {{/include_secure_storage}}
  }

  // userData
  if (state.userData != null) {
    {{#include_secure_storage}}
    await secureStorage.write(key: 'user_data', value: json.encode(state.userData));
    {{/include_secure_storage}}
    {{^include_secure_storage}}
    await prefs.setString('user_data', json.encode(state.userData));
    {{/include_secure_storage}}
  } else {
    {{#include_secure_storage}}
    await secureStorage.delete(key: 'user_data');
    {{/include_secure_storage}}
    {{^include_secure_storage}}
    await prefs.remove('user_data');
    {{/include_secure_storage}}
  }

  // locale
  await prefs.setString('locale', state.locale);
}
