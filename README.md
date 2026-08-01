# Flutter Hybrid Architecture — Mason Workspace

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Mason](https://img.shields.io/badge/Mason-CLI-blue)](https://pub.dev/packages/mason_cli)
[![Redux](https://img.shields.io/badge/Redux-Session_Persistence-764ABC?logo=redux)](https://pub.dev/packages/redux)
[![RxDart](https://img.shields.io/badge/RxDart-Ephemeral_BLoC-D60000)](https://pub.dev/packages/rxdart)
[![Dio](https://img.shields.io/badge/Dio-HTTP2_Interceptors-0175C2)](https://pub.dev/packages/dio)

A production-grade, two-brick **Mason Workspace** for bootstrapping robust Flutter applications using a high-performance **Hybrid State Management Architecture**:

- **Redux**: Global, persisted session state (Auth Token, User Profile, Locale).
- **RxDart**: Local, per-screen, ephemeral state (Screen BLoCs, API fetches, form controls).

---

## 🚀 Quick Start

### 1. Register Bricks in Workspace Root
From the root of this Mason workspace:
```bash
mason get
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
*Prompts for `project_name` (snake_case), `android_package_name` (com.example.myapp), and `ios_bundle_id`.*

### 4. Scaffold Feature Modules (`mason make bloc`)
Whenever adding a new screen or feature module:
```bash
mason make bloc
```
*Prompts for `feature_name` (e.g. `user_profile`, `settings`).*

---

## 🧩 Mason Bricks at a Glance

| Brick | Command | Execution Frequency | Key Responsibilities |
|-------|---------|---------------------|----------------------|
| **`project`** | `mason make project` | **Once** per app | Scaffolds Redux store, Dio HTTP/2 engine with 5 interceptors, `ApiExceptionUIExt`, AppRouter, Toast helper (`ShowMessage`), CommonUtils, ResColors, AppTypography, L10n, and Showcase Demo. |
| **`bloc`** | `mason make bloc` | **Repeatedly** per feature | Generates BLoC, Repo, Page, and Content Widget with AI-friendly architecture guidance headers. |

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
lib/
├── l10n/                                 # Localization ARB files (en, hi)
├── networking/                           # Network engine layer
│   ├── interceptors/                     # 5-step Dio interceptor chain
│   │   ├── connectivity_interceptor.dart # 1. ConnectivityInterceptor (offline check)
│   │   ├── auth_interceptor.dart         # 2. AuthInterceptor (token injection)
│   │   ├── platform_injector_interceptor.dart # 3. PlatformInjectorInterceptor (header/body injection)
│   │   │                                 # 4. RetryInterceptor (from dio_smart_retry package)
│   │   └── error_mapping_interceptor.dart # 5. ErrorMappingInterceptor (DioException mapping)
│   ├── api_base_helper.dart              # Testable API facade
│   ├── api_constants.dart                # Base URL & endpoint registry
│   ├── api_exceptions.dart               # Sealed ApiException hierarchy (8 subtypes)
│   ├── api_response.dart                 # Sealed ApiResponse<T> (Initial, Loading, Completed, Error)
│   └── dio_client.dart                   # HTTP/2 Dio client configuration with 5-step chain
├── redux/                                # Global session persistence layer
│   ├── middleware/                       # Logging & SharedPreferences persistence middleware
│   ├── reducers/                         # Pure reducer with exhaustive switch matching
│   ├── actions.dart                      # Sealed AppAction hierarchy
│   ├── app_state.dart                    # Immutable AppState
│   └── app_store.dart                    # Store hydration & token provider for Dio
├── resources/                            # Design tokens
│   ├── app_typography.dart               # Material 3 Type Scale with ScreenUtil .sp
│   └── res_colors.dart                   # Clean 20-token color palette
├── screens/                              # App screens & showcase demo
│   └── non_auth/showcase/                # Interactive architecture showcase page
├── services/                             # Background & device stubs
│   ├── device_info_service.dart          # Device info plugin stub
│   └── notification_service.dart        # Push & local notification stub
├── utils/                                # Universal utilities & routing
│   ├── extensions/                       # exception.userFacingMessage, context.l10n, context.textTheme
│   ├── router/                           # AppRouter, Routes registry, navigatorKey
│   ├── widgets/                          # AppScaffold, AppLoadingState, AppErrorState, AppEmptyState
│   ├── common_utils.dart                 # hideKeyboard, url launchers, showCommonDialog
│   └── show_message.dart                 # ShowMessage.success / error / info / warning toasts
└── main.dart                             # Entry point: Store hydration, AppRouter, ScreenUtil, OverlaySupport
```

---

## ⚡ Key Technical Features & Standards

### 1. Decoupled UI Error Mapping (`ApiExceptionUIExt`)
- Centralized `exception.userFacingMessage` extension formats error copy cleanly without requiring artificial BaseBloc inheritance constraints.

### 2. Zero Friction AI-Guided Feature Generation
- Brick templates scaffold clean, minimal skeletons with top-of-file architecture guidance docstrings so developers and AI coding assistants immediately understand project conventions when generating feature code.

### 3. Sealed Hierarchy & Exhaustive Pattern Matching
- **`ApiResponse<T>`**: `Initial`, `Loading`, `Completed(T data)`, and `Error(ApiException exception)`.
- **`ApiException`**: `NoInternet`, `BadRequest`, `Unauthorized`, `NotFound`, `Conflict`, `RequestTimeout`, `InternalServerError`, and `BusinessLogicException`.

---

## 🛠️ Generated Feature Module Structure (`mason make bloc`)

Running `mason make bloc` creates a self-contained feature folder under `lib/`:

```
lib/my_feature/
├── bloc/my_feature_bloc.dart          # Clean BLoC skeleton with AI-guidance header
├── repo/my_feature_repo.dart          # Constructor-injectable repository
├── widgets/my_feature_content_widget.dart # Decoupled UI content widget
└── my_feature_page.dart               # Clean StatefulWidget with standard Scaffold
```

---

## 📝 Best Practices & Guidelines

### ✅ DO
- Use `mason make project` once on a freshly created Flutter app.
- Use `mason make bloc` for every new screen or module.
- Use `exception.userFacingMessage` for clean error formatting.
- Access localizations via `context.l10n` and themes via `context.textTheme`.

### ❌ DON'T
- Do **NOT** add screen-specific UI state to Redux.
- Do **NOT** call `flutter create` inside Mason hooks.
- Do **NOT** use hardcoded pixel sizes — use ScreenUtil `.w`, `.h`, `.r`, `.sp`.

---

## 📄 License
This workspace template is released under the **MIT License**.
