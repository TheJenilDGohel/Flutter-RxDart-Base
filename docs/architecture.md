# Flutter Hybrid Architecture Specification

**Architecture Pattern:** Omakase Hybrid State Management (Redux Global Session + RxDart Ephemeral BLoCs + Domain Service Broadcast Streams) with Feature-First Clean Architecture  
**Tooling:** Mason bricks ([`project`](bricks/project.md), [`bloc`](bricks/bloc.md), [`harness`](bricks/harness.md)) and the [`redux_rxdart_lints`](packages/redux_rxdart_lints.md) analyzer plugin

---

## 0. Architectural Philosophy: The Omakase Principle

This repository is built on an **Omakase** ("Chef's Choice") philosophy. 

Rather than presenting developers or AI coding agents with an open buffet of state management libraries, networking wrappers, and directory layouts, this architecture serves a **curated, highly opinionated, fixed menu**:
- **Redux** exclusively for hydrated global session persistence.
- **One RxDart BLoC** per screen for ephemeral UI state and validation.
- **Domain Services** with broadcast streams for cross-screen shared reactive data.
- **Dio** with a fixed, deterministic 4-step interceptor pipeline (default `dart:io` adapter; the native stack is an opt-in recipe).
- **`go_router`** (Router API): one path table for in-app navigation, deep links, App Links and web URLs.
- **Custom analyzer lints** ([`redux_rxdart_lints`](packages/redux_rxdart_lints.md)) that turn architectural deviations into compiler warnings and errors.

### Why Omakase?
1. **Zero Bikeshedding:** Teams stop debating state management libraries, folder structures, or HTTP clients. Conventions are predetermined and consistent across every feature and repository.
2. **AI Agent Determinism:** Frontier coding agents (Claude Code, Cursor, Codex, Gemini CLI) perform best under strict, non-ambiguous constraints. An opinionated AST boundary eliminates hallucinations, ensuring generated features compile and pass lint on the first attempt.
3. **Guaranteed Disposal & Zero Memory Leaks:** Every stateful element has a strictly defined lifecycle owner: screens dispose BLoCs, BLoCs cancel in-flight HTTP requests via `CancelTokenOwner`, and only hydrated session data touches the disk.

---

## 1. The Core State Decision Rule

Before creating any state container, apply this 3-tier decision test:

> **The Core State Rule**
> 
> 🟢 **1. Does this data need to survive a cold app restart or logout?**  
> $\rightarrow$ **Global Session State (`AppState` via Redux)**
> - Auth JWT / Session Token
> - User Profile Metadata
> - App Locale Preference (`en`, `hi`)
> - Theme Mode (`light`, `dark`, `system`)
> - *Persisted to disk by `persistenceMiddleware` (`SharedPreferences`, with optional `FlutterSecureStorage` for credentials).*
>
> 🟡 **2. Does this data need to be shared across multiple screens without touching disk?**  
> $\rightarrow$ **Shared Domain Service (`lib/services/` with Broadcast Stream)**
> - Unread Notification / Bell Count Badge
> - Multi-Step Wizard or Funnel Progress
> - Real-time WebSocket or Server-Sent Event (SSE) Feeds
> - Active Audio / Media Playback Controller
> - *Managed by a domain service class exposing a `StreamController<T>.broadcast()`, subscribed to by relevant BLoCs or UI widgets.*
>
> 🔵 **3. Is this data private to a single screen or user interaction?**  
> $\rightarrow$ **Local Ephemeral State (One RxDart BLoC per Screen)**
> - Screen API Fetch States (`ApiResponse<T>`)
> - Form Inputs, Text Validation, and Submission Spinners
> - Search Queries, Filters, Tabs, and Modals
> - *Created in `initState()`, disposed in `dispose()`, never touches disk.*

---

## 2. Architectural Layers & Dataflow

