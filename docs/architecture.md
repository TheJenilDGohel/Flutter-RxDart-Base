# Flutter Hybrid Architecture Specification

**Architecture Pattern:** Hybrid State Management (Redux Global Session + RxDart Ephemeral BLoCs) with Feature-First Clean Architecture  
**Tooling:** Mason CLI Workspace (`project` & `bloc` bricks)

---

## 0. Executive Architectural Overview

This architecture implements a strict, high-performance **Hybrid State Management** approach in Flutter. 

Before diving into components, internalize the core decision rule:

> ### 💡 The Core State Rule
> **"Does this data need to survive screen navigation or a cold app restart?"**
>
> 🟢 **YES $\rightarrow$ Global State (`AppStore` via Redux)**
> - Auth JWT / Session Token
> - User Profile Metadata
> - App Locale Preference (`en`, `hi`)
> - *Persisted automatically to `SharedPreferences` via middleware.*
>
> 🔵 **NO $\rightarrow$ Local Ephemeral State (`RxDart BLoC`)**
> - Screen API Fetch States (`ApiResponse<T>`)
> - Form Validation & Input Controls
> - UI Toggles, Tabs, & Modals
> - *Created in `initState()`, disposed in `dispose()`, never touches disk.*

---

## 1. Architectural Layers & Dataflow

```text
┌────────────────────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER (UI / Widgets)                    │
│   • Views (StatefulWidget / StatelessWidget)                            │
│   • Declarative Binding: AppResponseBuilder<T> (ApiResponse stream)    │
│   • Form & Action Toolkit: CommonButton (loading state), AppTextFormField│
│   • Overlays: AppDialog (confirm, status, async confirm with spinner)   │
│   • Design System Tokens: ResColors, AppTypography, AppScaffold, AppCard│
│   • Responsive Scaling: flutter_screenutil (.w, .h, .r, .sp)            │
└───────────────────▲────────────────────────────────▲───────────────────┘
                    │                                │
          Stream Subscription /                    StoreConnector /
          AppResponseBuilder (RxDart)              StoreBuilder (Redux)
                    │                                │
┌───────────────────┴──────────────────┐  ┌──────────┴──────────────────┐
│   LOCAL STATE (RxDart, ephemeral)    │  │  GLOBAL STATE (Redux,        │
│   • Feature BLoC (BehaviorSubject)   │  │  persistence-only)           │
│   • CancelTokenOwner lifecycle mixin │  │  • authToken, userData       │
│   • Reactive $ stream convention     │  │  • synced to SharedPrefs     │
│   • CompositeSubscription disposal   │  │                              │
└───────────────────▲──────────────────┘  └──────────▲──────────────────┘
                    │                                │
                    └────────────────┬───────────────┘
                                     │ Constructor-injected repo calls (with CancelToken)
┌────────────────────────────────────┴───────────────────────────────────┐
│                       REPOSITORIES & SERVICES                          │
│   • Feature Repositories (injected ApiBaseHelper)                       │
│   • Global Services (NotificationService, DeviceInfoService)          │
└────────────────────────────────────▲───────────────────────────────────┘
                                     │ Requests raw JSON / Throws ApiException
┌────────────────────────────────────┴───────────────────────────────────┐
│                      NETWORKING LAYER (Dio Engine)                     │
│   • ApiBaseHelper (GET, POST, PUT, DELETE, postFormData, putFormData)  │
│   • CancelTokenOwner (lifecycle-safe request cancellation)             │
│   • DioClient (HTTP/2 Engine with 5-step Interceptor chain)            │
│   • Interceptors: Connectivity → Auth → Platform → Retry → ErrorMap    │
│   • Sealed ApiException Hierarchy (8 subtypes) + safe UI mapping       │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Core Component Deep Dive

### 2.1 Global Session State: Redux-as-Persistence (`lib/redux/`)

Global state is strictly scoped to session persistence data (`authToken`, `userData`, `locale`).

- **`AppState`**: Immutable state container with explicit `.copyWith()` mutation methods.
- **`AppAction`**: Sealed class hierarchy (`SetAuthTokenAction`, `SetUserDataAction`, `SetLocaleAction`, `LogoutAction`).
- **`AppStore`**: Standard Store hydration construct.
  - `main()` awaits `final store = await AppStore.init();` to restore disk state **before** the first frame renders, preventing initial unauthenticated 401 requests and UI flicker.
  - `main()` passes `store` directly to `MyApp(store: store)`.
  - `AppStore.authToken` provides a static getter for non-widget contexts (such as Dio `AuthInterceptor`).
- **`persistenceMiddleware`**: Automatically serializes state changes to `SharedPreferences`.
- **`loggingMiddleware`**: Logs state transitions in debug mode for auditable session tracking.

### 2.2 Local State: RxDart Stream BLoCs with Lifecycle Cancellation

Feature screens instantiate per-screen BLoCs using RxDart primitives (`BehaviorSubject`, `CompositeSubscription`) and the `CancelTokenOwner` mixin.

- **Lifecycle**: Created in `initState()`, disposed in `dispose()`.
- **Stream Naming Convention**: Public streams exposed by BLoCs use the reactive `$` suffix (e.g., `state$`, `data$`).
- **Request Cancellation**: `CancelTokenOwner` mixin ties Dio requests to the BLoC lifecycle. Calling `cancelRequests()` in `dispose()` aborts running network requests cleanly on page pop.
- **Subscription Safety**: Uses RxDart's native `CompositeSubscription` to collect and cancel reactive stream subscriptions cleanly upon disposal.
- **Thread Safety (`isClosed` Guards)**: Every post-`await` emission is guarded:
  ```dart
  if (!subject.isClosed) {
    subject.add(ApiResponse.completed(data));
  }
  ```
- **Declarative UI Binding**: `AppResponseBuilder<T>` binds BLoC streams to the widget tree with automatic loading indicators and error states with retry buttons.
- **Decoupled Exception Mapping**: Handled via `error.userMessage` / `error.userFacingMessage` extension (`lib/utils/extensions/exception_ext.dart`).

---

## 3. Mason Bricks Specification

### 3.1 Workspace Command Summary

```bash
# 1. Bootstrap project architecture (run ONCE on an existing Flutter app)
mason make project

# 2. Generate a feature module (run REPEATEDLY per screen)
mason make bloc
```

### 3.2 Feature Brick Output (`mason make bloc`)

```
lib/features/my_feature/
├── bloc/my_feature_bloc.dart          # Clean BLoC with CancelTokenOwner & $ stream convention
├── model/                             # Empty model directory for feature models
├── repo/my_feature_repo.dart          # Injectable repository (ApiBaseHelper DI + CancelToken)
├── widgets/my_feature_content_widget.dart # Decoupled content widget
└── my_feature_page.dart               # StatefulWidget with AppScaffold & ui_components
```

---

## 4. Architectural Tradeoffs & Guarantees

### 🟢 Advantages
1. **Production-Ready UI Primitives**: Includes `CommonButton` (with built-in loading spinner), `AppTextFormField` (with password visibility toggle), `AppDialog` (with async confirm spinner), and `AppCard`.
2. **Zero-Boilerplate Reactive Streams**: `AppResponseBuilder<T>` removes repetitive `StreamBuilder` + `switch` blocks across screens.
3. **Automatic Request Cancellation**: In-flight HTTP requests are automatically aborted via `CancelTokenOwner` when screens are popped or re-fetched.
4. **Multipart & File Upload Ready**: Built-in `postFormData` and `putFormData` in `ApiBaseHelper`.
5. **Feature-First Clean Architecture**: Scalable, modular `lib/features/` organization.