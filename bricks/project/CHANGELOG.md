# Changelog

## 1.1.0

- `post_gen.dart` now runs `flutter gen-l10n` after `flutter pub get` to generate localization
  classes from the scaffolded ARB files.
- Added `include_harness` boolean var (default `true`). When true, `post_gen.dart` auto-runs
  `mason make harness --project_name <name>` to scaffold the AI Agent Harness. Non-fatal if it
  fails — prints a note that it can be installed anytime via `mason make harness`.

## 1.0.0

- Initial release: Redux store, Dio HTTP/2 engine with 5-interceptor chain, design tokens,
  localization scaffold, showcase demo, package-name/bundle-id rename on generation.
