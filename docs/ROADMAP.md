# Improvement Roadmap

Status: **proposal, nothing implemented.** Produced from a read-only review of the repository on 2026-09-21.

Paths below are relative to `bricks/project/__brick__/` unless stated otherwise. Items marked **[confirm]** were found by reading code and must be proven or disproven by the Phase 0 smoke test before any fix is written.

## 1. Summary

The core design is sound: sealed `ApiException` / `ApiResponse`, per-screen BLoC with `CancelTokenOwner`, disciplined brick versioning, and an honest `base-gaps.md`. The weak spot is that the repository claims guarantees it no longer delivers, and nothing tests the bricks end to end, so drift keeps getting in.

## 2. Findings

### P0: false claims and broken guarantees

1. **The lint plugin is orphaned.**
   - Harness 1.4.x removed the hooks that patched `pubspec.yaml` and `analysis_options.yaml`. No template now contains `custom_lint` or `redux_rxdart_lints`.
   - `bricks/harness/__brick__/AGENTS.md:59`, `bricks/harness/README.md:52-57` and the skill's `SKILL.md` still say Rules 1, 3 and 4 are analyzer-enforced.
   - Even when wired, `custom_lint` results normally come from `dart run custom_lint`, not `flutter analyze` **[confirm]**.
2. **The base breaks its own Rule 3 (zero `setState`).** `setState` is called in `lib/features/showcase/showcase_home_page.dart:204`, `lib/utils/widgets/ui/app_dialog.dart:185` and `lib/utils/widgets/ui/app_textformfield.dart:84`. The `no_setstate_in_widget` rule flags any `setState` call in any file. `no_rxdart_in_ui` exempts everything under `/utils/`, which is where UI widgets live, so it is too loose.
3. **Freshly generated `bloc` output probably fails the quality gate [confirm].**
   - The BLoC template has unused imports (`api_exceptions`, `api_response`) and an unused `_repo` field; the page template has an unused `_bloc` field.
   - `bricks/bloc/README.md` says the page uses `AppScaffold`; it uses plain `Scaffold`.
   - `lib/redux/middleware/persistence_middleware.dart` calls `_syncToPrefs(...)` unawaited while `unawaited_futures` is enabled in `analysis_options.yaml`.
   - `verify` runs `flutter analyze --fatal-infos`.
4. **A cancelled request surfaces as an error.** `lib/networking/interceptors/error_mapping_interceptor.dart` maps `DioExceptionType.cancel` to `InternalServerErrorException`, and `ApiBaseHelper._extractException` does the same. Golden Rule 8 (`createNewToken()` on refetch) cancels the previous call, so the BLoC can emit a stale error for a superseded request.
5. **Non-object bodies escape as `TypeError`.** `response.data as Map<String, dynamic>` in `lib/networking/api_base_helper.dart` throws a raw `TypeError` for a list body or an empty 204, which no BLoC catches as `ApiException`. `base-gaps.md` documents the list case but no code handles it.
6. **`ApiResponse` subtype names collide.** `Error<T>` in `lib/networking/api_response.dart` shadows `dart:core` `Error` in every file that imports it. `Initial`, `Loading` and `Completed` are similarly generic.
7. **`AppStore` cannot be re-initialised.** `static late final Store<AppState> _store` throws on a second `init()` (tests, hot restart), and `AuthInterceptor` depends on that global so it cannot be unit tested.
8. **The SDK constraint is hard-pinned.** `pubspec.yaml` sets `sdk: ^3.12.2`, overwriting what `flutter create` wrote. Teams on an older Flutter cannot run `pub get`.

### P1: drift, hygiene, developer experience

