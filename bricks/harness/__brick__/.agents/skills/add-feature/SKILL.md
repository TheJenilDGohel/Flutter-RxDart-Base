---
name: add-feature
description: Builds a new screen or user flow end to end on this Flutter Redux + RxDart + Dio base - API contract, a short spec with acceptance criteria, scaffold and route (wire_route.dart / mason make bloc), endpoint, repo, model, BLoC, page, l10n strings, tests and the quality gate. Use whenever asked to add, create, build or implement a screen, page, feature, module or flow, even for a one-line request like "add a profile screen".
---

# Add a feature

Spec, scaffold, fill in from the network up, green gate. Rules: `AGENTS.md` §2. Don't skip steps for a small request: the shortcuts are where agent-written features break.

## 0. Load what this project learned
Read `.harness/skills/add-feature.md` if it exists (it wins over this file), run `dart scripts/agent/learn.dart list add-feature`, and grep `.harness/system-snapshot.md` for related features and routes: extend one instead of creating a near-duplicate.

## 1. Contract and spec
No contract (`AGENTS.md` §3) → stop and ask for a sample response; an invented shape passes the generated tests and fails on the first real request. Then write `.harness/specs/<feature>.md`, under ~30 lines:

```
# <feature>
Route: /<path> · Reached from: <screen, tab, deep link>
Endpoints: GET /... (contract: <file or link>)
States: loading · empty · error + retry · success  [· offline · no permission · partial]
Acceptance criteria:
- [ ] AC1: Given ..., when ..., then ...
Out of scope / Open questions: ...
```
Each criterion becomes a test in step 5. A vague request (no states, no data source, unclear role) → confirm the spec with the user first; otherwise write your assumptions into it and carry on.

## 2. Scaffold and route
`dart scripts/agent/wire_route.dart <feature_name> [/route-path]` runs `mason make bloc` when `lib/features/<feature_name>/` is missing and adds the `Routes` constant and the route in `AppRouter` (a `GoRoute`; a `case` in apps still on `onGenerateRoute`). It refuses with `auto_route`: wire by hand. Then `verify.dart --fast`: a green start makes every later failure yours.

## 3. Fill in, network first
1. Endpoint, repo, model, BLoC fetch: `.agents/skills/add-endpoint/SKILL.md` per endpoint (replace the scaffold's placeholder path).
2. State beyond one fetch (forms, search, paging, events, session): `.agents/skills/manage-state/SKILL.md`.
3. Once BLoC tests pass, drop raw JSON and test logs from context; carry only the stream contract, model fields, UI states and the criteria.
4. UI: the page owns the BLoC and binds `data$` with `AppResponseBuilder`; the content widget gets the parsed model, never the BLoC or a stream. `.agents/skills/build-ui/SKILL.md`.
5. Strings: move the scaffold's hardcoded AppBar title and every new string to `context.l10n`, in both `lib/l10n/app_en.arb` and `lib/l10n/app_hi.arb`.

## 4. Navigation in
Add the entry point the spec names with `context.push(Routes.<constant>)` (`context.go` replaces the stack, e.g. after sign-in). Pass ids as path or query parameters (`/orders/:id`, read with `state.pathParameters` in the `GoRoute` builder) so a deep link opens the same screen; `extra` only for objects no link ever carries. Apps still on `onGenerateRoute` use `Navigator.pushNamed` and `RouteSettings.arguments`. Never `Navigator.push(MaterialPageRoute(...))` a screen others may link to.

## 5. Tests from the criteria
Keep the 7 generated BLoC tests green, adapted to the real model, and add one test per criterion (BLoC for logic, widget test for conditional UI): `.agents/skills/write-tests/SKILL.md`.

## 6. Done means
- `verify.dart` passes (not `--fast` alone); failures → `.agents/skills/fix-bug/SKILL.md`. Maestro smoke at milestones (`AGENTS.md` §4).
- No placeholder path, `TODO(<feature>)`, sample field or hardcoded string left from the scaffold.
- Every criterion ticked or moved to Open questions; delete the spec once the feature ships (`AGENTS.md` §6) and record anything a future agent would get wrong (`evolve-harness`).
