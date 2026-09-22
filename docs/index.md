# Flutter Hybrid Architecture — Mason Workspace

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Mason](https://img.shields.io/badge/Mason-CLI-blue)](https://pub.dev/packages/mason_cli)
[![Redux](https://img.shields.io/badge/Redux-Session_Persistence-764ABC?logo=redux)](https://pub.dev/packages/redux)
[![RxDart](https://img.shields.io/badge/RxDart-Ephemeral_BLoC-D60000)](https://pub.dev/packages/rxdart)
[![Dio](https://img.shields.io/badge/Dio-HTTP2_Interceptors-0175C2)](https://pub.dev/packages/dio)

A production-grade **Mason Workspace** for bootstrapping robust Flutter applications using a high-performance **Hybrid State Management Architecture**:

- **Redux**: Global, persisted session state (Auth Token, User Profile, Locale).
- **RxDart**: Local, per-screen, ephemeral state (Screen BLoCs, API fetches, form controls).

Three bricks (`project`, `bloc`, `harness`) plus a standalone `custom_lint` package
(`redux_rxdart_lints`) that turns the architecture rules into `flutter analyze` errors
instead of prose an agent has to remember.

---

## 🚀 Quick Start

### 1. Install Bricks Globally via Mason CLI (from GitHub)
```bash
mason add -g project --git-url https://github.com/TheJenilDGohel/Flutter-RxDart-Base.git --git-path bricks/project
mason add -g bloc --git-url https://github.com/TheJenilDGohel/Flutter-RxDart-Base.git --git-path bricks/bloc
mason add -g harness --git-url https://github.com/TheJenilDGohel/Flutter-RxDart-Base.git --git-path bricks/harness
```

### 2. Create Your Flutter Project
```bash
flutter create my_app
cd my_app
```

### 3. Bootstrap Architecture (`mason make project`)
From inside your new Flutter project directory:
```bash
mason make project
```
*Prompts for `project_name` (snake_case), `android_package_name` (com.example.myapp), `ios_bundle_id`, and `include_harness` (Y/n, default Y — scaffolds the AI Agent Harness below automatically).*

### 4. Scaffold + Wire Feature Modules
Whenever adding a new screen or feature module, if the harness is installed, one command does it all:
```bash
dart run scripts/agent/wire_route.dart <feature_name> [route_path]
```
Auto-runs `mason make bloc --feature_name <name>` first if the feature doesn't exist, then wires
the route constant + `onGenerateRoute` case. Without the harness, run `mason make bloc` directly
(prompts for `feature_name`) and wire the route by hand.

---

## 🧩 Mason Bricks at a Glance

| Brick | Command | Execution Frequency | Key Responsibilities |
|-------|---------|---------------------|----------------------|
| **`project`** | `mason make project` | **Once** per app | Scaffolds Redux store, Dio HTTP/2 engine with 5 interceptors, `ApiExceptionUIExt`, AppRouter, Toast helper (`ShowMessage`), CommonUtils, ResColors, AppTypography, L10n, and Showcase Demo. |
| **`bloc`** | `mason make bloc` | **Repeatedly** per feature | Generates BLoC, Repo, Model folder, Page, and Content Widget with AI-friendly architecture guidance headers. |
| **`harness`** | `mason make harness` | **Once** per project (auto-run by `project`) | Scaffolds `AGENTS.md`/`CLAUDE.md`, `scripts/agent/wire_route.dart` + `verify.ps1`/`verify.sh`, and wires the `redux_rxdart_lints` custom_lint plugin. See [`bricks/harness/README.md`](bricks/harness/README.md). |

---

## 🏛️ The Core Architectural Rule

> **"Does this data need to survive navigation or a cold app restart?"**
>
> 🟢 **YES $\rightarrow$ `AppStore` (Redux)**
> - Auth JWT / Session Token
> - User Profile Metadata
> - App Locale Preference
>
> 🔵 **NO $\rightarrow$ Feature BLoC (`RxDart`)**
> - Page API Response States
> - Form Fields & UI Toggles
> - Screen-specific Ephemeral Data

---

## 📁 Generated Architecture Overview

```
AGENTS.md                                 # Universal AI agent contract (if include_harness)
CLAUDE.md                                 # @AGENTS.md transclusion (if include_harness)
scripts/agent/                            # wire_route.dart, verify.ps1, verify.sh (if include_harness)
lib/
├── features/                             # Feature-first modules
│   └── showcase/                         # Architecture & UI toolkit showcase page
├── l10n/                                 # Localization ARB files (en, hi)
├── networking/                           # Network engine layer
│   ├── interceptors/                     # 5-step Dio interceptor chain
│   │   ├── connectivity_interceptor.dart # 1. ConnectivityInterceptor (offline check)
│   │   ├── auth_interceptor.dart         # 2. AuthInterceptor (token injection)
│   │   ├── platform_injector_interceptor.dart # 3. PlatformInjectorInterceptor (header/body injection)
│   │   │                                 # 4. RetryInterceptor (from dio_smart_retry package)
│   │   └── error_mapping_interceptor.dart # 5. ErrorMappingInterceptor (DioException mapping)
│   ├── api_base_helper.dart              # Facade with GET/POST/PUT/DELETE & postFormData/putFormData
│   ├── api_constants.dart                # Base URL & endpoint registry
│   ├── api_exceptions.dart               # Sealed ApiException hierarchy (8 subtypes)
│   ├── api_response.dart                 # Sealed ApiResponse<T> with error, retry, and .data accessor
│   ├── cancel_token_owner.dart           # CancelTokenOwner mixin for lifecycle request cancellation
│   └── dio_client.dart                   # HTTP/2 Dio client configuration with 5-step chain
├── redux/                                # Global session persistence layer
│   ├── middleware/                       # Logging & SharedPreferences persistence middleware
│   ├── reducers/                         # Pure reducer with exhaustive switch matching
│   ├── actions.dart                      # Sealed AppAction hierarchy
│   ├── app_state.dart                    # Immutable AppState
│   └── app_store.dart                    # Store hydration & token provider for Dio
├── resources/                            # Design tokens
│   ├── app_typography.dart               # Material 3 Type Scale with ScreenUtil .sp
│   └── res_colors.dart                   # Clean 23-token color palette (with disabled & card tokens)
├── services/                             # Background & device stubs
│   ├── device_info_service.dart          # Device info plugin stub
│   └── notification_service.dart        # Push & local notification stub
├── utils/                                # Universal utilities & routing
│   ├── extensions/                       # error.userMessage, context.l10n, context.textTheme
│   ├── router/                           # AppRouter, Routes registry, navigatorKey
│   ├── widgets/                          # Design system & interactive components
│   │   ├── app_scaffold.dart             # Standard scaffold with AppBar & background
│   │   └── ui/                           # Reusable UI component library
│   │       ├── ui_components.dart        # Barrel export for clean imports
│   │       ├── app_response_builder.dart # Declarative ApiResponse stream builder
│   │       ├── common_button.dart        # Production button with built-in loading spinner
│   │       ├── app_textformfield.dart    # Styled input with password visibility eye toggle
│   │       ├── app_dialog.dart           # Confirmation, status, & async confirm dialogs
│   │       ├── app_card.dart             # Styled card container
│   │       ├── app_empty_state.dart      # Empty state placeholder
│   │       ├── app_error_state.dart      # Error state with retry button
│   │       └── app_loading_state.dart    # Centered loading spinner
│   ├── common_utils.dart                 # hideKeyboard, launcher recipes, showCommonDialog
│   └── show_message.dart                 # ShowMessage.success / error / info / warning toasts
└── main.dart                             # Entry point: Store hydration, AppRouter, ScreenUtil, OverlaySupport
```

---

## ⚡ Key Technical Features & Standards

### 1. Declarative UI Binding (`AppResponseBuilder<T>`)
- Eliminates 30–50 lines of boilerplate `StreamBuilder` + `switch` per screen by declaratively handling `loadingWidget`, `AppErrorState` with retry callback, and typed `builder(context, data)`.

### 2. Form & Action Toolkit (`CommonButton` & `AppTextFormField`)
- **`CommonButton`**: Handles loading state out of the box (disables taps and shows spinner), prefix/suffix icons, and custom styling.
- **`AppTextFormField`**: Form input with labels, hints, prefixes/suffixes, built-in password visibility toggle (`obscureText`), and ScreenUtil responsive scaling.

### 3. Lifecycle-Safe Cancellation (`CancelTokenOwner`)
- BLoCs mix in `CancelTokenOwner` to manage Dio `CancelToken`s. Pending network calls automatically abort on screen `dispose()` or pull-to-refresh without memory leaks.

### 4. Interactive Dialog Shells (`AppDialog`)
- Static helpers `AppDialog.showConfirmation`, `AppDialog.showStatus`, and `AppDialog.showAsyncConfirm` (keeps dialog open with spinner during async mutation).

### 5. Multipart & Form-Data Ready (`ApiBaseHelper`)
- Built-in `postFormData` and `putFormData` with `FormData.fromMap` and `onSendProgress` progress callbacks.

---

## 🛠️ Generated Feature Module Structure (`mason make bloc`)

Running `mason make bloc` creates a self-contained feature folder under `lib/features/`:

```
lib/features/my_feature/
├── bloc/my_feature_bloc.dart          # Clean BLoC with CancelTokenOwner & $ stream convention
├── model/                             # Empty model folder for feature response models
├── repo/my_feature_repo.dart          # Constructor-injectable repository (with CancelToken support)
├── widgets/my_feature_content_widget.dart # Decoupled UI content widget
└── my_feature_page.dart               # Clean StatefulWidget with AppScaffold & ui_components
```

---

## 🤖 AI Agent Harness

`mason make harness` (auto-run by `project` unless `include_harness: false`) scaffolds:

- **`AGENTS.md`** — the architecture contract: golden rules, backend API discovery, deterministic
  commands, git policy. Read natively by Claude Code, Cursor, Copilot, Codex, and 20+ other
  AGENTS.md-compatible tools. `CLAUDE.md` is a 1-line `@AGENTS.md` transclusion.
- **`scripts/agent/wire_route.dart`** — one command scaffolds a feature and wires its route.
- **`scripts/agent/verify.ps1` / `verify.sh`** — deterministic quality gate (format + analyze).
- **`redux_rxdart_lints`** — a [`custom_lint`](packages/redux_rxdart_lints/README.md) plugin wired
  into `pubspec.yaml` / `analysis_options.yaml` automatically. Golden Rules #1 (repo-transport-only),
  #3 (zero `setState`), #4 (zero RxDart outside BLoC) become `flutter analyze` **errors**, not just
  prose an agent has to remember.

See [`bricks/harness/README.md`](bricks/harness/README.md) for details.

---

## 📝 Best Practices & Guidelines

### ✅ DO
- Use `mason make project` once on a freshly created Flutter app.
- Use `mason make bloc` for every new screen or module (or `dart run scripts/agent/wire_route.dart <name>` if the harness is installed — scaffolds + wires the route in one step).
- Use `exception.userFacingMessage` for clean error formatting.
- Access localizations via `context.l10n` and themes via `context.textTheme`.

### ❌ DON'T
- Do **NOT** add screen-specific UI state to Redux.
- Do **NOT** call `flutter create` inside Mason hooks.
- Do **NOT** use hardcoded pixel sizes — use ScreenUtil `.w`, `.h`, `.r`, `.sp`.

---

## 🛠️ Maintaining This Workspace
See [`CONTRIBUTING.md`](CONTRIBUTING.md) for versioning, README-sync, and lint-propagation rules.

## 📄 License
This workspace template is released under the **MIT License**. See [`LICENSE`](LICENSE).
