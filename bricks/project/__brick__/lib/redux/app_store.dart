import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:redux/redux.dart';
import 'package:shared_preferences/shared_preferences.dart';
{{#include_secure_storage}}
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
{{/include_secure_storage}}
import 'package:{{project_name}}/redux/app_state.dart';
import 'package:{{project_name}}/redux/actions.dart';
import 'package:{{project_name}}/redux/reducers/app_reducer.dart';
import 'package:{{project_name}}/redux/middleware/logging_middleware.dart';
import 'package:{{project_name}}/redux/middleware/persistence_middleware.dart';

/// Redux [Store] helper & token provider for non-widget layers (e.g., Dio interceptors).
abstract final class AppStore {
  static Store<AppState>? _store;

  /// Whether [init] has run.
  static bool get isInitialized => _store != null;

  /// The store instance. Throws if [init] has not been called.
  static Store<AppState> get store =>
      _store ?? (throw StateError('AppStore.init() has not been called'));

  /// Current auth token for non-widget code (e.g. AuthInterceptor) without
  /// needing BuildContext. Null before [init].
  static String? get authToken => _store?.state.authToken;

  /// Current snapshot of global state.
  static AppState get state => store.state;

  /// Convenience dispatch helper. No-op before [init].
  static void dispatch(AppAction action) => _store?.dispatch(action);

  /// Hydrates persisted state from SharedPreferences and returns the initialized [Store].
  ///
  /// Call once in main() before runApp().
  static Future<Store<AppState>> init() async {
    return _store = Store<AppState>(
      appReducer,
      initialState: await _hydrate(),
      middleware: [
        if (kDebugMode) loggingMiddleware,
        persistenceMiddleware,
      ],
    );
  }

  /// Reads persisted state. Never throws: unreadable or corrupt storage
  /// (e.g. a keystore reset after an Android backup restore) is wiped and
  /// the app starts signed out instead of crashing on launch.
  static Future<AppState> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final locale = prefs.getString(PersistenceKeys.locale) ?? 'en';
    {{#include_secure_storage}}
    const secureStorage = FlutterSecureStorage();
    {{/include_secure_storage}}

    try {
      {{#include_secure_storage}}
      final token = await secureStorage.read(key: PersistenceKeys.authToken);
      final userDataJson =
          await secureStorage.read(key: PersistenceKeys.userData);
      {{/include_secure_storage}}
      {{^include_secure_storage}}
      final token = prefs.getString(PersistenceKeys.authToken);
      final userDataJson = prefs.getString(PersistenceKeys.userData);
      {{/include_secure_storage}}

      final userData = userDataJson == null
          ? null
          : Map<String, dynamic>.from(json.decode(userDataJson) as Map);

      return AppState(authToken: token, userData: userData, locale: locale);
    } catch (e) {
      debugPrint('AppStore: discarding unreadable session: $e');
      {{#include_secure_storage}}
      try {
        await secureStorage.delete(key: PersistenceKeys.authToken);
        await secureStorage.delete(key: PersistenceKeys.userData);
      } catch (_) {}
      {{/include_secure_storage}}
      {{^include_secure_storage}}
      await prefs.remove(PersistenceKeys.authToken);
      await prefs.remove(PersistenceKeys.userData);
      {{/include_secure_storage}}
      return AppState(locale: locale);
    }
  }
}
