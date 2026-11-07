# `project` Brick

Scaffolds a complete, production-grade Flutter architecture onto an **already-created** Flutter project.

**Supported toolchain:** Flutter ≥ 3.47.8 (Dart ≥ 3.13.7): older SDKs ship the `dart:io` eMudhra TLS issue ([GHSA-frr6-h895-5pxp](https://github.com/dart-lang/sdk/security/advisories/GHSA-frr6-h895-5pxp)) and skip the golden-rule lints. On a machine with another Flutter, pin it per project with FVM (`fvm use 3.47.9`). CI tests the minimum (3.47.8) and the latest stable.

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
| `include_harness` | Boolean | Scaffold the [AI Agent Harness](harness.md) (`AGENTS.md`, `CLAUDE.md`, `scripts/agent/`, analyzer-enforced golden rules) | `true` (default) |

---

## 🏗️ What Gets Generated

- **`lib/redux/`**: `AppState`, `AppAction`, reducer, `AppStore` hydration, logging & persistence middleware.
- **`lib/networking/`**: `ApiBaseHelper`, `DioClient` (default `dart:io` adapter; native stack opt-in), 4-interceptor chain, sealed `ApiException`, sealed `ApiResponse<T>`.
- **`lib/resources/`**: Design tokens (`ResColors`, Material 3 `AppTypography` with `.sp` from `adaptive_units`) and `AppBreakpoints` / `WindowSize` (Material 3 window size classes).
- **`lib/utils/`**: Design system & shared components:
  - `widgets/ui/`: Stateless primitives (`AppCard`, `AppEmptyState`, `AppErrorState`, `AppLoadingState`, `AppResponseBuilder`, `AppScaffold`, `AppContentWidth` (readable width on tablets), `CommonButton`, and barrel export `ui_components.dart`).
  - `widgets/view/`: RxDart BLoC-driven components upholding Rule 3 (`AppTextFormField` with `AppTextFormFieldBloc`, `AppDialog` with `AppDialogBloc`).
  - `router/`, `common_utils.dart`, `show_message.dart` toasts, context & string extensions.
- **`lib/features/`**: The home for your actual app features (generated via `mason make bloc`).
- **`lib/services/`**: Notification and device info stubs.
- **`lib/l10n/`**: Localization setup (`app_en.arb`, `app_hi.arb`, `l10n.yaml`).
- **`lib/main.dart`**: Complete entry point with Redux hydration, `MaterialApp.router` on `AppRouter.router` (go_router), `adaptive_units`' `ScreenUtilInit` (phone design below 600dp, 1:1 above, rebuilds on resize), and Toastification. Material widgets come from `material_ui` (`package:material_ui/material_ui.dart`), the package Flutter is moving them into.

---

## ⚙️ Hook Execution Summary

All dependencies (`dio`, `redux`, `rxdart`, `flutter_localizations`, `generate: true`,
dev-deps like `change_app_package_name`, etc.) ship pre-declared in `__brick__/pubspec.yaml` —
no dependency injection happens at generation time.

### `post_gen.dart`
- Verifies `android/` and `ios/` directories exist (confirms `flutter create` was run first).
- Runs `flutter pub get`.
- Runs `flutter gen-l10n` to generate localization classes from the scaffolded ARB files.
- Runs package rename via `change_app_package_name` using `android_package_name`.
- Warns if `ios_bundle_id` differs from `android_package_name` (manual `project.pbxproj` follow-up).
- If `include_harness` is true (default), runs `mason make harness --project_name <name>` to
  scaffold the AI Agent Harness. Non-fatal if it fails — prints a note that it can be installed
  anytime via `mason make harness`.

See [`CHANGELOG.md`](https://github.com/jenilseawind-glitch/Flutter-RxDart-Base/blob/main/bricks/project/CHANGELOG.md) for version history.
