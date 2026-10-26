# `bloc` Brick

Generates a feature folder under `lib/features/` that already follows the Golden Rules: an RxDart BLoC with `fetch({bool refresh})`, a transport-only repository, a defensively parsed model, a page bound through `AppResponseBuilder`, and unit tests for every state transition.

---

## 📋 Usage

From inside your Flutter project root (after bootstrapping with `mason make project`):

```bash
mason make bloc --feature_name user_profile
```

### Variables

| Variable | Type | Description | Default / Behavior |
|----------|------|-------------|--------------------|
| `feature_name` | String | Feature name; normalised to `snake_case` and validated before any file is written | *Required* |

`project_name` is not a prompt: the `pre_gen` hook reads it from `pubspec.yaml`, so the brick runs non-interactively for CI and AI agents. Run it from the project root.

---

## 📁 Output Structure

```
lib/features/{feature_name}/
├── bloc/{feature_name}_bloc.dart              # RxDart BLoC: fetch({refresh}), guarded emits, retry, CancelTokenOwner
├── model/{feature_name}_model.dart            # Response model with defensive fromJson (Golden Rule #12)
├── repo/{feature_name}_repo.dart              # Transport-only repository (ApiBaseHelper DI + CancelToken)
├── widgets/{feature_name}_content_widget.dart # Pure widget rendering the parsed model
└── {feature_name}_page.dart                   # Owns the BLoC; AppResponseBuilder + pull-to-refresh
test/features/{feature_name}/bloc/
└── {feature_name}_bloc_test.dart              # 7 tests: success, error+retry, wrapped errors, cancel, refresh, dispose
```

All generated files are formatted by the `post_gen` hook, so the harness quality gate passes on a fresh feature.

---

## 🏛️ What the Template Demonstrates

1. **Fetch pattern (Golden Rule #8)**: `createNewToken()` first, so a newer fetch cancels the older one; `refresh: true` keeps current content on screen.
2. **Safe emissions**: every state goes through one `_emit` guard, so nothing is added after `dispose()`.
3. **Errors**: `ApiException` → `ErrorResponse` with `retry: fetch`; cancellations are ignored; unexpected errors are wrapped in `MalformedResponseException` and never shown raw to users.
4. **Constructor injection**: `FeatureRepo({ApiBaseHelper? api})` and `FeatureBloc({FeatureRepo? repo})` for tests.
5. **UI binding**: the page renders through `AppResponseBuilder` (loading, error with retry, content) with zero `setState`.

---

## 🔌 Wiring the Route

If the [`harness` brick](harness.md) is installed, skip `mason make bloc` entirely and
run one command instead — it scaffolds the feature (if missing) *and* wires the route:

```bash
dart run scripts/agent/wire_route.dart <feature_name> [route_path]
```

---

See [`CHANGELOG.md`](https://github.com/jenilseawind-glitch/Flutter-RxDart-Base/blob/main/bricks/bloc/CHANGELOG.md) for version history.
