# {{project_name}} — Project Memory

This file loads automatically every session — keep it short and token-efficient.
Full golden rules contract lives in `AGENTS.md`. Deep reference docs live in
`.agents/skills/flutter-senior-dev/references/` and load only when needed.

## Stack
Flutter · Redux (global session state) · RxDart (per-screen ephemeral state) · Dio (networking).
Android package: `{{android_package_name}}`. iOS bundle id: `{{ios_bundle_id}}`.

## The State Rule: Where Does Data Live?
**"Does this data need to survive navigation or a cold app restart?"**
- **YES → `AppStore` (Redux)** — auth token, user profile, locale. Nothing else.
- **NO → Feature BLoC (RxDart)** — API fetch state, form fields, UI toggles. Screen-local only.
*Rule of thumb*: When unsure, ask — never leak screen state into Redux "just in case."

## Folder Map
```
lib/
├── networking/        # DioClient + 5 interceptors + sealed ApiException & ApiResponse
├── redux/             # AppStore / AppState / AppAction — session persistence ONLY
├── resources/         # ResColors, AppTypography — design tokens, no raw literals
├── utils/widgets/     # AppScaffold, AppLoadingState, AppErrorState, AppEmptyState, AppCard
└── features/<name>/   # mason make bloc — bloc/ repo/ model/ widgets/ + page
```

## Adding a Feature (Daily Workflow)
1. `dart run scripts/agent/wire_route.dart <feature_name>` — scaffolds bloc if missing & wires route.
2. Implement repo → bloc → model → widgets/page following the golden rules.
3. Run `scripts/agent/verify.ps1` (Win) or `./scripts/agent/verify.sh` (Mac/Linux) before commit.

## Hard Rules (Enforced by Analyzer & Architecture)
- **Repository is transport ONLY**: call `ApiBaseHelper`, return raw `Map<String, dynamic>`. **Never** call `Model.fromJson` in repository. *(Enforced by custom_lint)*
- **BLoC owns business logic**: await repo, parse with `Model.fromJson`, emit `ApiResponse<T>`.
- **Zero `setState` in widgets**: use stream builders (`AppResponseBuilder` / `StreamBuilder`). *(Enforced by custom_lint)*
- **Zero RxDart outside BLoC**: widgets consume plain `Stream<T>` / `ApiResponse<T>` only. *(Enforced by custom_lint)*
- **Sealed `ApiResponse<T>`**: `InitialResponse`, `LoadingResponse`, `SuccessResponse(data)`, `ErrorResponse(error, {retry})`. Match exhaustively.
- **Error mapping**: errors reach UI only via `exception.userFacingMessage` / `AppErrorState`.
- **Token lifecycle**: mixin `CancelTokenOwner`, call `createNewToken()` before fetches, cancel in `dispose()`. Guard stream emissions with `if (!subject.isClosed)`.
- **Design tokens only**: sizing via ScreenUtil (`.w`, `.h`, `.r`, `.sp`), colors via `ResColors.withValues(alpha:)`, typography via `context.textTheme`.

## QA & Review Defaults
- Routine feature work is a single-session, single-agent job.
- For a focused architecture audit of a finished feature, invoke the `flutter-qa` agent (`.agents/agents/flutter-qa.md`).

---
@.harness/active-context.md