- **Doc drift.**
  - `AGENTS.md:6` names `CurlLoggerInterceptor`, which does not exist.
  - `AGENTS.md:15` says `ApiResponseBuilder`; the class is `AppResponseBuilder`.
  - `AGENTS.md:20` and `SKILL.md` point to `utils/widgets/common/`; the folder is `ui/`.
  - `bricks/harness/README.md:35` says a `post_gen` hook mirrors `.cursor/` (there are no hooks now); line 66 says v1.4.0 while the brick is 1.4.1.
  - `SKILL.md` references `references/architecture.md`, which was flattened away.
  - `bricks/project/README.md` says `lib/screens/`; it is `lib/features/`.
  - `bricks/bloc/README.md` lists a `project_name` var and a `pre_gen` hook, but `project_name` is not declared in `bricks/bloc/brick.yaml`.
  - Root `architecture.md` has a broken code fence (`## 1. ... Data```) and differs from the skill's copy.
  - `CONTRIBUTING.md` says `project` has no CHANGELOG; it does.
  - `bricks/harness/__brick__/.harness/active-context.md` has corrupted encoding.
- **No tests and no CI.** There is no `.github/`. Nothing tests the bricks, the hooks, `wire_route.dart` or the lint package (no `test/`). The history contains a hooks-then-no-hooks flip-flop driven by a Windows-only path problem that a CI matrix would have caught. The `CONTRIBUTING.md` rules (version bump, README sync) are enforced only by memory.
- **Duplicated skill and heavy context.**
  - The `.agents/` and `.cursor/` skill copies are byte-identical (4 files each), and `AGENTS.md` and `SKILL.md` both list the 12 rules.
  - `CLAUDE.md` `@`-imports about 24 KB (roughly 6K tokens) into every Claude Code session, which defeats on-demand skill loading.
  - Claude Code discovers project skills under `.claude/skills/`, not `.agents/` **[confirm]**.
- **`snapshot.dart` and `verify`.** The snapshot embeds a timestamp (dirties git on every run) and re-runs a full `flutter analyze` right after `verify` already ran one. The gate never runs `flutter test`. `verify.sh` step counters read `[1/2]`, `[2/3]`, `[3/3]`.
- **`wire_route.dart`.** It writes the route constant before checking that the router file exists, so a failure leaves a half-wired repo with no rollback. It selects the router file by fuzzy filename. `bloc` does not validate `feature_name`.
- **`bricks/project/hooks/post_gen.dart`.** It ignores the exit code of `change_app_package_name`, calls `exit(1)` after mason has already written files, silently swallows a missing global `harness` brick, and leaves `change_app_package_name` as a permanent dev dependency after its one-shot use.
- **Hardcoded English despite l10n.** `lib/utils/extensions/exception_ext.dart` messages, the `'Retry'` label in `app_error_state.dart` and the `'Error'` title in `app_response_builder.dart`. A Hindi user sees English errors.
- **Missing pieces.** No 401 → `LogoutAction` path; no 403/422/429 mapping; `ApiConstants.baseUrl` is a `const` with no env or flavor support; retry policy for POST/PUT is unverified **[confirm]**; `bloc` generates no test and `model/` is empty.
- **Repeated boilerplate.** Rules 8 and 12 (fetch, cancel, `isClosed` guard, defensive JSON) are hand-copied into every BLoC.
- **No contributor entry point at the repo root.** The last commit removed `.agents` and `.cursor` from the root, so nothing points agents or maintainers at `CONTRIBUTING.md` or a smoke-test command.

## 3. Decisions needed

1. **Enforcement route.** Wire `custom_lint` into the project template (recommended, fastest), migrate to Dart's native analyzer plugin API later, or drop the "analyzer-enforced" claim.
2. **Rule 3 scope.** Exempt `utils/widgets/ui/` primitives (recommended) or rewrite them with `ValueNotifier`.
3. **Skill layout.** One canonical `.agents/` copy plus `.claude/skills/`, and drop the `.cursor/` mirror (recommended); or keep the mirrors with a CI byte-diff check.
4. **Secure storage.** Default on, or an opt-in `include_secure_storage` flag (recommend opt-in).
5. **Redux.** Three fields and four actions is the thinnest justification in the stack. Recommendation: keep it as the project's identity, but do not extend it.

## 4. Plan

