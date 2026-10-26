# AI Agent Contract & Architecture Standards

Read by every coding agent (Claude Code, Codex, Cursor, Copilot, Gemini CLI, ...).
Rules marked 🔒 fail the quality gate when broken (`redux_rxdart_lints`).

## 1. Architecture: Hybrid Redux + RxDart + Dio
- **Redux (global)**: session data that must survive a restart — `authToken`, `userData`, `locale`. Nothing else.
- **RxDart BLoC (per screen)**: fetch state, forms, pagination, search, toggles.
- **Dio**: HTTP/2, fixed interceptor order — Connectivity → Auth → PlatformInjector → Retry → ErrorMapping. Never reorder.

## 2. Golden Rules
1. 🔒 **Repository is transport only**: call `ApiBaseHelper`, return the raw `Map<String, dynamic>`. Never `fromJson`/`fromMap` (calls or tear-offs) in `repo/` or `*_repo.dart`. **One BLoC, one repo**: a BLoC never holds two repos. Compose shared capabilities (e.g. dropdowns, tags, profile, logout) with `mixin <Capability>Mixin` (`with FooMixin`) — never `extends OtherFeatureRepo` (inheritance leaks unrelated/sensitive methods).
   - `// ❌ BAD:  Future<User> get() async => User.fromJson(await helper.get(...));`
   - `// ✅ GOOD: Future<Map<String, dynamic>> get() => helper.get(...);`
2. 🔒 **BLoC owns logic and state**: await the repo, parse with `Model.fromJson`, emit `ApiResponse<T>`. Widgets show errors with `error.userFacingMessage(context)` (or let `AppResponseBuilder` do it). Never display `e.toString()`.
   - `// ❌ BAD:  Text(e.toString());`
   - `// ✅ GOOD: Text(error.userFacingMessage(context)); // or let AppResponseBuilder render it`
3. 🔒 **Zero `setState`** in feature widgets. Drive UI from streams (`AppResponseBuilder`, `StreamBuilder`). Only design-system primitives in `lib/utils/widgets/ui/` may hold purely visual state.
   - `// ❌ BAD:  setState(() => _count++); in feature widget`
   - `// ✅ GOOD: AppResponseBuilder<User>(stream: _bloc.userStream, builder: (ctx, user) => ...)`
4. 🔒 **Zero RxDart outside BLoCs**: widgets never import `rxdart`; they consume plain `Stream<T>` / `ApiResponse<T>`.
   - `// ❌ BAD:  import 'package:rxdart/rxdart.dart'; in widget or page`
   - `// ✅ GOOD: import only plain Dart Streams and ApiResponse<T>`
5. **Rule of 2**: a widget used in ≥ 2 places moves to `lib/utils/widgets/ui/`. Reuse with parameters before duplicating.
6. **Presentation**: standard `Scaffold` by default; `AppScaffold` when the shared chrome is wanted.
7. **Forms**: the `StatefulWidget` owns and disposes `TextEditingController`s and passes values to BLoC methods (`_bloc.submit(email: _email.text)`). BLoC streams drive spinners and error banners.
8. 🔒 **Fetch**: `Future<void> fetch({bool refresh = false})`; call `createNewToken()` first (a newer fetch cancels the older one; `no_fetch_without_token`); ignore `RequestCancelledException`; emit errors with `retry: fetch`. Live search: `PublishSubject<String>` + `.debounceTime(300ms).distinct()`.
9. **One-off UI events** (toast, navigation): a `PublishSubject` in the BLoC, subscribed in `initState()`, cancelled in `dispose()`.
10. **Redux bridge**: when a feature changes session data, the BLoC emits the new model and the UI dispatches to the store after it renders.
11. **Auth**: `AuthInterceptor` attaches the bearer token only to the `BASE_URL` host. For silent token refresh, a token refresh handler/interceptor intercepts 401, requests a new token via refresh endpoint, replays pending requests, and only dispatches `LogoutAction` if refresh fails or no refresh token exists — don't add per-screen 401 handling.
12. **Defensive JSON parsing**: `(json['id'] as num?)?.toInt() ?? 0`, `json['name']?.toString() ?? ''`, `(json['items'] as List? ?? []).map(...)`, `DateTime.tryParse(json['at']?.toString() ?? '')`.
13. 🔒 **ScreenUtil only in public widgets**: `.w/.h/.r/.sp` inside a private (`_Foo`) widget is not rebuilt on resize. Make the widget public.
   - `// ❌ BAD:  class _Card extends StatelessWidget { Widget build(...) => SizedBox(width: 100.w); }`
   - `// ✅ GOOD: class Card extends StatelessWidget { Widget build(...) => SizedBox(width: 100.w); }`
