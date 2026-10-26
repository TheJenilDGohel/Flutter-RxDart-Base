# Changelog

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
