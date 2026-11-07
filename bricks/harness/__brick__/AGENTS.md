# AI Agent Contract & Architecture Standards

Read by every coding agent (Claude Code, Codex, Cursor, Copilot, Gemini CLI, ...).
Rules marked 🔒 are enforced by `redux_rxdart_lints` (lint name in backticks) and fail the quality gate; the lint message is the explanation. The lints need Dart 3.13+; `verify.dart` warns when they are not running, and then you check those rules yourself.

## 1. Architecture: Hybrid Redux + RxDart + Dio
- **Redux (global)**: session data that must survive a restart — `authToken`, `userData`, `locale`. Nothing else.
- **RxDart BLoC (per screen)**: fetch state, forms, pagination, search, toggles.
- **Dio**: default `dart:io` adapter (native stack opt-in: repo recipe I), fixed interceptor order — Auth → PlatformInjector → Retry → ErrorMapping. Never reorder.

## 2. Golden Rules
1. 🔒 **Repository is transport only** (`repo_transport_only`): call `ApiBaseHelper`, return the raw `Map<String, dynamic>`, no `fromJson`/`fromMap` in `repo/`. One BLoC, one repo; share capabilities with `mixin <Capability>Mixin`, never `extends OtherFeatureRepo`.
   - `// ❌ BAD:  Future<User> get() async => User.fromJson(await helper.get(...));`
   - `// ✅ GOOD: Future<Map<String, dynamic>> get() => helper.get(...);`
   - _Only this rule keeps a BAD/GOOD pair (`tool/eval.dart` requires one); the lints explain the rest._
2. 🔒 **BLoC owns logic and state** (`no_exception_tostring`): parse with `Model.fromJson`, emit `ApiResponse<T>`; show errors with `error.userFacingMessage(context)`.
3. 🔒 **Zero `setState`** in feature widgets (`no_setstate_in_widget`); drive UI from streams. Only `lib/utils/widgets/ui/` primitives hold purely visual state.
4. 🔒 **Zero RxDart outside BLoCs** (`no_rxdart_in_ui`): widgets consume plain `Stream<T>` / `ApiResponse<T>`.
5. **Rule of 2**: a widget used in ≥ 2 places moves to `lib/utils/widgets/ui/`.
6. **Presentation**: standard `Scaffold` by default; `AppScaffold` when the shared chrome is wanted.
7. **Forms**: the `StatefulWidget` owns and disposes its `TextEditingController`s and passes values to BLoC methods (`_bloc.submit(email: _email.text)`).
8. 🔒 **Fetch** (`no_fetch_without_token`): `Future<void> fetch({bool refresh = false})`, `createNewToken()` first, ignore `RequestCancelledException`, emit errors with `retry: fetch`. Live search: `PublishSubject<String>` + `.debounceTime(300ms).distinct()`.
9. **One-off UI events** (toast, navigation): a `PublishSubject` in the BLoC, subscribed in `initState()`, cancelled in `dispose()`.
10. **Redux bridge**: the BLoC emits the new model; the UI dispatches to the store after it renders.
11. **Auth**: `AuthInterceptor` attaches the bearer token only to the `BASE_URL` host. A 401 while a token is held dispatches `LogoutAction` once (`ErrorMappingInterceptor`) — no per-screen 401 handling. There is no refresh token by default; silent refresh is opt-in (recipe H in `.agents/skills/add-endpoint/repo-recipes.md`).
12. **Defensive JSON parsing**: a wrong wire type falls back, never throws: `switch (json['id']) { final num v => v.toInt(), final String v => num.tryParse(v)?.toInt() ?? 0, _ => 0 }`, `json['name']?.toString() ?? ''`, `switch (json['items']) { final List<Object?> v => v, _ => const <Object?>[] }`, `DateTime.tryParse(json['at']?.toString() ?? '')`. A bare `as` cast (`as num?`, `as List?`, `as Map?`) throws on a wrong type.
13. 🔒 **`flutter_screenutil` units only in public widgets** (`no_screenutil_in_private_widget`): it skips private widgets on resize. The base's `adaptive_units` (same API) rebuilds them.
14. 🔒 **No `withOpacity`** (`no_with_opacity`): use `withValues(alpha: ...)` or a colour token.
15. 🔒 **Dispose all RxDart subjects** (`no_unclosed_subject`): close every subject in `dispose()`.

