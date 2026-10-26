# Base architecture snapshot (project brick 1.4.1 · bloc 1.2.1 · harness 1.7.3)

Contents: 1 Layout, 2 Networking, 3 Redux, 4 BLoC and page, 5 UI kit, 6 Routing, 7 Localization and sizing, 8 Bricks, harness and lints, 9 Dependencies.

A summary of what the bricks generate. The working copy wins: re-read the real file before quoting a signature.


## 1. Layout

```
AGENTS.md                      # agent contract (all tools); CLAUDE.md imports it
.claude/                       # settings.json (edit hook, permissions), skills/ (entry points), agents/flutter-qa.md
.agents/skills/                # this skill + task skills (add-feature, add-endpoint, manage-state,
                               #   build-ui, write-tests, fix-bug, evolve-harness); project skills too
.mcp.json, .cursor/mcp.json    # Dart & Flutter MCP server (dart mcp-server)
.harness/                      # active-context.md, progress.md, lessons.md, system-snapshot.md, version.json;
                               #   skills/<skill>.md overlays and specs/<feature>.md (created by agents)
scripts/agent/                 # verify.dart (+ .sh/.ps1), on_edit.dart, snapshot.dart, wire_route.dart, learn.dart, upgrade.dart
lib/
├── features/<name>/           # one folder per screen/flow; showcase/ is the demo
├── l10n/                      # app_en.arb, app_hi.arb → generated AppLocalizations
├── networking/
│   ├── interceptors/          # connectivity, auth, platform_injector, error_mapping
│   ├── api_base_helper.dart   # get/post/put/delete/postFormData/putFormData
│   ├── api_constants.dart     # BASE_URL (from .env) and endpoint registry
│   ├── api_exceptions.dart    # sealed ApiException
│   ├── api_response.dart      # sealed ApiResponse<T>
│   ├── cancel_token_owner.dart
│   └── dio_client.dart
├── redux/                     # actions, app_state, app_store, reducers/, middleware/
├── resources/                 # res_colors.dart, app_typography.dart
├── services/                  # device/platform capabilities (stubs to extend)
├── utils/                     # extensions/, router/, widgets/ui/, widgets/view/, show_message, common_utils
└── main.dart
```

Feature folder (`mason make bloc` / `wire_route.dart`):

```
lib/features/<name>/
├── bloc/<name>_bloc.dart      # fetch({bool refresh}), data$ stream
├── model/<name>_model.dart    # defensive fromJson
├── repo/<name>_repo.dart      # transport only
├── widgets/<name>_content_widget.dart
└── <name>_page.dart           # owns the BLoC, AppResponseBuilder + RefreshIndicator
test/features/<name>/bloc/<name>_bloc_test.dart
```

## 2. Networking

- `DioClient.instance`: `ApiConstants.baseUrl`, 30 s timeouts, JSON, `Http2Adapter` (falls back to HTTP/1.1 for servers without h2).
- Interceptors, in order: 1 `ConnectivityInterceptor` (offline → `NoInternetException`), 2 `AuthInterceptor` (bearer token only for the `BASE_URL` host), 3 `PlatformInjectorInterceptor` (`{"platform": "app"}` in JSON bodies), 4 `RetryInterceptor` (GET/HEAD/OPTIONS/PUT/DELETE only, 2 retries at 1 s and 3 s; POST/PATCH never retried), 5 `ErrorMappingInterceptor`.
- `ErrorMappingInterceptor`: HTTP 200 with `{"status": false, "message"}` → `BusinessLogicException`; 400 `BadRequestException`, 401 `UnauthorizedException` (also dispatches `LogoutAction` when a token is held), 403 `ForbiddenException`, 404 `NotFoundException`, 408/timeouts `RequestTimeoutException`, 409 `ConflictException`, 422 `ValidationException` (server message), 429 `TooManyRequestsException`, 5xx `InternalServerErrorException`, cancel `RequestCancelledException`, no connection `NoInternetException`. Server `message`/`error` fields are kept in `ApiException.message`; `statusCode` is set for HTTP errors.
- `ApiBaseHelper({Dio? dio})` with a lazy `instance`. Returns `Map<String, dynamic>`; a top-level JSON array becomes `{'items': [...]}`; a non-JSON body throws `MalformedResponseException`. Only `ApiException`s escape.
- UI copy: `error.userFacingMessage(context)` (`utils/extensions/exception_ext.dart`). Shown verbatim only for `BusinessLogicException` and non-empty `ValidationException`; the rest are localized.
- `ApiResponse<T>` (sealed): `InitialResponse`, `LoadingResponse`, `SuccessResponse(data)`, `ErrorResponse(ApiException error, {RetryCallback? retry})`; `.data` is non-null only on success.
- `CancelTokenOwner`: `cancelToken`, `isCancelled`, `cancelRequests([reason])`, `createNewToken()`.
- **Repositories (transport only)**: call `ApiBaseHelper`, return raw `Map<String, dynamic>`, never call `fromJson` (enforced by `repo_transport_only` lint), forward `CancelToken? cancelToken`, and let exceptions propagate.
- **Repository composition (capability mixins)**: exactly one repository per BLoC. Never inject multiple repositories into a BLoC; never inherit other feature repositories. When multiple features share secondary calls (e.g. dropdown options, tags, profile fetch, logout), extract the call into a `mixin <Capability>Mixin` and compose onto the feature repository with `with`.


