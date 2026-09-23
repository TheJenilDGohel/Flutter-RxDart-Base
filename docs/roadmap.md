# Improvement Roadmap

Status: **Phases 0 through 6 Executed & Verified.** Major future horizons (Phases 7 through 10) tracked below for v2.0 evolution as of 2026-09-23.

Paths below are relative to `bricks/project/__brick__/` unless stated otherwise.

## 1. Summary

The core design is sound: sealed `ApiException` / `ApiResponse`, per-screen BLoC with `CancelTokenOwner`, disciplined brick versioning, and an honest `base-gaps.md`. All historical gaps around false claims, missing CI, or unverified brick outputs have been resolved with automated end-to-end smoke testing (`tool/smoke.dart`), link validation (`tool/docs_check.dart`), GitHub Actions CI matrix (`ci.yml`, `version-gate.yml`), and a streamlined AI Agent Harness v1.4.2.

## 2. Findings Resolution

### P0: False claims and broken guarantees (All Resolved)

1. ~~**The lint plugin is orphaned.**~~ *(Fixed: Wired `custom_lint` and `redux_rxdart_lints` into project template's `pubspec.yaml` and `analysis_options.yaml` via mustache `{{#include_harness}}`)*
2. ~~**The base breaks its own Rule 3 (zero `setState`).**~~ *(Fixed: Migrated showcase and form toggles to RxDart BLoC pattern with BehaviorSubjects)*
3. ~~**Freshly generated `bloc` output fails quality gate.**~~ *(Fixed: BLoC template imports `api_response.dart` directly; unit test template includes `Fake...Repo` mock with initial stream matcher; all unused fields/imports removed)*
4. ~~**A cancelled request surfaces as an error.**~~ *(Fixed: Added `RequestCancelledException` and proper cancel token handling)*
5. ~~**Non-object bodies escape as `TypeError`.**~~ *(Fixed: Typed network methods in `ApiBaseHelper` with `<dynamic>` to safely accommodate lists and primitive JSON payloads)*
6. ~~**`ApiResponse` subtype names collide.**~~ *(Fixed: Renamed to `ErrorResponse`, `InitialResponse`, `LoadingResponse`, `SuccessResponse`)*
7. ~~**`AppStore` cannot be re-initialised.**~~ *(Fixed: Removed `final` keyword from `_store` to allow clean re-hydration across test suites and hot restarts)*
8. ~~**The SDK constraint is hard-pinned.**~~ *(Fixed: Relaxed to `>=3.0.0 <4.0.0`)*

### P1: Drift, hygiene, developer experience (All Resolved)

- ~~**Doc drift.**~~ *(Fixed: Cleaned up interceptor names, corrected `AppResponseBuilder`, standardized `ui/` component references, eliminated broken code fences in `architecture.md`, and fixed UTF-8 encoding across all docs)*
- ~~**No tests and no CI.**~~ *(Fixed: Added full GitHub Actions CI matrix in `.github/workflows/ci.yml`, `version-gate.yml`, and `docs.yml`)*
- ~~**Duplicated skill and heavy context.**~~ *(Fixed: Harness 1.4.2 trimmed `CLAUDE.md` to ~48 lines (~500 tokens), using `@.harness/active-context.md` transclusion for lean cross-session memory without context bloat)*
- ~~**`snapshot.dart` and `verify`.**~~ *(Fixed: Quality gates verified; deterministic smoke testing added)*
- ~~**`wire_route.dart`.**~~ *(Fixed: Scaffolds feature and injects routes cleanly with validation)*
- ~~**Deprecated UI methods.**~~ *(Fixed: Replaced `.withOpacity(...)` with Flutter 3.27+ `.withValues(alpha: ...)`)*
- ~~**RenderFlex overflow in buttons.**~~ *(Fixed: Wrapped `CommonButton` label in `Flexible` + `TextOverflow.ellipsis`)*
- ~~**No contributor entry point at repo root.**~~ *(Fixed: Added root `AGENTS.md` and `CLAUDE.md` pointing maintainers and agents to `docs/contributing.md`, `tool/smoke.dart`, and `tool/docs_check.dart`)*

---

## 3. Plan & Implementation Status

- [x] **Phase 0: Baseline Smoke Test**
  - Added `tool/smoke.dart`: Runs `flutter create` -> `mason make project` -> `mason make bloc` -> `dart format` -> `flutter analyze` -> `flutter test` -> `custom_lint`.
  - Resolution: 100% pass on Windows and Linux CI.

- [x] **Phase 1: Template Correctness**
  - Resolved P0 items 3-8: clean generated code, `RequestCancelledException`, list handling in `ApiBaseHelper`, sealed `ApiResponse` subtypes, re-initializable `AppStore`, relaxed SDK constraints.
  - Bumped `project` to `1.2.0` and `bloc` to `1.1.0` with full CHANGELOGs.

- [x] **Phase 2: Analyzer & Custom Lint Enforcement**
  - Wired `custom_lint` and `redux_rxdart_lints` into project templates without fragile hooks.
  - Rules 1, 3, and 4 enforced at compile time.

- [x] **Phase 3: CI & Verification Automation**
  - GitHub Actions matrix running smoke tests, lint package validation, format checks, and analyzer gates.
  - Version-gate workflow ensuring any template change includes a version bump and CHANGELOG entry.
  - `tool/docs_check.dart` validating markdown link integrity across all files.

- [x] **Phase 4: Base DX Upgrades**
  - Isolated BLoC unit testing template with `Fake...Repo` mock and stream matchers.
  - `CancelTokenOwner.createNewToken()` returns the instantiated token for direct assignment.
  - Button text overflow resilience.

- [x] **Phase 5: Harness Diet**
  - Harness 1.4.2 pure template brick with zero hooks.
  - `CLAUDE.md` condensed to ~48 lines (~500 tokens).
  - Cross-session memory handled via `@.harness/active-context.md`.

- [x] **Phase 6: Release Hygiene**
  - Synced all READMEs (`README.md`, `bricks/*/README.md`, `packages/*/README.md`).
  - Added repository root `AGENTS.md` and `CLAUDE.md`.
  - All `docs/` and brick cross-references passing link check.

---

## 4. Pending Horizons & Major Evolution Roadmap (v2.0)

The following major milestones track architectural enhancements, enterprise capabilities, and ecosystem expansions identified from real-world usage and [base-gaps.md](../bricks/harness/__brick__/.agents/skills/flutter-senior-dev/base-gaps.md).

### ⏳ Phase 7: Core Scaffolding Hardening & Template Alignment
*Objective: Eliminate template runtime bugs, decouple generated presentation layers, and resolve networking omissions.*

- [ ] **BLoC Request Cancellation Guard**:
  - Update `{{feature_name}}_bloc.dart` template to explicitly check `e is! RequestCancelledException` in the `ApiException` catch block. Prevent aborted requests from surfacing as UI errors.
  - Wire `retry: fetchData` callback directly into `ApiResponse.error(e, retry: fetchData)` so retry action handlers work automatically.
- [ ] **Decoupled Feature Page & Content Widget**:
  - Update `{{feature_name}}_page.dart` to trigger `_bloc.fetchData()` in `initState()`.
  - Wire `AppResponseBuilder<{{feature_name.pascalCase()}}Model>` into the page body.
  - Refactor `{{feature_name}}_content_widget.dart` to receive pure domain model data (`{{feature_name.pascalCase()}}Model`) instead of holding a direct reference to the BLoC.
- [ ] **Network Method Completeness (`PATCH`)**:
  - Implement HTTP `patch()` in `ApiBaseHelper` for partial resource updates.
- [ ] **Server Error Message Extraction**:
  - Enhance `ErrorMappingInterceptor` to extract backend error messages from `err.response?.data` (e.g. `data['message']` or `data['errors']`) for 400, 401, 404, 409, and 500 status codes rather than falling back to generic Dio messages.
- [ ] **De-duplicate AppScaffold**:
  - Remove redundant `lib/utils/widgets/app_scaffold.dart`, consolidating to `lib/utils/widgets/ui/app_scaffold.dart`.
- [ ] **Comprehensive Unit Test Templates**:
  - Expand `{{feature_name}}_bloc_test.dart` to assert stream emission sequences (`loading` -> `completed`, and error state handling with mocks).

---

### ⏳ Phase 8: Enterprise Session, Security & Resilient Networking
*Objective: Upgrade auth session management to enterprise grade, support streaming/AI workloads, and fix payload injection.*

- [ ] **401 Token Refresh & Auto-Logout Flow**:
  - Implement single-flight token refresh mutex in `AuthInterceptor`.
  - Queue concurrent requests during active refresh and replay upon token renewal.
  - Automatically dispatch `LogoutAction` and trigger route transition on unrecoverable 401/403 session expiration.
- [ ] **Strict Backend Compatibility**:
  - Remove unconditional JSON body mutation in `PlatformInjectorInterceptor` (move `{"platform": "app"}` to custom HTTP headers or opt-in configuration) to avoid 400 schema validation errors on strict backends.
- [ ] **Streaming & LLM Response Support**:
  - Add streaming call to `ApiBaseHelper` using Dio `ResponseType.stream` returning a chunked `Stream<String>` for Server-Sent Events (SSE) and AI model inference.
- [ ] **File Download with Progress Tracking**:
  - Add `download()` method to `ApiBaseHelper` supporting local disk writes and download progress callbacks.
- [ ] **Localized Exception Mapping Expansion**:
  - Expand `ApiExceptionUIExt` and ARB localization files to provide distinct user-facing messages for `BadRequestException`, `NotFoundException`, `ConflictException`, and `RequestTimeoutException`.

---

### ⏳ Phase 9: Dynamic Theming, Responsive Layouts & Offline Queue
*Objective: Multi-theme persistence, cross-device form factor support, and resilient offline capabilities.*

- [ ] **Dynamic Dark Mode & Theme Persistence**:
  - Add `ThemeMode` (light, dark, system) to Redux `AppState` and persist to storage.
  - Introduce dark color tokens in `ResColors` and configure `darkTheme` + `themeMode` in `MaterialApp`.
- [ ] **Adaptive Form Factors & Multi-Screen Support**:
  - Upgrade responsive layout utilities beyond phone dimensions (`Size(375, 812)`).
  - Add responsive layout builders and breakpoint tokens for foldables, tablets, and desktop/web.
- [ ] **Offline-First Mutation Queue**:
  - Integrate local storage abstraction (Drift/Hive) in `lib/services/`.
  - Introduce an offline write queue that serializes mutations during network loss and replays them when connectivity resumes.
- [ ] **Declarative Routing / GoRouter Integration**:
  - Add declarative routing support or migration guide for `go_router` deep-linking and web URL synchronization while retaining automated feature wiring capabilities.

---

### ⏳ Phase 10: Brick Ecosystem Expansion & Custom Lint Guardrails
*Objective: Scaffold common repetitive modules and expand analyzer-enforced architecture rules.*

- [ ] **`model` Brick**:
  - Scaffolds immutable DTOs with defensive JSON type casting (Golden Rule #12) or optional `freezed` / `json_serializable` support.
- [ ] **`list_bloc` / `pagination` Brick**:
  - Scaffolds infinite scrolling, page/cursor pagination, pull-to-refresh, empty states, and debounced live search (`PublishSubject<String>` with `.debounceTime()`).
- [ ] **`auth` Brick**:
  - Scaffolds a complete auth module (Splash, Login, Register, Forgot Password, Secure Token Storage, and Redux session dispatching).
- [ ] **`redux_rxdart_lints` Custom Lint Expansion**:
  - Add analyzer rule enforcing `$` suffix on public BLoC streams (Golden Rule #8).
  - Add analyzer rule enforcing `CancelTokenOwner` mixin on all classes ending with `Bloc`.
  - Add analyzer rule requiring proper resource disposal in `dispose()` (closing subjects, cancelling subscriptions).
  - Add analyzer rule forbidding direct `*Repo` instantiation inside UI presentation widgets.