## 3. Before Writing Network Code
Look for `*.postman_collection.json`, then OpenAPI/Swagger, then docs. Ingest contracts with `dart scripts/agent/ingest_contract.dart <contract.json> --scaffold <endpoint>` to generate models with defensive parsing, mock fixtures, and endpoint constants. Add endpoints to `lib/networking/api_constants.dart`. Never guess a response shape — ask if no contract exists.

## 4. Tooling for Agents
- **Find, don't sweep**: symbols and types via `mcp__dart` (LSP); routes, features and endpoints by grepping `.harness/system-snapshot.md` (generated, never edit, never read whole). Never read `*.g.dart`, `*.freezed.dart`, `build/`, `.dart_tool/`; the read-guard plugin blocks them. Read files over 30k chars by range. Recipe files (`*-recipes.md`) are long: grep `^## ` for the section and read only that range.
- **Layer rules**: `.claude/rules/*.md` (Cursor: `.cursor/rules/*.mdc`) load only when matching files are touched.
- **Skills** (`.claude/skills/`, mirrored in `.agents/skills/`): `add-feature`, `add-endpoint`, `manage-state`, `build-ui`, `write-tests`, `fix-bug`, `evolve-harness`, `flutter-senior-dev` (planning, review). Load the one that fits.
- **Checks, cheapest first**: `mcp__dart` analyze while editing (milliseconds once warm; compile errors and SDK lints, not the 🔒 lints) → `dart scripts/agent/on_edit.dart` on touched files (format + analyze with the 🔒 lints, ~20 s) → `dart scripts/agent/affected_tests.dart` after each change → `dart scripts/agent/verify.dart` (size budget, format, analyze, lints, full suite, snapshot) before commits that touch shared code and at milestones (`--fast` = budget + format + analyze).
- **Scaffold + route**: `dart scripts/agent/wire_route.dart <feature_name> [route_path]`.
- **Device testing**: Maestro flows in `.maestro/flows/` run as a command (`maestro test <flow or folder>`), pass/fail only, at milestones. Never drive the device by screenshots; capture one only for a failing step (the shot-shrink plugin downsizes it).
- **One session**: every extra session reloads the startup context. Subagents (`.claude/agents/`) only when their output would flood the main context, on the cheapest model that works; parallel sessions only on the owner's request, one `git worktree` each.
- **MCP** (`.mcp.json`): `dart`, `maestro`. **FVM**: with `.fvm/` or `.fvmrc`, prefix commands with `fvm` (agent scripts detect it).
- **Harness upgrade**: `dart scripts/agent/upgrade.dart` keeps `.harness/`, your skills and everything below the project-rules marker.

## 5. Git
- Never commit or push unless asked. Run the quality gate first.
- Conventional Commits: `feat(<feature>): ...`, `fix(...)`, `refactor(...)`, `chore(...)`.

## 6. Project Memory (`.harness/`)
- `active-context.md` loads on every request: keep it short (Current Focus 2-3 lines, Recent Tasks max 5 with proof, Known Issues only what is broken now). No close-out tax on small edits: update it only at a feature end or milestone; older tasks go to `progress.md` (read only when asked).
- Size budget (`budget.dart`, part of `verify.dart`): `CLAUDE.md` + `AGENTS.md` + `active-context.md` ≤ 12k chars, each `.claude/rules/*.md` ≤ 2k, `lessons.md` ≤ 60 lines.
- Knowledge goes where it loads on demand: layer facts and API quirks in `.claude/rules/<domain>.md` (+ `.cursor/rules/`), permanent rules in §7, lessons in `lessons.md` (one loop: lesson → seen twice → rule, guard rule (`guard-rules.json`) or lint → delete; see `evolve-harness`). No handoff files or status docs; finished specs are deleted (git keeps them).

<!-- harness:project-rules — Everything below this line is yours. `upgrade.dart` keeps it verbatim. -->
## 7. Project-Specific Rules
_Add team conventions, backend quirks, decisions and project skills that every agent must follow (promoted lessons land here)._
