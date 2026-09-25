# Changelog

## 1.3.1

- Restored `meta` constraint to `^1.16.0` and `intl` constraint to `^0.20.2` to ensure full compatibility with Flutter SDK (`flutter_test` pins `meta: 1.18.0` and `flutter_localizations` pins `intl: 0.20.2`).
- Added `meta` and `intl` to dependency audit skip list to prevent automated bumps beyond Flutter SDK pinned versions.

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
