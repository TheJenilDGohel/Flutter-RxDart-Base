# Quality gate failures

`dart run scripts/agent/verify.dart` stops at the first failing step and prints that tool's output. Fix the first failure and run the gate again, since later steps may pass once it's fixed.

## 1. Formatting
`dart format lib test` and re-run. The edit hook already formats each file Claude Code edits, so a format failure usually means a file changed outside it (a generator, a copied snippet, or another agent).

## 2. Analyzer (`flutter analyze --fatal-infos`)
Infos fail the gate too. The project enables strict casts, inference and raw types:

| Message (short) | Fix |
|---|---|
| `dynamic` can't be assigned / argument type `dynamic` | Cast explicitly and defensively: `json['name']?.toString() ?? ''`, `(json['n'] as num?)?.toInt() ?? 0` |
| Missing type arguments / raw type | `List<OrderModel>`, `Future<void>`, `PublishSubject<String>()` |
| `unawaited_futures` | `await` it, or wrap it in `unawaited(...)` (`dart:async`) when fire-and-forget is intended |
| `close_sinks` / `cancel_subscriptions` | Close the subject or cancel the subscription in `dispose()` |
| `use_build_context_synchronously` | `if (!mounted) return;` after the `await`, before using `context` |
| `prefer_const_constructors` / `prefer_final_locals` | Do what it says |
| Undefined getter on `AppLocalizations` | Add the key to both ARB files, then run `flutter gen-l10n` |
| URI doesn't exist (`package:<app>/...`) | Wrong path or package name. Copy imports from a sibling file. |

The MCP `analyze_files` tool gives the same diagnostics for one file without a full run.

## 3. Architecture lints (reported by the Analyzer step)
The `redux_rxdart_lints` analyzer plugin (top-level `plugins:` block in `analysis_options.yaml`) reports these through `flutter analyze` and the IDE. After changing that block, restart the analysis server (IDE: "Dart: Restart Analysis Server"). No rule ever shows up at all? The block is missing, or the SDK is older than Dart 3.13, which skips a git plugin source silently.
Each rule enforces a golden rule from `AGENTS.md` §2:

| Rule | Means | Fix |
|---|---|---|
| `repo_transport_only` (rule 1) | `fromJson`/`fromMap` is called or torn off in a repo file | Return the raw map from the repo and parse in the BLoC (`.agents/skills/add-endpoint/SKILL.md` §3–5) |
| `no_exception_tostring` (rule 2) | `e.toString()` on an error in UI code | Show `error.userFacingMessage(context)`, or let `AppResponseBuilder` render the error |
| `no_setstate_in_widget` (rule 3) | `setState` in a feature widget | Move the state into the BLoC (a `BehaviorSubject` + a sync getter) and render with `StreamBuilder` / `AppResponseBuilder`. Purely visual state in a `lib/utils/widgets/ui/` primitive is exempt. |
| `no_rxdart_in_ui` (rule 4) | A widget imports `rxdart` | Expose a plain `Stream<T>` getter from the BLoC, plus a sync getter if the widget needs the current value |
| `no_screenutil_in_private_widget` (rule 13) | `.w/.h/.r/.sp` in a `_Private` widget | Make the widget public (drop the `_`), or compute the size in a public parent and pass it down |

Never silence these with `// ignore:`. If a rule looks wrong for a real case, stop and ask: it may be a lesson for the base repo (`.agents/skills/evolve-harness/SKILL.md`).

## 4. Tests (`flutter test`)
Read the first failure's expectation vs actual, then:
- A state list mismatch: often a missing `await pumpEventQueue()` before asserting, or an extra loading state when `refresh: true` should keep content.
- `Bad state: No element` in a fake repo: the test queued fewer responses than the BLoC makes calls. That's a real behavior change or a double call.
- A failure only in the full run: shared static state (`AppStore`, `SharedPreferences` mocks, `dotenv`). Reset it in `setUp`.
- Your change broke a generated test? Fix the code unless the test encodes behavior the spec deliberately changed. Then update the test and say why.

## 5. Lessons (`learn.dart check`)
A line in `.harness/lessons.md` doesn't match the format (usually a hand edit). Fix the line as the file's header comment describes, or remove it and re-add it with `learn.dart add`. The step also reports lessons ready to promote. That isn't a failure; act on it at close-out (`.agents/skills/evolve-harness/SKILL.md`).

## 6. Snapshot
It rarely fails, and only when `lib/` can't be read. The snapshot is generated, so never edit `.harness/system-snapshot.md` by hand.