```text
┌────────────────────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER (UI / Widgets)                    │
│   • Views (StatefulWidget / StatelessWidget in lib/features/)          │
│   • Declarative Binding: AppResponseBuilder<T> (ApiResponse stream)    │
│   • Navigation: AppRouter.router (go_router) + Routes path constants  │
│   • Design System Tokens: ResColors, AppTypography, AppScaffold, AppCard│
│   • Responsive Scaling: adaptive_units (.w, .h, .r, .sp; 1:1 ≥600dp)   │
└───────────────────▲────────────────────▲───────────────────▲───────────┘
                    │                    │                   │
          Stream Subscription /     Broadcast Stream    StoreConnector /
          AppResponseBuilder         (lib/services/)    StoreBuilder (Redux)
                    │                    │                   │
┌───────────────────┴──────────────────┐ │   ┌───────────────┴───────────┐
│   LOCAL STATE (RxDart, ephemeral)    │ │   │  GLOBAL STATE (Redux,     │
│   • Feature BLoC (BehaviorSubject)   │ │   │  persistence-only)        │
│   • CancelTokenOwner lifecycle mixin │ │   │  • authToken, userData    │
│   • Reactive $ stream convention     │ │   │  • locale, themeMode      │
│   • CompositeSubscription disposal   │ │   │  • queued disk persistence│
└───────────────────▲──────────────────┘ │   └───────────────▲───────────┘
                    │                    │                   │
                    │                    │    Dispatches on session change
                    │                    │                   │
┌───────────────────┴────────────────────┴───────────────────┴───────────┐
│                       REPOSITORIES & SERVICES                          │
│   • Feature Repositories: transport only, return raw Map/JSON          │
│   • Domain Services (lib/services/): singleton/factory broadcast state │
│   • Global Services: DeviceInfoService, NotificationService            │
└────────────────────────────────────▲───────────────────────────────────┘
                                     │ Requests raw JSON / Throws ApiException
┌────────────────────────────────────┴───────────────────────────────────┐
│                      NETWORKING LAYER (Dio Engine)                     │
│   • ApiBaseHelper (GET, POST, PUT, DELETE, postFormData, putFormData)  │
│   • CancelTokenOwner (lifecycle-safe request cancellation)             │
│   • DioClient (dart:io adapter), 4-step interceptor pipeline:          │
│     1. AuthInterceptor (attaches bearer token to BASE_URL host)        │
│     2. PlatformInjectorInterceptor (injects {"platform": "app"})       │
│     3. RetryInterceptor (backoff for idempotent methods only)          │
│     4. ErrorMappingInterceptor (maps DioException -> ApiException)     │
│   • Sealed ApiException hierarchy (13 subtypes) + safe user messaging │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Core Component Deep Dive

### 3.1 Global Session State: Redux-as-Persistence (`lib/redux/`)

Global state is strictly scoped to session persistence data (`authToken`, `userData`, `locale`). It is **never** used as a general-purpose state store for feature screens.

- **`AppState`**: Immutable state container with explicit `.copyWith()` methods.
- **`AppAction`**: Sealed class hierarchy (`SetAuthTokenAction`, `SetUserDataAction`, `SetLocaleAction`, `LogoutAction`).
- **`AppStore`**: Standard store hydration and access:
  - `main()` awaits `final store = await AppStore.init();` to restore disk state **before** `runApp()`. This eliminates initial unauthenticated 401 redirects and UI flicker.
  - `AppStore.authToken` provides a static convenience getter for non-widget contexts (such as `AuthInterceptor`).
  - **Never-Crash Startup Guarantee:** If disk storage is corrupted (e.g., following an OS backup restore or Keystore invalidation), `AppStore._hydrate()` catches the exception, deletes corrupted keys, logs a diagnostic warning, and returns a clean, signed-out `AppState(locale: locale)`. Launch is guaranteed never to crash on startup.
- **`persistenceMiddleware`**: Serializes state changes to disk. Writes are queued sequentially via an internal `_queue` to ensure deterministic write ordering (e.g., a fast `LogoutAction` will never be overwritten by a pending `SetAuthTokenAction`).

### 3.2 Cross-Screen Reactive State: Domain Services (`lib/services/`)

When multiple screens need real-time, shared reactive state without disk persistence, use a **Domain Service**:
- **Location:** Placed under `lib/services/<domain>/` (e.g., `lib/services/notifications/bell_count.dart`).
- **Pattern:** Class exposing a private constructor singleton or injectable instance, holding an internal value and a `StreamController<T>.broadcast()` stream.
- **Consumption:** Pages or BLoCs listen to the service stream (`BellCount.instance.count`) and update their local state or UI accordingly.

### 3.3 Local Screen State: RxDart Stream BLoCs (`lib/features/`)

Feature screens instantiate per-screen BLoCs using RxDart primitives (`BehaviorSubject`, `PublishSubject`, `CompositeSubscription`) and the `CancelTokenOwner` mixin.

- **Lifecycle:** Created in `initState()`, disposed in `dispose()`.
- **Stream Naming Convention:** Public streams exposed by BLoCs use the reactive `$` suffix (e.g., `data$`, `state$`). Widgets consume plain Dart `Stream<T>` and never import RxDart.
- **Request Cancellation:** The `CancelTokenOwner` mixin ties Dio HTTP requests to the BLoC lifecycle. Calling `cancelRequests()` in `dispose()` cleanly aborts running network calls when a screen is popped.
- **Subscription Safety:** Uses `CompositeSubscription subscriptions` to collect reactive subscriptions and cancel them cleanly on disposal.
- **Emit Guards:** Every post-`await` emission is guarded with `if (!_data.isClosed)` to prevent post-disposal state errors.

### 3.4 Presentation Layer & Declarative Binding: `AppResponseBuilder<T>`

`AppResponseBuilder<T>` is the core widget that binds a BLoC's `Stream<ApiResponse<T>>` to the widget tree:
- **Contract:**
  ```dart
  AppResponseBuilder<MyFeatureModel>(
    stream: _bloc.data$,
    onLoading: (context) => const Center(child: CircularProgressIndicator()), // optional custom spinner
    onError: (context, error, retry) => CustomErrorWidget(error: error, retry: retry), // optional
    builder: (context, data) => MyFeatureContentWidget(data: data),
  )
  ```
- **Loading State:** Automatically renders a centered progress indicator during `ApiResponse.loading()` unless a custom `onLoading` builder is provided.
- **Error State & Retries:** During `ApiResponse.error()`, automatically renders a friendly error banner with a "Retry" button linked to the BLoC's `fetch` method.
- **Safe Messaging:** Calls `error.userFacingMessage(context)` so internal technical strings or stack traces are never exposed to users.

### 3.5 Declarative Routing: `AppRouter` & `Routes` (`lib/utils/router/`)

Navigation goes through one `GoRouter` (`go_router`, maintained by the Flutter team on the Router API), so in-app navigation, Android App Links, iOS Universal Links, web URLs and predictive back all resolve the same paths:
- **`AppRouter` (`lib/utils/router/app_router.dart`):** `static final GoRouter router` (passed to `MaterialApp.router`), one `GoRoute` per path, an `errorBuilder` that opens the start screen for unknown links, and `navigatorKey` for navigation that starts outside the widget tree.
- **Route Constants (`lib/utils/router/routes.dart`):** Path constants (e.g. `Routes.showcase`, `Routes.profile`).
- **Parameters:** Ids travel in the path or query (`/orders/:id`, read with `state.pathParameters`) so every screen also opens from a link; `extra` is reserved for objects no link ever carries.
- **Feature wiring:** `wire_route.dart` adds the constant and a `GoRoute` above the `// wire_route:routes` marker. Apps generated before project 2.0.0 keep `onGenerateRoute`, and the script still wires those.