Workstreams own disjoint files so they can run as parallel agents in separate worktrees. Every phase after 0 is gated by the Phase 0 smoke test.

- **A**: templates (`bricks/project`, `bricks/bloc`)
- **B**: harness and docs (`bricks/harness`, root docs)
- **C**: enforcement and CI (`packages/redux_rxdart_lints`, `.github/`, `tool/`)

Dependencies: 0 → 1 → (2, 3 in parallel) → 4 → 5 → 6.

### Phase 0: Baseline (size S)

Add `tool/smoke.dart` (or `.sh` / `.ps1`) that runs: `flutter create` in a temp directory → `mason make project` (non-interactive, overwrite conflicts) → `flutter analyze --fatal-infos` → `flutter test` → `mason make bloc` → `wire_route` → analyze again.

Acceptance: runs on Windows and Linux; its output is the confirmed defect list and resolves every **[confirm]** above.

### Phase 1: Template correctness (M, workstream A)

Fix P0 items 3-8: clean generated code, a `RequestCancelledException`, a list and empty-body path in `ApiBaseHelper`, renamed `ApiResponse` subtypes, re-initialisable `AppStore`, a relaxed SDK constraint, and l10n for error strings.

Acceptance: smoke test passes with zero analyzer issues; `project` bumped to 1.2.0 and `bloc` to 1.1.0 with CHANGELOG entries.

### Phase 2: Make enforcement real (M, workstream C)

Depends on Decision 1.

- Wire `custom_lint` and the `redux_rxdart_lints` git dependency through mustache sections (`{{#include_harness}}...{{/include_harness}}`) in the project template's `pubspec.yaml` and `analysis_options.yaml`, with no hook.
- Add `dart run custom_lint` to `verify`.
- Add tests to the lint package.
- Reconcile Rule 3 with the UI kit (Decision 2).
- Check that the pinned `analyzer ^7.0.0` resolves against SDK 3.12.

Acceptance: a deliberate `setState` in a generated feature page fails `verify`.

### Phase 3: CI (M, workstream C)

- GitHub Actions matrix on ubuntu, windows and macos running the smoke test, the lint package tests, and `dart format` / `dart analyze` per package.
- A check that fails when `__brick__` or hooks change without a `brick.yaml` version bump and CHANGELOG entry.
- A docs check that class names and paths cited in `AGENTS.md`, `SKILL.md` and the READMEs exist.

Acceptance: a PR that changes a template without a version bump fails.

### Phase 4: Base DX upgrades (L, workstream A)

Depends on Phase 1.

- A `BaseBloc` helper or `runFetch(subject, () => repo...)` covering loading, the `isClosed` guard, cancel and `userMessage`.
- JSON parsing helpers for Rule 12.
- `bloc` template with an example model, an example fetch and a generated test.
- Env config via `--dart-define`.
- A 401 → logout hook.
- An opt-in `include_secure_storage` flag.

Acceptance: a generated feature needs no hand-written cancel or guard code; `project` bumped to 1.3.0.

### Phase 5: Harness diet (M, workstream B)

Depends on Decision 3.

- One skill source plus `.claude/skills/`.
- `CLAUDE.md` imports only `AGENTS.md` and `active-context.md`.
- Deterministic snapshot (no timestamp, no second analyze), gitignored or regenerated.
- `flutter test` added to `verify`; fix `verify.sh` numbering.
- Atomic `wire_route` with rollback and input validation.
- Fix the encoding corruption and the doc drift listed above.

Acceptance: session-start context from the harness is at most about a quarter of today's ~6K tokens; `verify` leaves git clean; `harness` bumped to 1.5.0.

### Phase 6: Release hygiene (S)

Sync all READMEs (`CONTRIBUTING.md` rule 2), refresh the root README table, correct `CONTRIBUTING.md`, and add a short root `AGENTS.md` pointing to `CONTRIBUTING.md` and the smoke command.

Acceptance: the docs check from Phase 3 passes with no exceptions.
