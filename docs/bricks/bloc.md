# `bloc` Brick

Generates a minimal, zero-friction feature folder under `lib/features/` with clean BLoC, repository, empty model directory, content widget, and page skeletons, pre-configured with architecture guidance docstrings.

---

## 📋 Usage

From inside your Flutter project root (after bootstrapping with `mason make project`):

```bash
mason make bloc
```

### Prompted Variables

| Variable | Type | Description | Default / Behavior |
|----------|------|-------------|--------------------|
| `feature_name` | String | Feature name in `snake_case` (e.g. `user_profile`) | *Required* |
| `project_name` | String | Project name in `snake_case` | Auto-detected from `pubspec.yaml` if left blank |

---

## 📁 Output Structure

```
lib/features/{feature_name}/
├── bloc/{feature_name}_bloc.dart          # Clean RxDart BLoC with CancelTokenOwner & $ stream convention
├── model/                                 # Empty model directory for feature models (.gitkeep)
├── repo/{feature_name}_repo.dart          # Injectable repository (ApiBaseHelper DI + CancelToken)
├── widgets/{feature_name}_content_widget.dart # Decoupled dumb UI content widget
└── {feature_name}_page.dart               # StatefulWidget managing BLoC lifecycle with Scaffold
test/features/{feature_name}/bloc/
└── {feature_name}_bloc_test.dart          # Unit test skeleton with Fake repo and reactive stream matchers
```

---

## 🏛️ Architectural Guidance Included in Template

1. **Auto-Detection**: The `pre_gen` hook automatically detects the `project_name` from your root `pubspec.yaml`, enabling non-interactive execution for CI/CD and AI agents.
2. **Lifecycle Safety**: BLoC mixes in `CancelTokenOwner` to auto-abort pending HTTP requests in `dispose()`.
3. **Pre-scaffolded Model Folder**: Includes an empty `model/` folder so feature models can be added immediately.
4. **Constructor Injection**: Repositories use `FeatureRepo({ApiBaseHelper? api}) : _api = api ?? ApiBaseHelper.instance;` for easy unit testing.
5. **Scaffold Shell**: Uses `Scaffold` with consistent styling, app bar title, and design tokens.
6. **Isolated Unit Testing**: Scaffolded unit tests in `test/features/` test state emission without making actual HTTP requests.

---

## 🔌 Wiring the Route

If the [`harness` brick](harness.md) is installed, skip `mason make bloc` entirely and
run one command instead — it scaffolds the feature (if missing) *and* wires the route:

```bash
dart run scripts/agent/wire_route.dart <feature_name> [route_path]
```

---

See [`CHANGELOG.md`](https://github.com/TheJenilDGohel/Flutter-RxDart-Base/blob/main/bricks/bloc/CHANGELOG.md) for version history.
