# Changelog

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