### 3.6 Networking Engine & The 13 `ApiException` Subtypes

All network traffic passes through `ApiBaseHelper` and `DioClient`. Network exceptions are caught by `ErrorMappingInterceptor` and mapped into a sealed `ApiException` hierarchy:

| Exception Subtype | HTTP Status / Source | Behavior & UI Handling |
| :--- | :--- | :--- |
| `NoInternetException` | Request could not connect | Offline banner with retry |
| `BadRequestException` | HTTP 400 | Generic invalid request error |
| `UnauthorizedException` | HTTP 401 | `AuthInterceptor` triggers silent refresh or automatic logout |
| `ForbiddenException` | HTTP 403 | Access denied message |
| `NotFoundException` | HTTP 404 | Resource not found message |
| `ConflictException` | HTTP 409 | Duplicate/conflict resource error |
| `ValidationException` | HTTP 422 | Server validation failure details |
| `TooManyRequestsException` | HTTP 429 | Rate limit backoff prompt |
| `RequestTimeoutException` | HTTP 408 / Socket Timeout | Connection timeout with retry |
| `InternalServerErrorException` | HTTP 5xx | Server-side error banner with retry |
| `BusinessLogicException` | HTTP 200 with `status: false` | **Only exception** whose `.message` is safe to display verbatim in the UI |
| `MalformedResponseException` | JSON parsing failure | Guarded error state; logs parsing failure |
| `RequestCancelledException` | Client navigation / refresh | **Silently ignored** by BLoCs (screen was popped or replaced) |

---

## 4. Mason Bricks Specification

### 4.1 CLI Scaffolding Commands

```bash
# 1. Bootstrap project architecture (run ONCE on a new Flutter app)
mason make project \
  --project_name my_app \
  --android_package_name com.example.myapp \
  --ios_bundle_id com.example.myapp \
  --include_harness true \
  --include_secure_storage false

# 2. Generate a feature module (run REPEATEDLY per screen)
mason make bloc --feature_name user_profile

# With the AI harness: scaffold feature and wire its route in one step
dart scripts/agent/wire_route.dart user_profile
```

