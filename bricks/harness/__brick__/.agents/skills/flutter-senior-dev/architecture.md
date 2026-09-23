# Base architecture snapshot (harness brick 1.1.0)

Contents: 1 Generated layout, 2 Networking, 3 Redux, 4 BLoC and page lifecycle, 5 UI kit, 6 Routing, 7 Localization and sizing, 8 Bricks, harness and lints, 9 Dependencies.

This is a summary of the base repository. If the working copy differs, the working copy wins. Re-read the real file before quoting a signature.

## 1. Generated layout (`mason make project`)

```
AGENTS.md / CLAUDE.md          # harness: agent contract (CLAUDE.md = @AGENTS.md)
scripts/agent/                 # wire_route.dart, verify.ps1, verify.sh
lib/
├── features/                  # one folder per screen/flow (bloc brick output)
├── l10n/                      # app_en.arb, app_hi.arb  (l10n.yaml at project root)
├── networking/
│   ├── interceptors/          # connectivity, auth, platform_injector, error_mapping
│   ├── api_base_helper.dart   # facade: get/post/put/delete/postFormData/putFormData
│   ├── api_constants.dart     # base URL and endpoint registry
│   ├── api_exceptions.dart    # sealed ApiException (8 subtypes)
│   ├── api_response.dart      # sealed ApiResponse<T>
│   ├── cancel_token_owner.dart
│   └── dio_client.dart
├── redux/                     # actions, app_state, app_store, reducers/, middleware/
├── resources/                 # res_colors.dart, app_typography.dart
├── services/                  # notification_service, device_info_service (stubs)
├── screens/                   # showcase demo
├── utils/                     # extensions/, router/, widgets/, common_utils, show_message
└── main.dart
```

Feature folder from `mason make bloc`:

```
lib/features/<name>/
├── bloc/<name>_bloc.dart
├── model/                      # empty, .gitkeep
├── repo/<name>_repo.dart
├── widgets/<name>_content_widget.dart
└── <name>_page.dart
```

## 2. Networking

- `DioClient` singleton: base URL from `ApiConstants`, 30 s connect/receive/send timeouts, JSON, HTTP/2 adapter.
- Interceptor order (do not reorder): 1 Connectivity (blocks when offline), 2 Auth (bearer from `AppStore.authToken`), 3 PlatformInjector (adds `{"platform": "app"}` to JSON bodies), 4 Retry (`dio_smart_retry`, 3 retries at 1 s, 2 s, 4 s on timeouts and 502/503), 5 ErrorMapping.
- `ApiBaseHelper({Dio? dio})` is constructible for tests and has a lazy `instance` singleton. Methods return `Future<Map<String, dynamic>>` and throw `ApiException`. Each accepts `queryParameters` and `cancelToken`; the form-data variants accept `onSendProgress`. A response whose top level is not a JSON object throws at the cast, so list endpoints must be wrapped in an object or need an extra method.
- Repositories take `{ApiBaseHelper? api}` and default to `ApiBaseHelper.instance`.
- `ApiException` (sealed): `NoInternetException`, `BadRequestException` (400), `UnauthorizedException` (401), `NotFoundException` (404), `ConflictException` (409), `RequestTimeoutException` (408 or Dio timeouts), `InternalServerErrorException` (500 and fallbacks), `BusinessLogicException` (HTTP 200/201 with `{"status": false, "message": ...}`).
- Only `BusinessLogicException.message` is shown verbatim to users. Everything else maps through `userFacingMessage` / `userMessage` (extension in `utils/extensions/exception_ext.dart`), which has a switch with safe copy.
- `ApiResponse<T>` (sealed): `InitialResponse`, `LoadingResponse`, `SuccessResponse(data)`, `ErrorResponse(error, {retry})`; `.data` returns data only when successful.
- `CancelTokenOwner` mixin: `cancelToken` (lazy), `isCancelled`, `cancelRequests([reason])`, `createNewToken()` (cancels the old one, creates a fresh one).

## 3. Redux (session only)

