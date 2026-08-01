# `bloc` Brick

Generates a minimal, zero-friction feature folder with clean BLoC, repository, empty model directory, content widget, and page skeletons, pre-configured with AI-friendly architecture guidance docstrings.

---

## 📋 Usage

From inside your Flutter project (after bootstrapping with `mason make project`):

```bash
mason make bloc
```

### Prompted Variables

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `feature_name` | String | Feature name in `snake_case` | `user_profile` |

---

## 📁 Output Structure

```
{feature_name}/
├── bloc/{feature_name}_bloc.dart          # Clean RxDart BLoC skeleton with AI-guidance header
├── model/                                 # Empty model directory for feature models
├── repo/{feature_name}_repo.dart          # Injectable repository (ApiBaseHelper DI)
├── widgets/{feature_name}_content_widget.dart # Decoupled content widget
└── {feature_name}_page.dart               # Clean StatefulWidget with standard Scaffold
```

---

## 🏛️ Architectural Guidance Included in Template

1. **AI-Friendly Guidance Headers**: Each generated file contains clear top-of-file docstrings explaining project conventions so AI coding assistants (and developers) write code consistently.
2. **Pre-scaffolded Model Folder**: Includes a clean, empty `model/` folder so you don't have to create directory structures manually when adding feature models.
3. **Constructor Injection**: Repositories use `FeatureRepo({ApiBaseHelper? api}) : _api = api ?? ApiBaseHelper.instance;`.
4. **Flexible Page Layout**: Uses standard Flutter `Scaffold`, making it easy to embed into tabs, bottom sheets, dialogs, or full screens without deleting custom scaffold wrappers.