## 3. Redux (session only)

- `AppState`: `authToken`, `userData` (`Map<String, dynamic>?`), `locale`; immutable with `copyWith`.
- `AppAction` (sealed): `SetAuthTokenAction`, `SetUserDataAction`, `SetLocaleAction`, `LogoutAction` (clears the session, keeps the locale).
- `AppStore.init()` (await in `main()` before `runApp`) hydrates from storage; unreadable or corrupt storage is wiped and the app starts signed out. `AppStore.authToken`, `.state`, `.dispatch()` for non-widget code; `authToken`/`dispatch` are safe before `init()`.
- Middleware: `loggingMiddleware` (debug builds only) and `persistenceMiddleware` (queued, in-order writes of changed slices; keys in `PersistenceKeys`). Token and user data go to `flutter_secure_storage` when the project was generated with `include_secure_storage`, otherwise SharedPreferences.

## 4. BLoC and page

- `final class XBloc with CancelTokenOwner`, constructor `XBloc({XRepo? repo})`, `CompositeSubscription subscriptions`, `dispose()` → `cancelRequests()`, `subscriptions.dispose()`, close subjects.
- Public streams end in `$`. `BehaviorSubject` for state, `PublishSubject` for one-off events. All emissions go through one guard that drops them after `dispose()`.
- Page: `StatefulWidget` that creates the BLoC, calls `fetch()`, disposes it, and binds `data$` with `AppResponseBuilder`. Content widgets receive parsed models, never the BLoC or a stream.

## 5. UI kit

- `utils/widgets/ui/` (export barrel `ui_components.dart`): `AppScaffold`, `AppCard`, `AppResponseBuilder<T>`, `AppLoadingState`, `AppErrorState`, `AppEmptyState`, `CommonButton` (built-in loading).
- `utils/widgets/view/`: `AppDialog` (`showConfirmation`, `showStatus`, `showAsyncConfirm`) and `AppTextFormField`, each with its own small BLoC.
- Toasts: `ShowMessage.success/error/info/warning` (toastification). Context helpers: `context.l10n`, `context.textTheme`, `context.colorScheme`, `context.screenSize`.

## 6. Routing

Navigator with `onGenerateRoute` (`utils/router/app_router.dart`), constants in `utils/router/routes.dart` (`abstract final class Routes`), global `navigatorKey`. `wire_route.dart` adds the constant and the router case, supports delegated sub-routers, and refuses to run when `go_router` or `auto_route` is a dependency.

## 7. Localization and sizing

`l10n.yaml` → `lib/l10n`, template `app_en.arb`, generated `AppLocalizations`. Add every string to both ARB files. Sizes via `flutter_screenutil` (`.w .h .r .sp`, design size 375×812) — public widgets only (rule 13). Colors from `ResColors`, opacity with `withValues(alpha:)`.

## 8. Bricks, harness and lints

- `project`: run once inside a fresh `flutter create` app. `pre_gen` validates names and ids before writing; `post_gen` runs `pub get`, `gen-l10n`, applies the Android package and iOS bundle id, formats, merges `.gitignore`, and installs the harness (`--on-conflict skip`).
- `bloc`: per feature, from the project root; reads `project_name` from `pubspec.yaml`.
- `harness`: pure template (no hooks) — `AGENTS.md`, `CLAUDE.md`, `.claude/`, `.agents/skills/` (8 skills), MCP config, `.harness/` (memory + lessons), `scripts/agent/`. `learn.dart` runs the learning loop; `upgrade.dart` replaces only the skills it ships and never `.harness/`.
- `redux_rxdart_lints` (analyzer plugin, top-level `plugins:` in `analysis_options.yaml`): `repo_transport_only` (rule 1), `no_exception_tostring` (2), `no_setstate_in_widget` (3), `no_rxdart_in_ui` (4), `no_screenutil_in_private_widget` (13). Reported by `flutter analyze`, the IDE and `verify.dart`.

## 9. Key dependencies

dio, dio_smart_retry, dio_http2_adapter, connectivity_plus, redux, flutter_redux, shared_preferences, (flutter_secure_storage), rxdart, flutter_screenutil, toastification, intl, url_launcher, snug_logger, flutter_dotenv; dev: flutter_lints (the `redux_rxdart_lints` plugin is configured in `analysis_options.yaml`, not `pubspec.yaml`).
