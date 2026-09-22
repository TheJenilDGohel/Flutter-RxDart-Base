# redux_rxdart_lints

`custom_lint` plugin enforcing the Redux+RxDart+Dio architecture golden rules
documented in the harness's `AGENTS.md`, at `dart analyze` time instead of
relying on an AI agent (or human) remembering them.

## Rules

| Rule | Golden Rule | Flags |
|---|---|---|
| `no_rxdart_in_ui` | #4 Zero RxDart Outside BLoC | `import 'package:rxdart/...'` outside `bloc/`, `_bloc.dart`, `utils/`, `redux/` |
| `no_setstate_in_widget` | #3 Zero setState | any `setState(...)` call |
| `repo_transport_only` | #1 Repository is Transport ONLY | `.fromJson(...)` call inside a `repo/` file |

## Usage

In the consuming Flutter project's `pubspec.yaml`:

```yaml
dev_dependencies:
  custom_lint: ^0.7.0
  redux_rxdart_lints:
    git:
      url: https://github.com/TheJenilDGohel/Flutter-RxDart-Base.git
      path: packages/redux_rxdart_lints
```

In `analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - custom_lint
```

Then `dart pub get` and run `dart analyze` (or `flutter analyze`) as usual —
`scripts/agent/verify.ps1` / `verify.sh` already invoke it.
