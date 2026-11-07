---
name: fix-bug
description: Diagnoses and fixes bugs and red quality gates in this Flutter Redux + RxDart + Dio app - reproduce, map the symptom to a layer (endless spinner, unexpected logout, generic error, missing token, duplicate request, emission after dispose, layout not adapting), fix at the right layer, add a regression test, and turn the cause into a lesson. Covers verify.dart failures and every redux_rxdart_lints rule. Use for any bug, crash, error message, failing test, analyzer or lint error, "it doesn't work" or "why does X happen" in this app.
---

# Fix a bug

Find the wrong layer, fix it there, prove it with a test, leave a lesson. Patching a symptom in a widget usually breaks a rule and hides the cause.

## 0. Load what this project learned
Read `.harness/skills/fix-bug.md` if it exists (it wins over this file) and run `dart scripts/agent/learn.dart list fix-bug`: a matching lesson is the fastest fix.

## 1. Get the exact failure
- **Red gate**: the first failing step of `verify.dart`; each step and lint is covered in `.agents/skills/fix-bug/gate-failures.md`.
- **Runtime**: stack trace or exact steps. With a debug app and the `dart` MCP: `get_runtime_errors`, `widget_inspector`, `hot_reload`. The debug Redux logger prints every action (look for an unexpected `LogoutAction`).
- **Logic bug**: the failing test comes first, named after the bug (`.agents/skills/write-tests/SKILL.md`).
- Hypothesis and reproduction before any edit; propose the root cause and the minimal diff. No trial-and-error edits.

## 2. Map the symptom to a layer
| Symptom | Usual cause | Fix in |
|---|---|---|
| Spinner never ends | Two loaders share one cancel token, or an emission was skipped | BLoC, recipe E of `.agents/skills/manage-state/bloc-recipes.md` |
| Generic "Something went wrong" | `MalformedResponseException` (parse error) or a 5xx | Model casts vs a real response (rule 12) |
| Server sentence shown to users | `BusinessLogicException` / `ValidationException` text, by design | Backend copy, or map it in the BLoC |
| Signed out unexpectedly | Any 401 while signed in logs out (rule 11; refresh only with recipe H) | Find the endpoint; no per-screen 401 handling |
| Token not sent | Host, scheme or port differs from `BASE_URL` | `ApiConstants` / `.env` |
| Request sent 2-3 times | Idempotent retry (by design) or a double tap | Guard in the BLoC (recipe A) |
| 400 on some backends only | `"platform": "app"` injected into JSON bodies | Backend (`.agents/skills/flutter-senior-dev/base-gaps.md` §2) |
| "Cannot add new events after calling close" | Emission bypassing the `_emit` guard | BLoC |
| "setState() called after dispose" / context after `await` | Missing `mounted` check | Page State |
| Toast twice / on return | `BehaviorSubject` used for events | BLoC: `PublishSubject` (recipe D) |
| Layout wrong after resize | ScreenUtil in a private widget | Make it public (rule 13) |
| Missing getter on `AppLocalizations` | Key missing from an ARB, or not regenerated | Both ARBs, `flutter gen-l10n` |
| Stale search results flash | Response after a newer query | Check `token.isCancelled` after `await` (recipe B) |

None fit → bisect by layer: raw map (repo), emitted states (BLoC test), render of a given model (widget test).

## 3. Fix and prove
- Smallest change that removes the cause; never `setState`, `e.toString()` or a widget `try/catch` to hide a BLoC or model bug.
- Shared code (`lib/networking/`, `lib/redux/`, `lib/utils/widgets/ui/`) affects every feature: say so, run the full gate.
- Never weaken a lint, skip a test or add `// ignore:`; if a rule seems wrong, ask.
- The new test fails before and passes after; `verify.dart` passes; runtime bugs confirmed in the app or a Maestro flow.

## 4. Learn from it
Record the cause, not the symptom. Same cause as a lesson → `learn.dart hit L<id> --proof commit:<hash>`. New cause → `learn.dart add <skill-that-should-have-prevented-it> "<trigger>: <what to do instead>" --proof <ref>` (often `add-endpoint` or `manage-state`, not `fix-bug`). A harness file that misled you → `.agents/skills/evolve-harness/SKILL.md`.