- `AppState` fields: `authToken`, `userData` (a `Map<String, dynamic>?`), `locale`. Immutable with `copyWith`.
- `AppAction` sealed: `SetAuthTokenAction`, `SetUserDataAction`, `SetLocaleAction`, `LogoutAction`. Reducer uses exhaustive switch.
- `AppStore.init()` hydrates from SharedPreferences (`auth_token`, `locale`, `user_data`) and must be awaited in `main()` before `runApp` so no request goes out unauthenticated. `AppStore.authToken`, `AppStore.state`, `AppStore.dispatch(...)` are static helpers for non-widget code.
- Middleware: `loggingMiddleware` (debug) and `persistenceMiddleware` (writes to SharedPreferences).
- The token is stored in plain SharedPreferences. Flag this for any app handling minors' or financial data.

## 4. BLoC and page lifecycle

- `final class XBloc with CancelTokenOwner`, constructor `XBloc({XRepo? repo})`, a `CompositeSubscription subscriptions`, and `void dispose()` that calls `cancelRequests()` and `subscriptions.dispose()`.
- Public streams end in `$` (`state$`, `data$`). `BehaviorSubject` for state, `PublishSubject` for one-off events. Guard every emission after an `await` with `if (!subject.isClosed)`.
- Page: `StatefulWidget`, `late final XBloc _bloc` created in `initState()`, disposed in `dispose()`. The page hosts the BLoC; the content widget is "dumb" and takes data.
- Pattern A (search/fetch/events) and Pattern B (forms, Redux bridge) are rules 7 to 10 in the golden rules.

## 5. UI kit (`utils/widgets/`)

`AppScaffold`, `AppCard`, `AppResponseBuilder<T>` (binds an `ApiResponse` stream to loading, error-with-retry, and a typed builder), `AppLoadingState`, `AppErrorState`, `AppEmptyState`, `CommonButton` (built-in loading spinner), `AppTextFormField` (label, hint, password toggle), `AppDialog` (`showConfirmation`, `showStatus`, `showAsyncConfirm`). Toasts via `ShowMessage.success/error/info/warning` (OverlaySupport). Helpers in `CommonUtils` (hideKeyboard, launcher recipes, showCommonDialog).

## 6. Routing

Navigator with `onGenerateRoute` in `utils/router/app_router.dart`, constants in `utils/router/routes.dart` (`abstract final class Routes`), and a `navigatorKey`. `wire_route.dart` adds a `Routes` constant and a `switch (settings.name)` case, supports delegated sub-routers whose filename contains the route prefix, and refuses to inject when `go_router` or `auto_route` is in `pubspec.yaml`.

## 7. Localization and sizing

`l10n.yaml` points at `lib/l10n` with `app_en.arb` as template; generated class `AppLocalizations` in `lib/l10n/generated`. Access via `context.l10n`; theme text via `context.textTheme`. Use `flutter_screenutil` units (`.w .h .r .sp`) instead of raw pixels. Designed for phones; tablets and desktop web need their own design size or layout.

## 8. Bricks, harness and lints

- `project`: run once on a fresh `flutter create` from inside the app folder (the hook checks for `android/` and `ios/`, then runs `flutter pub get`, `flutter gen-l10n`, package rename, and optionally the harness).
- `bloc`: run per feature from the project root; auto-detects `project_name` from `pubspec.yaml`.
- `harness`: writes `AGENTS.md`, `CLAUDE.md`, `scripts/agent/*`, and wires `custom_lint` plus `redux_rxdart_lints` (git dependency) into `pubspec.yaml` and `analysis_options.yaml`.
- Lint rules: `no_rxdart_in_ui` (rule 4), `no_setstate_in_widget` (rule 3), `repo_transport_only` (rule 1).
- Quality gate: `dart format --set-exit-if-changed .` and `flutter analyze --fatal-infos`.
- Backend discovery convention: look for `*.postman_collection.json` first, then OpenAPI/Swagger, then docs.

## 9. Key dependencies

dio, dio_smart_retry, dio_http2_adapter, connectivity_plus, redux, flutter_redux, shared_preferences, rxdart, flutter_screenutil, overlay_support, intl, url_launcher, snug_logger; dev: flutter_lints, change_app_package_name, custom_lint, redux_rxdart_lints.
