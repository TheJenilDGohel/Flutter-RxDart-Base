# Changelog

## 1.2.1

- **Fix:** hook SDK floor lowered to Dart ≥ 3.5 (what `mason` needs). 1.2.0 required Dart ≥ 3.13, which broke `mason upgrade` on Flutter ≤ 3.44.

## 1.2.0

- BLoC follows Golden Rule #8: `fetch({bool refresh = false})` (was `fetchData()`), `createNewToken()` before any emission, `refresh` keeps current content visible.
- All emissions go through one `_emit` guard (the loading emit was unguarded and threw after `dispose()`).
- `ErrorResponse` now carries `retry: fetch`. `RequestCancelledException` is ignored. Unexpected errors become `MalformedResponseException` instead of a `BusinessLogicException(e.toString())`, which displayed raw exception text to users.
- Page calls `fetch()`, renders through `AppResponseBuilder`, and supports pull-to-refresh; the content widget receives the parsed model instead of an unused BLoC.
- Repo method renamed to `fetch<Feature>()`, endpoint placeholder uses the feature's param-case path.
- Bloc test suite: 7 tests covering initial, success, error + retry, wrapped errors, cancellation, refresh and dispose.
- `pre_gen` validates and normalises `feature_name`; `post_gen` formats both `lib/` and `test/` output (with a timeout) and points to `wire_route.dart` with the correct camelCase route constant.
- Raised hook SDK floor to Dart `>=3.13.0`; validated against Flutter 3.47.6 / Dart 3.13.5.
- Docs: removed the claims that `project_name` is a declared variable and that `model/` is empty.

## 1.1.0

- Fixed BLoC template import: directly imports `api_response.dart` instead of the UI widget `app_response_builder.dart`.
- Added unit test template in `test/features/<feature>/bloc/<feature>_bloc_test.dart` with `Fake...Repo` mock implementation and stream matcher verifying `InitialResponse`.
- Declared `project_name` variable with default `""` in `brick.yaml` to support non-interactive CLI arguments alongside auto-detection in `pre_gen.dart`.

## 1.0.0

- Initial release: Generates a complete feature module under `lib/features/` with RxDart BLoC, CancelTokenOwner mixin, injectable repository, response model, and page widgets.
