import 'dart:convert';

import 'package:redux/redux.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:temp_test_app/redux/app_state.dart';
import 'package:temp_test_app/redux/actions.dart';

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
  
  const secureStorage = FlutterSecureStorage();
  

  // authToken
  if (state.authToken != null) {
    
    await secureStorage.write(key: 'auth_token', value: state.authToken!);
    
    
  } else {
    
    await secureStorage.delete(key: 'auth_token');
    
    
  }

  // userData
  if (state.userData != null) {
    
    await secureStorage.write(key: 'user_data', value: json.encode(state.userData));
    
    
  } else {
    
    await secureStorage.delete(key: 'user_data');
    
    
  }

  // locale
  await prefs.setString('locale', state.locale);
}
