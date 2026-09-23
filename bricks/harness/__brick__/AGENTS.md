# AI Agent Contract & Architecture Standards

## 1. Architecture: Hybrid Redux + RxDart + Dio
- **Redux (Global)**: App-wide session, auth token, user profile, persistence.
- **RxDart BLoC (Ephemeral)**: Screen-level state, forms, pagination, searches.
- **Dio (Networking)**: HTTP/2 with interceptor chain (`AuthInterceptor`, `ErrorMappingInterceptor`).

## 2. Inviolable Golden Rules
1. **Repository is Transport ONLY**:
   - MUST ONLY call `ApiBaseHelper` and return raw `Map<String, dynamic>`.
   - ❌ NEVER call `Model.fromJson` in Repository.
2. **BLoC is Business Logic & State Owner**:
   - Awaits raw response from repo, parses via `Model.fromJson(json)`, catches errors, and emits `ApiResponse<T>` (`LoadingResponse`, `SuccessResponse`, `ErrorResponse`).
   - Use `e.userMessage` from `exception_ext.dart` for UI errors.
3. **Zero `setState`**: Strictly forbidden in all widgets. Use stream builders (`AppResponseBuilder`, `StreamBuilder`).
4. **Zero RxDart Outside BLoC**:
   - UI widgets MUST NEVER import or use RxDart (`BehaviorSubject`, `PublishSubject`).
   - UI widgets ONLY consume standard Dart `Stream<T>` / `ApiResponse<T>`.
5. **Rule of 2 for Widgets**:
   - If a widget or layout is used in $\ge 2$ places, extract it to `utils/widgets/ui/`.
   - If an existing widget can be reused with parameter tweaks, reuse it. NEVER duplicate widget trees.
6. **Universal Presentation**:
   - Baseline is standard `Scaffold` (do not force specialized wrappers unless requested).
7. **Form Pattern B (TextEditingController)**:
   - `StatefulWidget` owns and disposes `TextEditingController`s.
   - Pass string values directly to BLoC methods: `_bloc.submit(email: _emailCtrl.text)`.
   - BLoC streams drive loading spinners and error banners.
8. **Concurrency & Fetch (Pattern A)**:
   - Signature: `Future<void> fetch({bool refresh = false}) async`.
   - Always call `createNewToken()` at start of fetch to cancel prior requests.
   - For live search: use `PublishSubject<String>` with `.debounceTime(Duration(milliseconds: 300)).distinct()`.
9. **One-Off UI Events (Pattern A)**:
   - Toasts, snackbars, navigation use `PublishSubject<T>` in BLoC.
   - UI listens via `StreamSubscription` in `initState()` and cancels in `dispose()`.
10. **Redux Bridge (Pattern B)**:
    - When feature mutation updates global session (e.g. profile update):
    - BLoC emits updated model -> UI dispatches `StoreProvider.of(context).dispatch(...)` after successful render.
    - Prevents saving corrupt state to disk if UI breaks.
11. **Token Injection on Public Endpoints**:
    - `AuthInterceptor` attaches `Bearer <token>` if present to all requests (backends safely ignore on public routes).
12. **Defensive JSON Parsing**:
    - Numbers: `(json['id'] as num?)?.toInt() ?? 0`, `(json['amount'] as num?)?.toDouble() ?? 0.0`.
    - Strings: `json['name']?.toString() ?? ''`.
    - Lists: `(json['items'] as List<dynamic>? ?? []).map((e) => Item.fromJson(e as Map<String, dynamic>)).toList()`.
    - Dates: `DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now()`.

## 3. Backend API Discovery
- Inspect workspace for `*.postman_collection.json` before building network calls.
- If missing, check OpenAPI/Swagger definitions, documentation, or perform targeted web search.

## 4. Deterministic Commands & Verification Quality Gate
- Scaffold + Wire in one step: `dart run scripts/agent/wire_route.dart <name> [optional_path]`
  Auto-runs `mason make bloc --feature_name <name>` first if the feature doesn't exist yet.
- Quality Gate: `powershell -ExecutionPolicy Bypass -File scripts/agent/verify.ps1` (Win) or `./scripts/agent/verify.sh` (Mac/Linux).
  Must pass `dart format --set-exit-if-changed .` and `flutter analyze --fatal-infos`.
- Harness Upgrade & Migration: `dart run scripts/agent/upgrade.dart`.
  Performs 3-tier safe upgrade: overwrites engine scripts and skills, strictly protects `.harness/active-context.md` (0 data loss), and smart-merges custom project rules.
- Hot-reload vs full build: Rely on hot reload/restart during feature work; only full restart on native dependency/asset changes.

## 5. Golden Rules Are Analyzer-Enforced
Rules #1, #3, #4 (repo-transport-only, zero setState, zero RxDart outside BLoC) are enforced at
`flutter analyze` time by the `redux_rxdart_lints` custom_lint plugin (`packages/redux_rxdart_lints`
in the base repo). Violations are compile-gate errors, not just prose — the quality gate above
will already catch them.

## 6. Git Commit Policy
- Always run `verify.ps1` (or `verify.sh`) locally before proposing a commit.
- Use Conventional Commits format (`feat:`, `fix:`, `refactor:`, `chore:`).
- For scaffolded code, use `feat(<feature_name>): scaffold initial architecture`.

## 7. Project Context (.harness/)
- **Before starting**: read `.harness/active-context.md` (current state) and `.harness/system-snapshot.md` (project scan).
- **After completing a task**: update `.harness/active-context.md`:
  - `Current Focus`: what you just finished + what's next.
  - `Recent Tasks`: prepend entry with proof (`commit:a1b2c3d` or `file:lib/features/chat/...`). Cap at 5 — move overflow to `progress.md`.
  - `Key Decisions`: only add if you made an architectural or pattern choice.
  - `Known Issues`: only add if you found something broken you didn't fix.
- **Never** edit `.harness/system-snapshot.md` — it is script-generated only.
- **Never** read `.harness/progress.md` unless explicitly asked for historical context.
- Regenerate snapshot: `dart run scripts/agent/snapshot.dart`.
