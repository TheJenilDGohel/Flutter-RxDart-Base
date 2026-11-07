import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:redux/redux.dart';
import 'package:shared_preferences/shared_preferences.dart';
{{#include_secure_storage}}
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
{{/include_secure_storage}}
import 'package:{{project_name}}/redux/app_state.dart';
import 'package:{{project_name}}/redux/actions.dart';

/// Storage keys shared with [AppStore.init].
abstract final class PersistenceKeys {
  static const authToken = 'auth_token';
  static const userData = 'user_data';
  static const locale = 'locale';
}

/// Persists authToken, userData and locale after each [AppAction].
///
/// Writes are queued so they complete in dispatch order — a
/// `SetAuthTokenAction` followed quickly by `LogoutAction` can never leave
/// a stale token on disk. Only slices that actually changed are written.
/// Does not block the dispatch chain.
void persistenceMiddleware(
  Store<AppState> store,
  dynamic action,
  NextDispatcher next,
) {
  final before = store.state;
  next(action);
  final after = store.state;

  if (action is AppAction) {
    _queue = _queue.then((_) => _sync(before, after)).catchError(
      (Object e, StackTrace st) {
        debugPrint('persistenceMiddleware: write failed: $e');
      },
    );
  }
}

Future<void> _queue = Future<void>.value();

/// Completes when all queued writes have finished. Useful in tests.
@visibleForTesting
Future<void> get persistenceIdle => _queue;

Future<void> _sync(AppState before, AppState after) async {
  final prefs = await SharedPreferences.getInstance();
  {{#include_secure_storage}}
  const secureStorage = FlutterSecureStorage();
  {{/include_secure_storage}}

  if (before.authToken != after.authToken) {
    final token = after.authToken;
    {{#include_secure_storage}}
    token == null
        ? await secureStorage.delete(key: PersistenceKeys.authToken)
        : await secureStorage.write(key: PersistenceKeys.authToken, value: token);
    {{/include_secure_storage}}
    {{^include_secure_storage}}
    token == null
        ? await prefs.remove(PersistenceKeys.authToken)
        : await prefs.setString(PersistenceKeys.authToken, token);
    {{/include_secure_storage}}
  }

  if (!mapEquals(before.userData, after.userData)) {
    final userData = after.userData;
    {{#include_secure_storage}}
    userData == null
        ? await secureStorage.delete(key: PersistenceKeys.userData)
        : await secureStorage.write(
            key: PersistenceKeys.userData,
            value: json.encode(userData),
          );
    {{/include_secure_storage}}
    {{^include_secure_storage}}
    userData == null
        ? await prefs.remove(PersistenceKeys.userData)
        : await prefs.setString(PersistenceKeys.userData, json.encode(userData));
    {{/include_secure_storage}}
  }

  if (before.locale != after.locale) {
    await prefs.setString(PersistenceKeys.locale, after.locale);
  }
}