14. 🔒 **No withOpacity in UI**: Avoid `.withOpacity()`; use `Color.withValues(alpha: ...)` or design-system color tokens (`no_with_opacity`).
   - `// ❌ BAD:  Colors.black.withOpacity(0.5);`
   - `// ✅ GOOD: Colors.black.withValues(alpha: 0.5); // or ResColors.primary`
15. 🔒 **Dispose all RxDart subjects**: Every `BehaviorSubject` / `PublishSubject` in a BLoC must be closed in `dispose()` to prevent memory leaks (`no_unclosed_subject`).
   - `// ❌ BAD:  void dispose() { subscriptions.dispose(); } // left subject unclosed`
   - `// ✅ GOOD: void dispose() { cancelRequests(); subscriptions.dispose(); _data.close(); }`

## 3. Before Writing Network Code
Look for `*.postman_collection.json`, then OpenAPI/Swagger, then docs. Ingest contracts with `dart run scripts/agent/ingest_contract.dart <contract.json> --scaffold <endpoint>` to generate models with defensive parsing, mock fixtures, and endpoint constants. Add endpoints to `lib/networking/api_constants.dart`. Never guess a response shape — ask if no contract exists.

## 4. Tooling for Agents
- **Context Retrieval & Token Efficiency (RAG)**:
  - **AST & Symbol Retrieval (LSP)**: Use `mcp__dart` for symbol definitions, method signatures, and type hierarchies instead of reading entire files into context.
  - **Index-Based Retrieval**: Read `.harness/system-snapshot.md` first for routes, features, and endpoints; never recursively sweep directories.
  - **Deterministic Path Rules**: Path-scoped rules in `.claude/rules/*.md` (Claude Code) and `.cursor/rules/*.mdc` (Cursor) inject layer-specific constraints only when editing matching files.
  - **In-flight check & watcher**: Use `dart run scripts/agent/on_edit.dart` on touched files (<1.5s) during active dev. Check `.harness/diagnostics.json` if `dart run scripts/agent/watch.dart` is running. Reserve full `verify.dart` for the pre-commit gate.
  - **Targeted Research**: Delegate external pub packages and API docs to `@docs-scout` (runs on Haiku, caps digests strictly <200 words).
  - **Banned Files**: Never read generated serialization (`*.g.dart`, `*.freezed.dart`, `build/`, `.dart_tool/`).
