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

## 1. Architectural Layers & Data Flow

```
┌────────────────────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER (UI / Widgets)                    │
│   • Views (StatefulWidget / StatelessWidget)                            │
│   • Responsive Scaling (flutter_screenutil .w, .h, .r, .sp)             │
│   • Design System Tokens (ResColors, AppTypography, AppScaffold)       │
└───────────────────▲────────────────────────────────▲───────────────────┘
                    │                                │
          Stream Subscription /                    StoreConnector /
          StreamBuilder (RxDart)                   StoreBuilder (Redux)
                    │                                │
┌───────────────────┴──────────────────┐  ┌──────────┴──────────────────┐
│   LOCAL STATE (RxDart, ephemeral)    │  │  GLOBAL STATE (Redux,        │
│   • Feature BLoC (BehaviorSubject)   │  │  persistence-only)           │
│   • Form Validation & UI Lifecycle   │  │  • authToken, userData       │
│   • CompositeSubscription disposal    │  │  • synced to SharedPrefs     │
└───────────────────▲──────────────────┘  └──────────▲──────────────────┘
                    │                                │
                    └────────────────┬───────────────┘
                                     │ Constructor-injected repo calls
┌────────────────────────────────────┴───────────────────────────────────┐
│                       REPOSITORIES & SERVICES                          │
│   • Feature Repositories (injected ApiBaseHelper)                       │
│   • Global Services (NotificationService, DeviceInfoService)          │
└────────────────────────────────────▲───────────────────────────────────┘
                                     │ Requests raw JSON / Throws ApiException
┌────────────────────────────────────┴───────────────────────────────────┐
│                      NETWORKING LAYER (Dio Engine)                     │
│   • ApiBaseHelper (injectable facade constructible for tests)           │
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

### 2.2 Local State: RxDart Stream BLoCs

Feature screens instantiate per-screen BLoCs using RxDart primitives (`BehaviorSubject`, `CompositeSubscription`).

- **Lifecycle**: Created in `initState()`, disposed in `dispose()`.
- **Subscription Safety**: Uses RxDart's native `CompositeSubscription` to collect and cancel reactive stream subscriptions cleanly upon disposal.
- **Thread Safety (`isClosed` Guards)**: Every post-`await` emission is guarded:
  ```dart
  if (!subject.isClosed) {
    subject.add(ApiResponse.completed(data));
  }
  ```
- **Decoupled Exception Mapping**: Handled via `exception.userFacingMessage` extension (`lib/utils/extensions/exception_ext.dart`).

### 2.3 Networking Layer (`lib/networking/`)

The network layer uses a 5-step Dio interceptor pipeline in `lib/networking/dio_client.dart`:

1. **`ConnectivityInterceptor`**: Rejects requests immediately if offline (`NoInternetException`).
2. **`AuthInterceptor`**: Reads `AppStore.authToken` and injects `Authorization: Bearer <token>`.
3. **`PlatformInjectorInterceptor`**: Appends `{"platform": "app"}` or headers to request payloads.
4. **`RetryInterceptor`** *(from `dio_smart_retry`)*: Automatically retries failed requests under transient network conditions (3 retries with exponential backoff).
5. **`ErrorMappingInterceptor`**: Converts raw `DioException` instances into strongly-typed `ApiException` subtypes.

#### Sealed Exception Hierarchy (`ApiException`)
- `NoInternetException`
- `BadRequestException`
- `UnauthorizedException`
- `NotFoundException`
- `ConflictException`
- `RequestTimeoutException`
- `InternalServerErrorException`
- `BusinessLogicException`

#### Sealed Response State Hierarchy (`ApiResponse<T>`)
- `Initial`
- `Loading`
- `Completed(T data)`
- `Error(ApiException exception)`

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
lib/my_feature/
├── bloc/my_feature_bloc.dart          # Clean BLoC skeleton with AI-guidance header
├── repo/my_feature_repo.dart          # Injectable repository (ApiBaseHelper DI)
├── widgets/my_feature_content_widget.dart # Decoupled content widget
└── my_feature_page.dart               # StatefulWidget with standard Scaffold
```

---

## 4. Architectural Tradeoffs & Guarantees

### 🟢 Advantages
1. **Zero Friction Generation**: Generated feature files contain minimal clean skeletons with top-of-file AI-guidance headers, eliminating dummy code deletion overhead.
2. **Unconstrained BLoC Flexibility**: BLoCs are free to expose multiple stream sinks, side-effect triggers (`PublishSubject`), and multi-state streams.
3. **Decoupled UI Formatting**: Exception UI copy mapping is centralized in `ApiExceptionUIExt`.
4. **Compile-Time Exhaustiveness**: Sealed `ApiResponse<T>` and `ApiException` ensure unhandled state bugs are caught at compile time.