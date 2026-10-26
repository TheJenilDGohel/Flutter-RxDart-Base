# Redux session changes

Redux here is deliberately small: `authToken`, `userData`, `locale`, and `AGENTS.md` §1 says "Nothing else". A new field is an architecture change, not an implementation detail: it is permanent global state that is persisted, hydrated and cleared on logout.

**Before you start:** the owner must approve the field, so ask, with the reason it passes the test in `.agents/skills/manage-state/SKILL.md` §1. Once approved, record the decision in `AGENTS.md` §7, and extend the "HARD CONSTRAINT" doc comments in `lib/redux/app_state.dart` and `lib/redux/actions.dart` to name the new field, so the next agent doesn't read the code as forbidding it.

**Never in Redux:** fetched lists or details, loading flags, form input, filters, the selected tab, caches "for convenience", or whole API responses. Roles, permissions and enabled modules stay inside `userData` behind one helper (`.agents/skills/flutter-senior-dev/base-gaps.md` §4). A refresh token is a bigger change; see §1 of the same file.

## Adding a persisted session field

Example: an app-wide theme preference that must survive restarts.

**1. Action** (`lib/redux/actions.dart`, a sealed hierarchy):
```dart
/// Changes the theme preference ('system', 'light' or 'dark').
final class SetThemeModeAction extends AppAction {
  const SetThemeModeAction(this.themeMode);
  final String themeMode;
}
```

**2. State** (`lib/redux/app_state.dart`): add the field, a constructor default, a `copyWith` parameter and `toString`. Redact anything secret in `toString`, the way `authToken` is.
```dart
  const AppState({this.authToken, this.userData, this.locale = 'en', this.themeMode = 'system'});
  final String themeMode;
  // copyWith: String? themeMode → themeMode: themeMode ?? this.themeMode
```

**3. Reducer** (`lib/redux/reducers/app_reducer.dart`): the switch is exhaustive, so the compiler points at every place to update. Decide what logout does. A preference survives logout, like `locale`:
```dart
    SetThemeModeAction(:final themeMode) => state.copyWith(themeMode: themeMode),
    LogoutAction() => AppState(locale: state.locale, themeMode: state.themeMode),
```

**4. Persistence** (`lib/redux/middleware/persistence_middleware.dart`): fields are **not** persisted just by existing. Add a key to `PersistenceKeys` and a write in `_sync` that runs only when the value changed:
```dart
  static const themeMode = 'theme_mode';
  // in _sync:
  if (before.themeMode != after.themeMode) {
    await prefs.setString(PersistenceKeys.themeMode, after.themeMode);
  }
```
Secrets (tokens, PII) go to `flutter_secure_storage` when the project uses it, following the `authToken` branches. Preferences go to SharedPreferences.

**5. Hydration** (`lib/redux/app_store.dart`, `_hydrate`): read the value back with a safe default. Read preferences *outside* the `try` that guards the session, the way `locale` is read, so corrupt session storage doesn't reset them:
```dart
    final themeMode = switch (prefs.getString(PersistenceKeys.themeMode)) {
      'light' => 'light',
      'dark' => 'dark',
      _ => 'system',
    };
```
Then pass it into both `AppState(...)` constructors in `_hydrate`.

**6. Read it in the UI** with a `StoreConnector` as close as possible to the widgets that need it. The app-wide case extends the one in `lib/main.dart`; a record converter keeps one rebuild trigger:
```dart
StoreConnector<AppState, (String, String)>(
  converter: (store) => (store.state.locale, store.state.themeMode),
  builder: (context, prefs) { final (locale, themeMode) = prefs; ... },
)
```

**7. Dispatch.**
- After a network change: the BLoC reports success, and the page dispatches in its event listener (rule 10, recipe A in `bloc-recipes.md`).
- A pure preference with no network call: dispatch straight from the widget, `StoreProvider.of<AppState>(context, listen: false).dispatch(...)`.
- Non-widget code (interceptors, services): `AppStore.dispatch(...)` and `AppStore.state`. BLoCs and repos may read session data this way but never write feature state into the store.

## Tests
- Reducer: a pure function. Assert the new action, `LogoutAction` behavior, and that unrelated fields are unchanged.
- Persistence round trip: call `SharedPreferences.setMockInitialValues({})`, create a store with `persistenceMiddleware`, dispatch, `await persistenceIdle`, then check the stored value. `AppStore.init()` hydrates from the same mock.
- `dart run scripts/agent/verify.dart`. The snapshot lists the new `AppState` field, so review that diff too.