- **Skills** (`.agents/skills/`; Claude Code: `.claude/skills/`). Load the one that fits before starting: `add-feature` (new screen/flow), `add-endpoint` (API work), `manage-state` (BLoC recipes, Redux changes), `build-ui`, `write-tests`, `fix-bug` (bugs, red gate), `evolve-harness` (lessons, rules, new skills), `flutter-senior-dev` (planning, architecture, review).
- **Specialist Subagents** (`.claude/agents/`): `@bloc-specialist` (reactive state/streams), `@ui-artisan` (views/widgets/design system), `@device-qa` (Maestro device testing), `@flutter-qa` (architecture review), `@skeptic` (adversarial plan review), `@docs-scout` (token-shielded doc digests). Default to single-agent execution; invoke subagents only when specialized isolation or research is needed.
- **Swarm coordination, messaging & worktrees**: `dart run scripts/team/task_handoff.dart` (layer handoffs, `send`, `inbox`, `wait-human`), `dart run scripts/team/heartbeat.dart` (liveness & human blocker alerts), and `dart run scripts/team/worktree.dart` (isolated git worktrees, `.harness/team-protocol.md`).
- **Device testing**: `maestro test .maestro/flows/smoke_launch.yaml` (`.mcp.json` → `maestro mcp`).
- **Scaffold + route in one step**: `dart run scripts/agent/wire_route.dart <feature_name> [route_path]` (runs `mason make bloc` if the feature is missing).
- **Quality gate** (must pass before proposing a commit): `dart run scripts/agent/verify.dart` — format, analyze, custom lints, tests, lessons, snapshot. `--fast` = format + analyze only. Wrappers: `bash scripts/agent/verify.sh`, `powershell -File scripts/agent/verify.ps1`.
- **MCP servers** (`.mcp.json`): `dart` (`mcp__dart__*` for analyzer/LSP/debug), `maestro` (`mcp__maestro__*` for mobile UI testing), and `memory` (`mcp__memory__*` for persistent domain facts).
- **Learning & memory**: Store lessons simply in `.harness/lessons.md` or Claude Auto-Memory (`MEMORY.md`); promote recurring rules directly into `.claude/rules/` or linter rules. `dart run scripts/agent/learn.dart` is available for offline CLI tracking.
- **Harness upgrade**: `dart run scripts/agent/upgrade.dart` (keeps `.harness/`, your own skills and everything below the project-rules marker).
- **FVM projects**: when `.fvm/` or `.fvmrc` exists, prefix bare CLI commands with `fvm` (e.g. `fvm dart run scripts/agent/verify.dart`, `fvm flutter test`). Agent scripts (`verify.dart`, `wire_route.dart`, `on_edit.dart`, `watch.dart`) detect FVM automatically.

## 5. Git
- Never commit or push unless asked. Run the quality gate first.
- Conventional Commits: `feat(<feature>): ...`, `fix(...)`, `refactor(...)`, `chore(...)`.

## 6. Project Memory & Retrieval (`.harness/`)
- **Start of task**: Read `.harness/system-snapshot.md` for the project map (features, routes, endpoints, state, deps). Rely on path-scoped rules in `.claude/rules/` and `.cursor/rules/` for layer standards, and use `mcp__dart` (LSP) for exact symbol definitions and types. Read `.harness/active-context.md` for high-level continuity.
- **No close-out tax on small edits**: For quick bugfixes, styling tweaks, or iterative coding turns, **skip close-out entirely** — run `dart run scripts/agent/on_edit.dart` and report.
- **End of feature / milestone close-out**: Only when completing a full feature, epic, or when explicitly requested, ensure `dart run scripts/agent/verify.dart` is green, then update `.harness/active-context.md`:
  - `Current Focus`: 2-3 lines — what finished, what's next.
  - `Recent Tasks`: newest first, 1 line each with proof (`file:lib/...` or `feat: <summary>`). Keep max 5; move older items to `.harness/progress.md` as `[YYYY-MM-DD] type(scope): what (proof)`.
  - `Key Decisions`: 1-2 lines, architectural decision + reason.
  - `Known Issues`: only what is currently broken or deferred.
- **Learning & Rule Evolution**: Avoid bureaucratic logging. (1) Transient reflections: handled automatically by Claude Auto-Memory (`MEMORY.md`). (2) Domain facts & API quirks: codify directly into `.claude/rules/<domain>.md` and `.cursor/rules/` so they load automatically when that layer is touched. (3) Permanent team rules: add directly to §7. (4) Offline team sync: `dart run scripts/agent/learn.dart` remains available for tracking and proposing upstream improvements.
- Project knowledge lives only in `.harness/`, `.claude/rules/`, `.cursor/rules/`, and below the project-rules marker. Shipped skills and template text above the marker are refreshed on upgrade.
- Never edit `system-snapshot.md` by hand (generated by `verify` and `snapshot`). Read `progress.md` only when asked for project history.

<!-- harness:project-rules — Everything below this line is yours. `upgrade.dart` keeps it verbatim. -->
## 7. Project-Specific Rules
_Add team conventions, backend quirks, decisions and project skills that every agent must follow (promoted lessons land here)._
