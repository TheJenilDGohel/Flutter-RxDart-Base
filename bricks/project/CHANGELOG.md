# Changelog

## 2.0.0

- **Flutter 3.47.8 / Dart 3.13.7 minimum** (breaking, security). Older SDKs build Android, Windows and Linux apps whose `dart:io` TLS trusts the compromised eMudhra intermediate CAs ([GHSA-frr6-h895-5pxp](https://github.com/dart-lang/sdk/security/advisories/GHSA-frr6-h895-5pxp)), and they skip the `redux_rxdart_lints` git plugin. On a machine with another Flutter, pin the project with FVM: `fvm use 3.47.9`. CI tests 3.47.8 and the latest stable.
- **Routing: `go_router`** (breaking). `MaterialApp.router` on `AppRouter.router`: one `GoRoute` per path, so deep links, Android App Links, iOS Universal Links, web URLs and predictive back resolve the same paths. Unknown links open the start screen (`errorBuilder`); `AppRouter.navigatorKey` stays for navigation from outside the tree. `go_router: ^18.1.3`. `wire_route.dart` (harness 2.6.0) adds `GoRoute` entries above the `// wire_route:routes` marker.
- **Default `dart:io` adapter**: `Http2Adapter` and `dio_http2_adapter` removed. `Http2Adapter` forced a `dart:io`-only client (no web build) through an extra dependency; Dio's default adapter uses `dart:io` on devices and the browser on web, streams uploads (real `onSendProgress`) and supports certificate pinning. The platform's native stack (`native_dio_adapter`: HTTP/3, system VPN/proxy, user certificates) is an opt-in recipe in the harness, with its costs: uploads buffered in memory, pinning and proxy settings ignored, iOS 15 minimum, Google Play services on Android, and a Kotlin Gradle Plugin dependency that future Flutter versions will refuse.
- **No connectivity pre-check**: `ConnectivityInterceptor` and `connectivity_plus` removed. The chain is Auth → PlatformInjector → Retry → ErrorMapping; a request that cannot connect is `NoInternetException`. The pre-check cost a platform call per request and misreported captive portals and VPNs.
- **Large screens**: `lib/resources/app_breakpoints.dart` (`WindowSize`, the Material 3 window size classes, and `AppBreakpoints`) and `AppContentWidth` (max 840dp column, exported from `ui_components.dart`). ScreenUtil keeps the 375×812 design below 600dp and runs 1:1 above it; `MediaQuery.fromView` in `main.dart` re-picks the design size on rotation, fold/unfold and split screen (Android 16 ignores orientation and resize locks on large screens). `test/widget_test.dart` covers both.
- **Lints pinned**: the `redux_rxdart_lints` plugin `ref` is the 0.5.0 commit instead of `main`, so a new upstream rule cannot turn an app's gate red overnight.
- **Migration for existing apps** (optional; harness 2.6.0 still wires `onGenerateRoute` apps):
  1. `pubspec.yaml`: raise `environment` to `sdk: ">=3.13.7 <4.0.0"` / `flutter: ">=3.47.8"`, add `go_router: ^18.1.3`, remove `dio_http2_adapter` and, if nothing else uses it, `connectivity_plus`.
  2. Replace `lib/utils/router/app_router.dart` with the 2.0.0 version, move each `case` to a `GoRoute`, and use `MaterialApp.router(routerConfig: AppRouter.router)`. `Navigator.pushNamed(context, Routes.x)` becomes `context.push(Routes.x)`; `RouteSettings.arguments` become path or query parameters.
  3. In `dio_client.dart`, remove the `Http2Adapter` line (Dio's default adapter remains) and drop `ConnectivityInterceptor`.
  4. In `analysis_options.yaml`, pin `ref:` to a commit or tag.

## 1.5.0

- **Native analyzer plugin migration**: `redux_rxdart_lints` ported to Dart native analyzer plugin (`analysis_server_plugin`).
- Removed `custom_lint` and `redux_rxdart_lints` dev dependencies from `pubspec.yaml`.
- Replaced `analyzer: plugins: - custom_lint` with top-level `plugins: redux_rxdart_lints:` git source in `analysis_options.yaml`.
- **Migration for existing apps**:
  1. In `pubspec.yaml`: remove `custom_lint` and `redux_rxdart_lints` from `dev_dependencies`.
  2. In `analysis_options.yaml`: remove `plugins: - custom_lint` under `analyzer:`. Add a top-level `plugins:` block:
     ```yaml
     plugins:
       redux_rxdart_lints:
         git:
           url: https://github.com/jenilseawind-glitch/Flutter-RxDart-Base.git
           path: packages/redux_rxdart_lints
           ref: main
     ```
  3. Run `dart run scripts/agent/upgrade.dart` to upgrade `verify.dart` and harness settings.

## 1.4.1

- **Fix: `mason upgrade` / `flutter pub get` failed on Flutter ≤ 3.44.** 1.4.0 required Dart ≥ 3.13 / Flutter ≥ 3.47 because the floors were set to the toolchain it was tested on. Floors are now what the dependencies need: hooks Dart ≥ 3.5 (`mason`), generated app Dart ≥ 3.10 / Flutter ≥ 3.38 (`toastification`, `shared_preferences`). CI now also runs the smoke test on Flutter 3.38.
- Reverted `meta` to `^1.16.0`: `flutter_test` pins `meta` per SDK (1.18.0 on Flutter 3.44), so `^1.19.0` broke `flutter pub get` on older Flutter. Same for `characters` (`^1.4.0`; Flutter 3.38 pins 1.4.0).
- `post_gen` now formats last and includes the harness `scripts/`, so generated files match the formatter style of the app's own SDK and language version.

## 1.4.0

- Verified on Flutter 3.47.6 / Dart 3.13.5: `flutter analyze --fatal-infos`, `flutter test` and `custom_lint` all pass on a freshly generated app.
- Raised the SDK floor to Dart `>=3.13.0` and Flutter `>=3.47.0`; hook SDK floor raised to match.
- Renamed the private `_CustomToast` to `CustomToast` so the scaffolded app passes `no_screenutil_in_private_widget`.
- **Security**: `AuthInterceptor` only attaches the bearer token to requests for the `BASE_URL` host; third-party absolute URLs never receive it.
- **Session expiry**: a 401 while a token is held dispatches `LogoutAction` once (was a TODO), so expired tokens are not resent forever.
- **Error mapping**: added `ForbiddenException` (403), `ValidationException` (422, carries the server message), `TooManyRequestsException` (429) and `MalformedResponseException`; any 5xx maps to `InternalServerErrorException` with its status code. Server `message`/`error` fields are now read for 4xx/5xx. `ApiException` gained `statusCode`. New localized strings for timeout, 403 and 429.
- **Retry policy**: only idempotent methods (GET/HEAD/OPTIONS/PUT/DELETE) are retried, 2 retries (1s, 3s) instead of 3; POST/PATCH are never replayed; already-mapped errors (e.g. offline) are not retried.
- `ApiBaseHelper` never throws a raw `TypeError` on non-JSON bodies (`MalformedResponseException` instead); removed the redundant `ApiBaseHelper.init()`.
- **Persistence**: writes are queued so they finish in dispatch order (no stale token after a fast login→logout), only changed slices are written, and failures are logged instead of becoming uncaught errors. Storage keys centralised in `PersistenceKeys`.
- **Startup**: `AppStore.init()` no longer crashes on unreadable secure storage or corrupt JSON — it wipes the session and starts signed out. `AppStore.authToken`/`dispatch` are safe before `init()`. Redux logging middleware runs in debug builds only.
- `LogoutAction` keeps the user's locale.
- **Hooks**: new `pre_gen` validates `project_name`, `android_package_name`, `ios_bundle_id` and the target directory *before* any file is written. `ios_bundle_id` is now actually applied (underscores normalised to `-`; `RunnerTests` keeps its suffix). The brick no longer ships a `.gitignore` that replaced Flutter's defaults — harness lines are merged into the existing file. A failed step leaves files in place and prints the command to re-run. The auto-installed harness uses `--on-conflict skip`, so existing `CLAUDE.md`/`AGENTS.md` are never overwritten.
- `post_gen` runs `dart format lib test`: a fresh project previously failed its own `verify` format gate (26 files) under the Dart 3.13 formatter.
- `.env` is tracked (it is a bundled asset, so ignoring it broke fresh clones) and documents that its contents ship inside the app.
- Removed the duplicate, unused `lib/utils/widgets/app_scaffold.dart`.
- Dependencies: `flutter_secure_storage ^11.2.0`, `meta ^1.19.0`, `change_app_package_name ^1.5.0`.
- **Repository URLs** still point at the fork (`jenilseawind-glitch`) on purpose: upstream `TheJenilDGohel` ships an older `redux_rxdart_lints` that breaks new apps. Switch to upstream right after the upstream merge (checklist in `docs/contributing.md` §6).

- `redux_rxdart_lints` migrated to `analyzer ^8` / `custom_lint_builder ^0.8.1` (`DiagnosticSeverity`, `DiagnosticReporter`). `custom_lint 0.8.0` (analyzer 7) crashes on Flutter 3.47.x / Dart 3.13 with `Missing implementation of visitDotShorthandPropertyAccess`. Scaffolded `pubspec.yaml` now requires `custom_lint: ^0.8.1`. Not verified on Flutter 3.44 / Dart 3.12.

## 1.3.2

- Fixed `redux_rxdart_lints` dependency in scaffolded `pubspec.yaml` to reference the remote Git repository instead of a relative local path.
- Updated E2E smoke tester to dynamically resolve remote git linter dependencies.

## 1.3.1

- Restored `meta` constraint to `^1.16.0` and `intl` constraint to `^0.20.2` to ensure full compatibility with Flutter SDK (`flutter_test` pins `meta: 1.18.0` and `flutter_localizations` pins `intl: 0.20.2`).
- Added `meta` and `intl` to dependency audit skip list to prevent automated bumps beyond Flutter SDK pinned versions.
- Added `analysis_options_deprecated_plugins: ignore` alongside `unrecognized_error_code: ignore` in `analysis_options.yaml` to ensure clean analysis across both older and newer Flutter/Dart analyzer versions.

## 1.3.0

- Upgraded `connectivity_plus` from `^6.1.0` to `^7.3.1`; modernized `ConnectivityInterceptor` to use `result.hasConnectivity` instead of `result.contains(ConnectivityResult.none)`.
- Upgraded `flutter_secure_storage` from `^9.2.2` to `^10.3.4` (bridges legacy cipher migration engine — safe for existing user tokens). **Note:** 11.x is intentionally avoided as it deletes legacy Android tokens on first launch.
- Upgraded `flutter_dotenv` from `^5.2.1` to `^6.0.1` (fully backward compatible; no template code changes needed).
- Raised Dart SDK floor from `>=3.0.0` to `>=3.3.0` to match `connectivity_plus` 7.x requirement.
- Removed obsolete `analysis_options_deprecated_plugins: ignore` from `analysis_options.yaml` — the diagnostic code is no longer recognized by the current Dart analyzer and was causing an `unrecognized_error_code` warning.

## 1.2.1

- Ensured `.env` template asset is explicitly tracked in repository for clean smoke test asset resolution.
- Added `analysis_options_deprecated_plugins: ignore` to scaffolded `analysis_options.yaml` to suppress Dart SDK legacy plugin deprecation warning on Flutter 3.27+.
- Upgraded `custom_lint` to `^0.8.0` to support Dart analyzer 7.5.0+ and prevent AST visitor crashes on Flutter 3.27+ runners.

## 1.2.0

- Upgraded deprecated `.withOpacity(...)` to Flutter 3.27+ `.withValues(alpha: ...)` across design tokens and UI components (`common_utils.dart`, `app_card.dart`, `app_dialog.dart`, `app_textformfield.dart`, `showcase_home_page.dart`).
- Added `Flexible` with `TextOverflow.ellipsis` to `CommonButton` label text to prevent `RenderFlex` overflow on narrow viewports.
- Enhanced `CancelTokenOwner.createNewToken()` to return the freshly instantiated `CancelToken`.
- Explicitly typed `ApiBaseHelper` network calls with `<dynamic>` to safely accommodate primitive and array JSON payloads.
- `post_gen.dart` passes `--android_package_name`, `--ios_bundle_id`, and `--on-conflict overwrite` when invoking `mason make harness`.
- Relaxed Dart SDK constraints to `>=3.0.0 <4.0.0` for broader Flutter 3.x compatibility.

## 1.1.0

- `post_gen.dart` now runs `flutter gen-l10n` after `flutter pub get` to generate localization
  classes from the scaffolded ARB files.
- Added `include_harness` boolean var (default `true`). When true, `post_gen.dart` auto-runs
  `mason make harness --project_name <name>` to scaffold the AI Agent Harness. Non-fatal if it
  fails — prints a note that it can be installed anytime via `mason make harness`.

## 1.0.0

- Initial release: Redux store, Dio HTTP/2 engine with 5-interceptor chain, design tokens,
  localization scaffold, showcase demo, package-name/bundle-id rename on generation.
