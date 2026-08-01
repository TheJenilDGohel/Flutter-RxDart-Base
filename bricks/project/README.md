# `project` Brick

Scaffolds a complete, production-grade Flutter architecture onto an **already-created** Flutter project.

---

## 📋 Usage

From inside your Flutter project directory (e.g. created via `flutter create my_app`):

```bash
mason make project
```

### Prompted Variables

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `project_name` | String | Project name in `snake_case` (must match `flutter create` name) | `my_app` |
| `android_package_name` | String | Android reverse-domain package identifier | `com.example.myapp` |
| `ios_bundle_id` | String | iOS bundle identifier (defaults to `android_package_name` if blank) | `com.example.myapp` |

---

## 🏗️ What Gets Generated

- **`lib/redux/`**: `AppState`, `AppAction`, reducer, `AppStore` hydration, logging & persistence middleware.
- **`lib/networking/`**: `ApiBaseHelper`, `DioClient`, 5-interceptor chain, sealed `ApiException`, sealed `ApiResponse<T>`.
- **`lib/resources/`**: Design tokens (`ResColors`, Material 3 `AppTypography` with ScreenUtil `.sp`).
- **`lib/utils/`**: `AppScaffold`, core UI states (`AppLoadingState`, `AppErrorState`, `AppEmptyState`), `AppRouter`, `ShowMessage` toasts, `CommonUtils`, context & string extensions.
- **`lib/screens/`**: Interactive architecture showcase demo page.
- **`lib/services/`**: Notification and device info stubs.
- **`lib/l10n/`**: Localization setup (`app_en.arb`, `app_hi.arb`, `l10n.yaml`).
- **`lib/main.dart`**: Complete entry point with Redux hydration, ScreenUtil, AppRouter, and OverlaySupport.

---

## ⚙️ Hook Execution Summary

### `pre_gen.dart`
- Verifies `pubspec.yaml` exists and contains a `flutter:` key.
- Validates `project_name` is strict `snake_case`.
- Cross-checks `project_name` against the `name:` field in `pubspec.yaml`.
- Validates reverse-domain notation for package identifiers.

### `post_gen.dart`
- Runs package rename via `change_app_package_name`.
- Adds 26 unpinned core dependencies via `flutter pub add`.
- Edits `pubspec.yaml` for `flutter_localizations` SDK package and sets `generate: true`.
- Adds dev dependencies (`flutter_native_splash`).
- Runs `flutter pub get`.
