---
name: add-feature
description: Builds a new screen or user flow end to end on this Flutter Redux + RxDart + Dio base - API contract, a short spec with acceptance criteria, scaffold and route (wire_route.dart / mason make bloc), endpoint, repo, model, BLoC, page, l10n strings, tests and the quality gate. Use whenever asked to add, create, build or implement a screen, page, feature, module or flow, even for a one-line request like "add a profile screen".
---

# Add a feature

Spec first, scaffold second, then fill in from the network up, and finish with a green gate. The rules live in `AGENTS.md` §2; this file is the procedure. Don't skip steps because the request looks small: the shortcuts are where agent-written features break.

## 0. Load what this project learned
1. Read `.harness/skills/add-feature.md` if it exists. It holds this project's own additions and wins over this file when they disagree.
2. Check the Knowledge Graph (`search_nodes` / `read_graph`) or run `dart run scripts/agent/learn.dart list add-feature`.
3. Read `.harness/system-snapshot.md`: existing features, routes and endpoints. Extend an existing feature instead of creating a near-duplicate.

## 1. Pin the contract
Find the API contract in `AGENTS.md` §3 order: `*.postman_collection.json`, OpenAPI/Swagger files, then docs. For every endpoint you need: method, path, request body, one real success response and the error shape.

No contract → stop and ask for a sample response. An invented response shape compiles, passes the generated tests and fails on the first real request.

## 2. Write the spec
Create `.harness/specs/<feature>.md` (the folder too, if missing). Keep it under ~30 lines:

```
# <feature>
Route: /<path> · Reached from: <screen, tab, deep link>
Endpoints: GET /... (contract: <file or link>)
States: loading · empty · error + retry · success  [· offline · no permission · partial]
Acceptance criteria:
- [ ] AC1: Given ..., when ..., then ...
- [ ] AC2: ...
Out of scope: ...
Open questions: ...
```

Each criterion becomes at least one test in step 6. If the request was vague (no states, no source of data, unclear role), confirm the spec with the user before writing code. Otherwise state your assumptions in the spec and carry on.

## 3. Scaffold and route
```
dart run scripts/agent/wire_route.dart <feature_name> [/route-path]
```
This runs `mason make bloc` when `lib/features/<feature_name>/` is missing, then adds the `Routes` constant and the `AppRouter` case. It refuses to run when `go_router` or `auto_route` is a dependency; wire the route by hand there.

Run `dart run scripts/agent/verify.dart --fast` straight away. A green start means every later failure is yours and easy to locate.

## 4. Fill in, network first
Work in this order, keeping the gate green as you go (`dart run scripts/agent/on_edit.dart` on touched files for sub-second feedback):

1. **Endpoint, repo, model, BLoC fetch**: follow `.agents/skills/add-endpoint/SKILL.md` for each endpoint. The scaffold's repo calls a placeholder path, so replace it.
2. **Screen state beyond one fetch** (forms, search, pagination, events, session changes): follow `.agents/skills/manage-state/SKILL.md`.

> [!TIP]
> **Boundary Checkpoint (Context Compaction):** Once BLoC unit tests pass green, drop network payload schemas, raw JSON payloads, and test execution logs from active context before building UI. Carry forward ONLY:
> 1. The public `Stream<ApiResponse<T>>` / `data$` contract.
> 2. The parsed model field names and types.
> 3. The UI state transitions (loading, empty, error, data).
> 4. Acceptance criteria from the spec.
> Pruning raw HTTP traces and compiler noise saves 60-80% of context tokens during widget implementation.

3. **UI**: the page owns the BLoC and binds `data$` with `AppResponseBuilder`. The content widget receives the parsed model, never the BLoC or a stream. Follow `.agents/skills/build-ui/SKILL.md`.
4. **Strings**: the scaffold's AppBar title is a hardcoded `Text`. Move it and every new string to `context.l10n`, adding each key to both `lib/l10n/app_en.arb` and `lib/l10n/app_hi.arb`.

## 5. Navigation in
`wire_route.dart` makes the route reachable by name only. Add the entry point the spec names (a button, list tile, tab or drawer item) with `Navigator.pushNamed(context, Routes.<constant>)`. Pass arguments through `RouteSettings.arguments` and read them in the `AppRouter` case. Never `Navigator.push(MaterialPageRoute(...))` a screen another feature might link to.

## 6. Tests from the acceptance criteria
Keep the 7 generated BLoC tests passing and adapt them to the real model. Then add one test per acceptance criterion: BLoC tests for state and logic, a widget test for the content widget when it has conditional UI. See `.agents/skills/write-tests/SKILL.md`.

## 7. Gate, spec, close out
1. In-flight check: `dart run scripts/agent/on_edit.dart` on touched files.
2. Full quality gate: `dart run scripts/agent/verify.dart` until it passes: format, analyze, architecture lints, tests, lessons, snapshot. Failures: `.agents/skills/fix-bug/SKILL.md`.
3. Device smoke test (if emulators/devices connected): `maestro test .maestro/flows/smoke_launch.yaml`.
4. Tick the criteria in the spec. Move anything you didn't do into its "Open questions".
5. Close out per `AGENTS.md` §6: update `.harness/active-context.md`, then record anything a future agent would otherwise get wrong (`.agents/skills/evolve-harness/SKILL.md`, step 1).

## Done means
- The spec exists and every criterion is ticked or explicitly deferred.
- No placeholder path, `TODO(<feature>)`, sample model field or hardcoded string is left from the scaffold.
- The full gate passes. Don't report done on `--fast` alone.
