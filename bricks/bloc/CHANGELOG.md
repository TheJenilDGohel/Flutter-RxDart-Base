# Changelog

## 1.1.0

- Fixed BLoC template import: directly imports `api_response.dart` instead of the UI widget `app_response_builder.dart`.
- Added unit test template in `test/features/{{feature_name}}/bloc/{{feature_name}}_bloc_test.dart` with `Fake...Repo` mock implementation and stream matcher verifying `InitialResponse`.
- Declared `project_name` variable with default `""` in `brick.yaml` to support non-interactive CLI arguments alongside auto-detection in `pre_gen.dart`.

## 1.0.0

- Initial release: Generates a complete feature module under `lib/features/` with RxDart BLoC, CancelTokenOwner mixin, injectable repository, response model, and page widgets.
