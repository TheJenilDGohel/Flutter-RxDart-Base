import 'dart:convert';

import 'package:redux/redux.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:{{project_name}}/redux/app_state.dart';
import 'package:{{project_name}}/redux/actions.dart';
import 'package:{{project_name}}/redux/reducers/app_reducer.dart';
import 'package:{{project_name}}/redux/middleware/logging_middleware.dart';
import 'package:{{project_name}}/redux/middleware/persistence_middleware.dart';

/// Redux [Store] helper & token provider for non-widget layers (e.g., Dio interceptors).
abstract final class AppStore {
  static late final Store<AppState> _store;

  /// Exposes the underlying store instance if needed.
  static Store<AppState> get store => _store;

  /// Current auth token for non-widget code (e.g. AuthInterceptor) without needing BuildContext.
  static String? get authToken => _store.state.authToken;

  /// Current snapshot of global state.
  static AppState get state => _store.state;

  /// Convenience dispatch helper.
  static void dispatch(AppAction action) => _store.dispatch(action);

  /// Hydrates persisted state from SharedPreferences and returns the initialized [Store].
  ///
  /// Call once in main() before runApp().
  static Future<Store<AppState>> init() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('auth_token');
    final locale = prefs.getString('locale') ?? 'en';
    final userDataJson = prefs.getString('user_data');

    Map<String, dynamic>? userData;
    if (userDataJson != null) {
      userData = Map<String, dynamic>.from(
        json.decode(userDataJson) as Map,
      );
    }

    _store = Store<AppState>(
      appReducer,
      initialState: AppState(
        authToken: token,
        userData: userData,
        locale: locale,
      ),
      middleware: [
        loggingMiddleware,
        persistenceMiddleware,
      ],
    );

    return _store;
  }
}