### 4.2 Feature Brick Output (`mason make bloc`)

```
lib/features/user_profile/
├── bloc/user_profile_bloc.dart          # fetch({refresh}), data$ stream, CancelTokenOwner, guarded emits
├── model/user_profile_model.dart        # defensive fromJson
├── repo/user_profile_repo.dart          # transport only: ApiBaseHelper call, raw Map, CancelToken
├── widgets/user_profile_content_widget.dart # stateless view receiving parsed model
└── user_profile_page.dart               # owns BLoC: Scaffold + RefreshIndicator + AppResponseBuilder
test/features/user_profile/bloc/user_profile_bloc_test.dart # 7 automated unit tests
```

### 4.3 Automated BLoC Test Suite
Every generated BLoC includes 7 passing unit tests verifying architectural invariants:
1. Initial state is `InitialResponse`.
2. `fetch()` emits `LoadingResponse` then `SuccessResponse` with parsed model.
3. `ApiException` emits `ErrorResponse` with a working retry closure.
4. Unexpected runtime exceptions are wrapped as `MalformedResponseException`.
5. `RequestCancelledException` is silently ignored without emitting an error state.
6. `fetch(refresh: true)` keeps existing content visible during pull-to-refresh.
7. No emissions or crashes occur if network requests resolve after BLoC disposal.

---

## 5. Alternatives Considered

Under the Omakase design philosophy, alternative patterns were evaluated and rejected for specific technical reasons:

| Layer | Candidate Considered | Why Rejected in Favor of Omakase Choice |
| :--- | :--- | :--- |
| **Global Session** | **HydratedBloc** | Combines logic and persistence into a single construct; invites developers to dump transient UI state into the persistent store, causing storage bloat and slow restarts. Redux strictly limits persistence to session keys. |
| **Global Session** | **Riverpod** | Highly flexible with autodispose and family modifiers, but lacks compile-time architectural guardrails. In AI-assisted workflows, agents easily create circular provider dependencies or leaky global singletons. |
| **Screen State** | **`flutter_bloc` (Cubit / Bloc)** | Relies on extensive subclassing (`BlocProvider`, `BlocBuilder`, `BlocConsumer`, event classes). RxDart BLoCs use native Dart `Stream` and `BehaviorSubject` with zero framework lock-in and minimal boilerplate. |
| **Screen State** | **Signals / ValueNotifier** | Excellent for synchronous reactivity, but requires bespoke handling for asynchronous cancellation, debounced search, composite stream cancellation, and stream retry pipelines where RxDart operators (`debounceTime`, `switchMap`) excel. |
| **Networking** | **`package:http`** | Lacks built-in request cancellation (`CancelToken`), interceptor chaining (auth injection, retry backoff, error mapping), and form-data multipart upload coordination provided out-of-the-box by Dio. |
| **Routing** | **`auto_route`** | Code generation (`build_runner`) on every route change slows the agent loop and cannot be wired by `wire_route.dart`. `go_router` gives the same deep-link support with plain Dart. |

---

## 6. Architectural Trade-offs & Limitations

### 🟢 Advantages
1. **Zero Bikeshedding:** Architecture is fixed, complete, and automated. Developers focus 100% of their effort on business logic and UI.
2. **Analyzer-Enforced Guardrails:** The [`redux_rxdart_lints`](packages/redux_rxdart_lints.md) package turns architectural rules into IDE errors (no `setState` in features, no RxDart in widgets, no JSON parsing in repos).
3. **Deterministic AI Agent Pairing:** Agents scaffold complete, compilable, lint-clean features with full test coverage using a single CLI command (`wire_route.dart`).
4. **Lifecycle-Safe Networking:** Every network request is tied to a `CancelToken` and aborted when the screen is dismissed.

### 🔴 Known Limitations & Non-Goals
1. **Not Built for Micro-Frontends:** This template is optimized for cohesive mobile apps. Decoupled micro-app modularization with independent dependency injection is out of scope.
2. **Relational Client-Side Caching Requires Add-on:** The base template provides HTTP networking and session persistence. Offline-first apps requiring relational caching or outbox sync must integrate an encrypted local database (such as Drift/SQLite) alongside repository mixins.
3. **Single BLoC Per Screen Principle:** Screens with extreme sub-tree complexity (e.g., a dashboard with 10 independent asynchronous cards) must either decompose into child feature pages or use repository broadcast streams; stacking multiple BLoCs inside one screen is discouraged.
