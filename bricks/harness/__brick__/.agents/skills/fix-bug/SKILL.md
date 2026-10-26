---
name: fix-bug
description: Diagnoses and fixes bugs and red quality gates in this Flutter Redux + RxDart + Dio app - reproduce, map the symptom to a layer (endless spinner, unexpected logout, generic error, missing token, duplicate request, emission after dispose, layout not adapting), fix at the right layer, add a regression test, and turn the cause into a lesson. Covers verify.dart failures and every redux_rxdart_lints rule. Use for any bug, crash, error message, failing test, analyzer or lint error, "it doesn't work" or "why does X happen" in this app.
---

# Fix a bug

Find the layer that's wrong, fix it there, prove it with a test, and leave a lesson so it doesn't come back. Patching a symptom in a widget usually breaks a rule and hides the cause.

## 0. Load what this project learned
1. Read `.harness/skills/fix-bug.md` if it exists: known failure modes in *this* app. It wins over this file.
2. Check the Knowledge Graph (`search_nodes` / `read_graph`) or run `dart run scripts/agent/learn.dart list fix-bug`. A lesson or observation that matches the symptom is the fastest fix there is.

## 1. Get the exact failure
- **Red gate**: run `dart run scripts/agent/verify.dart` and read the first failing step's output. Each step is covered in `.agents/skills/fix-bug/gate-failures.md`.
- **Runtime**: the stack trace or the user's exact steps. With a running debug app and the `dart` MCP server: `get_runtime_errors`, `widget_inspector`, then `hot_reload` to confirm a fix. In debug builds, the Redux logging middleware prints every action (look for an unexpected `LogoutAction`).
- **Logic bug** (BLoC, model, reducer): write the failing test *first*, named after the bug. It's the reproduction and the regression guard in one (`.agents/skills/write-tests/SKILL.md`).
- **Separate diagnosis from fix**: Form a concrete hypothesis and reproduce it before changing code. Propose the root cause and minimal diff first. Never guess with multi-shot trial-and-error edits in the main context.

## 2. Map the symptom to a layer
| Symptom | Usual cause | Where to fix |
|---|---|---|
| Spinner never ends | A request was cancelled by another `createNewToken()` in the same BLoC (two loaders, one token), or an emission was skipped | BLoC: recipe E in `.agents/skills/manage-state/bloc-recipes.md` |
| Generic "Something went wrong" | `MalformedResponseException` from a parse error, or a 5xx | Model: compare `fromJson` with a real response, and fix the casts (rule 12) |
| A server sentence shown to users | `BusinessLogicException` / `ValidationException` text is shown verbatim by design | Backend copy, or map it in the BLoC |
| Signed out unexpectedly | Some request got a 401 while a token was held, which dispatches `LogoutAction` (rule 11) | Find which endpoint 401s. Never add per-screen 401 handling. |
| Token not sent | URL host, scheme or port differs from `BASE_URL`, so `AuthInterceptor` skips it | `ApiConstants` / `.env` |
| Request sent two or three times | Retry of an idempotent method on a transient failure (by design), or a double tap | Guard double taps in the BLoC (recipe A) |
| 400 only on some backends | `PlatformInjectorInterceptor` adds `"platform": "app"` to JSON bodies | Agree with the backend (`.agents/skills/flutter-senior-dev/base-gaps.md` §2) |
| "Cannot add new events after calling close" | An emission that bypasses the `_emit` guard | BLoC |
| "setState() called after dispose" / context used after `await` | A missing `mounted` check in an async callback | Page State |
| Toast shows twice / on return to a screen | A `BehaviorSubject` used for events | BLoC: `PublishSubject` (recipe D) |
| Layout wrong after rotation or resize | ScreenUtil in a private widget | Make the widget public (rule 13) |
| Missing getter on `AppLocalizations` | The key is missing from an ARB file, or l10n was not regenerated | Both ARB files, then `flutter gen-l10n` |
| Stale results flash in search | A response arrived after a newer query started | Check `token.isCancelled` after `await` (recipe B) |

None fit → narrow it down by layer: does the raw map (repo) look right? Does the BLoC emit the right states (test)? Does the widget render a given model (widget test)?

## 3. Fix at the right layer
- The smallest change that removes the cause. Keep the architecture: never `setState`, `e.toString()` or a `try/catch` in a widget to hide a BLoC or model bug.
- A bug in shared code (`lib/networking/`, `lib/redux/`, `lib/utils/widgets/ui/`) affects every feature. Say so, and run the full gate.
- Never weaken a lint, skip a test or add `// ignore:` to get green. If a rule seems wrong for a case, stop and ask.

## 4. Prove it
1. The new test fails before the fix and passes after.
2. Fast in-flight check: `dart run scripts/agent/on_edit.dart` on touched files.
3. Full quality gate: `dart run scripts/agent/verify.dart` passes.
4. Runtime / device bugs: confirm in the running app (`hot_reload` + `get_runtime_errors`) or via Maestro (`maestro test .maestro/flows/smoke_launch.yaml`).

## 5. Learn from it (this is what stops repeats)
Close out per `AGENTS.md` §6, and record the cause, not the symptom. Store persistent findings in the Knowledge Graph (`add_observations`) or path rules (`.claude/rules/`), or use the CLI:
- `dart run scripts/agent/learn.dart list fix-bug`. Same cause as an existing lesson → `learn.dart hit L<id> --proof commit:<hash>`.
- New cause → `learn.dart add <skill-that-should-have-prevented-it> "<trigger>: <what to do instead>" --proof <ref>`. Scope it to the skill whose procedure would have avoided the bug (often `add-endpoint` or `manage-state`), not to `fix-bug`.
- If a harness file (a skill, `AGENTS.md`, a reference) told you something wrong, that's an upstream lesson. Follow `.agents/skills/evolve-harness/SKILL.md`.
