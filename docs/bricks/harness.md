# `harness` Brick

Makes AI coding agents (Claude Code, Codex, Cursor, Copilot, Gemini CLI, ...) build your app the way this architecture expects, and get better at it over time. Installed by `project` when `include_harness` is on (the default), or on its own:

```bash
mason make harness --project_name my_app \
  --android_package_name com.acme.my_app --ios_bundle_id com.acme.my-app
```

The brick has no hooks and does not edit `pubspec.yaml`. `project` adds the `redux_rxdart_lints` analyzer plugin in `analysis_options.yaml`; on an existing project, add it yourself (see [`redux_rxdart_lints`](../packages/redux_rxdart_lints.md)).

---

## What your app gets

| Path | What it does |
|---|---|
| `AGENTS.md` | The rulebook every agent reads: architecture, 15 golden rules (🔒 = enforced by lints), skill index, tooling, memory. Everything below the `harness:project-rules` marker is yours. |
| `CLAUDE.md` | Claude Code's entry: imports `AGENTS.md`, adds the app ids, loads `.harness/active-context.md`. |
| `.agents/skills/` | Eight skills, one per kind of work (table below). Claude Code reads the entry points in `.claude/skills/`. |
| `.claude/rules/` | Path-scoped rules loaded on-demand: `bloc.md`, `ui.md`, `endpoints.md`, `testing.md`. |
| `.cursor/rules/` | Cursor path-scoped rules with glob frontmatter: `bloc.mdc`, `ui.mdc`, `endpoints.mdc`, `testing.mdc`. |
| `.claude/plugins/` | Pre-bundled Claude Code mods (v2.4.x): `golden-guard` (stop-time golden rules gate + `/audit`), `session-flow` (statusline + `/pickup` & `/handoff`), and `output-compactor` (failure trace compactor). |
| `.claude/agents/` | Specialist subagent swarm: `@bloc-specialist`, `@ui-artisan`, `@device-qa`, `@flutter-qa`, `@skeptic`, `@docs-scout`. |
| `scripts/agent/on_edit.dart` | Fast (<1.5s) in-flight format/analyze check with compact error stripping and anti-loop circuit breaker. |
| `scripts/agent/watch.dart` | Background incremental diagnostics watcher updating `.harness/diagnostics.json` with zero token overhead. |
| `scripts/agent/ingest_contract.dart` | Ingests OpenAPI/Postman JSON contracts to generate models with defensive parsing (Rule 12), mock fixtures, and endpoint constants. |
| `scripts/team/` | Distributed swarm coordination: `task_handoff.dart` (messaging & human blockers), `heartbeat.dart`, and `worktree.dart` (`.harness/team-protocol.md`). |
| `.maestro/` | Declarative E2E mobile testing flows (`flows/smoke_launch.yaml`). |
| `scripts/agent/verify.dart` | The quality gate: format → analyze (including architecture lints) → tests → lessons → snapshot with framework stack trace pruning. |
| `scripts/agent/wire_route.dart` | Scaffolds a feature with `mason make bloc` if missing, then adds its route. |
| `scripts/agent/learn.dart` | The lessons loop (below). |
| `scripts/agent/upgrade.dart` | Upgrades the harness without touching your work (below). |
| `.claude/` | Settings (Token Shield, 1h cache TTL, multiplexing), skill entry points, specialist subagents. |
| `.mcp.json`, `.cursor/mcp.json` | Dart MCP server, Maestro device automation, and Anthropic Knowledge Graph memory server. |
| `.harness/` | Memory: `active-context.md`, `progress.md`, `lessons.md`, `team-protocol.md`, generated `system-snapshot.md`, `version.json`. Agents add skill overlays (`skills/<skill>.md`) and specs (`specs/<feature>.md`). |

### Skills & Production Recipes

| Skill | Use it for |
|---|---|
| `add-feature` | A new screen or flow: contract → spec → scaffold → layers → tests → gate |
| `add-endpoint` | Any API work: transport-only repo, defensive model, BLoC call, tests with real JSON (backed by `repo-recipes.md`) |
| `manage-state` | Where state lives; BLoC recipes (submit, search, pagination, events, several loads, timers); storage & offline cache recipes; Redux changes |
| `build-ui` | Page/content split, tokens, ScreenUtil, l10n, shared widgets, dialogs, accessibility |
| `write-tests` | BLoC, model, widget, reducer, regression tests, and Maestro device journeys |
| `fix-bug` | Symptom → layer table, every gate step and lint rule |
| `evolve-harness` | Tiered memory, Knowledge Graph observations, path rules, and project skills |
| `flutter-senior-dev` | Planning, architecture decisions, review |

Codex, Gemini CLI and OpenCode read `.agents/skills/`. Claude Code reads `.claude/skills/`. Cursor reads both. Production repository recipes (CRUD filters, capability mixins, multipart upload, unpaginated fetch, binary streaming, cache-aside) are detailed in `.agents/skills/add-endpoint/repo-recipes.md`.

### Specialist Agent Swarm & Team Coordination

Tasks multiplex across lean, role-bounded subagents in `.claude/agents/` configured with `omitClaudeMd: true` to prevent cache invalidation:
- `@bloc-specialist`: RxDart stream lifecycles, composite subscriptions, emit guards.
- `@ui-artisan`: ScreenUtil public widgets, ResColors tokens, `AppResponseBuilder`, zero `setState`.
- `@device-qa`: Declarative end-to-end device testing via Maestro CLI and MCP.
- `@flutter-qa`: Conformance audits, boundary checks, and custom lints.
- `@skeptic`: Adversarial plan reviewer attacking reactive designs before coding begins.
- `@docs-scout`: Token-efficient package and documentation researcher (<200 words).

Coordination works across single-terminal in-process handoffs and concurrent multi-session Git worktrees (`.worktreeinclude`) via `scripts/team/task_handoff.dart`, `scripts/team/heartbeat.dart`, and `scripts/team/worktree.dart` (`.harness/team-protocol.md`).

### Pre-Bundled Claude Code Plugins & Interactive Commands (v2.4.x)

Harness v2.4.x bundles three native Anthropic Claude Code plugins located in `.claude/plugins/`:
- **`golden-guard`**: A stop-time verification hook (`classic.Stop`) enforcing Golden Rules (R1, R2, R3, R4, R13) and design tokens before finishing any turn, plus the on-demand `/audit` command.
- **`session-flow`**: Real-time terminal status line (`$.ui.status`) showing current branch, dirty files, unpushed commits, and worktree count. Provides deterministic session bookends:
  - `/pickup [task]`: Resumes work by auto-detecting uncommitted WIP and parsed `- [ ]` checklist items from `.harness/active-context.md`, presenting an interactive selection menu.
  - `/handoff`: Performs pre-commit hygiene, verifies gates, and saves clean task hand-off notes.
- **`output-compactor`**: Intercepts `Bash` command failures (`maestro test`, `flutter test`, `dart analyze`), stripping verbose framework stack traces while preserving root-cause error banners and line numbers.

### Universal Foundation vs IDE Enhancements

| Tier | Supported Agents | What it Provides |
|---|---|---|
| **Universal Foundation** | Cursor, Codex, Gemini CLI, Claude Code | `AGENTS.md` locked Golden Rules, `redux_rxdart_lints`, `.agents/skills/`, and pre-commit verification (`scripts/agent/verify.dart`, `wire_route.dart`). |
| **Cursor Path Rules** | Cursor IDE | `.cursor/rules/*.mdc` glob-frontmatter rules (`bloc.mdc`, `ui.mdc`, `endpoints.mdc`, `testing.mdc`) and `.cursor/mcp.json`. |
| **Claude Code Enhancements** | Claude Code CLI | Pre-bundled plugins (`.claude/plugins/`), 1h prompt caching (`promptCacheTtl: "1h"`), specialist swarm (`.claude/agents/`), and `/pickup` session flows. |


### Token Conservation & High-Efficiency Operations

Token waste is eliminated systematically across all agent interactions:
- **Fast In-Flight Checks & Anti-Loop Circuit Breaker**: `dart run scripts/agent/on_edit.dart` strips analyzer noise and halts runaway retry loops with exit code 2 on the 3rd consecutive identical failure.
- **Framework Stack Trace Pruning**: `scripts/agent/verify.dart` prunes internal Flutter framework traces (`package:flutter/src/`, `test_api/`, `dart:async/`), delivering ~80% token savings on test/build failures.
- **Layer-Boundary Compaction Protocol**: Skills (`add-feature`, `build-ui`) enforce explicit checkpoints between BLoC tests and UI creation, dropping raw network schemas and test output.
- **Background Watcher**: `dart run scripts/agent/watch.dart` provides live status in `.harness/diagnostics.json` without spawning extra processes.
- **Token Shield**: `.claude/settings.json` enforces `bashOutputMaxChars: 3000`, 1h prompt cache TTL, and denies reads to generated serialization files (`*.g.dart`, `*.freezed.dart`, `build/`, `.dart_tool/`).
- **Research Offload**: `@docs-scout` uses Haiku and enforces <200 word digests for library/API documentation.
- **System Snapshot**: `.harness/system-snapshot.md` eliminates expensive directory sweeps and repetitive tool calls.

### Declarative Device Automation (Maestro)

Mobile QA runs deterministically without token-draining screenshot OCR or raw accessibility trees:
- Flows live in `.maestro/flows/` (e.g. `smoke_launch.yaml`).
- Pre-approved in `.mcp.json` (`maestro mcp`) and CLI (`maestro test .maestro/flows/smoke_launch.yaml`).
- Subagent `@device-qa` drives full user journeys across real emulators and devices.

### Grounded RAG & Tiered Memory Architecture

Memory and context retrieval are structured to eliminate token bloat and administrative ceremony:
1. **Tier 1 (Compiler & Symbol Grounding - LSP RAG)**: `mcp__dart` retrieves ground-truth definitions, signatures, and types on demand without file dumping.
2. **Tier 2 (Deterministic Path Rules)**: Invariant standards in `.claude/rules/*.md` (`bloc.md`, `ui.md`, `endpoints.md`, `testing.md`) inject layer context only when matching files are opened (0 baseline prompt tokens).
3. **Tier 3 (Ambient Session Memory)**: Claude Code Auto-Memory (`MEMORY.md` + Auto-Dream) captures transient workflow context without manual journaling.
4. **Tier 4 (Permanent Team Rules)**: Non-negotiable global conventions live below `harness:project-rules` in `AGENTS.md` §7.
5. **Tier 5 (Offline CLI & Sync)**: `scripts/agent/learn.dart` remains available for offline team review and upstream proposals (`learn.dart upstream`).
- **No Close-Out Tax**: Routine bugfixes and UI tweaks skip close-out completely; only major features or milestones update `.harness/active-context.md`.

---

## Upgrading

```bash
dart run scripts/agent/upgrade.dart                 # latest upstream release
dart run scripts/agent/upgrade.dart --check-only    # just report
```

- **What it renders:** the harness from `upstream_repo` in `.harness/version.json`, in a throwaway mason workspace. A `mason.yaml` pin in your project or a stale `mason add -g` copy can't hold you back. `--ref <git-ref>` picks a branch, tag or commit; `--brick <dir>` uses a local brick. Offline, it falls back to your registered brick and says so.
- **What it changes:** every file the brick ships in `scripts/agent/` and the shipped skills, the QA subagent, and the part of `AGENTS.md`/`CLAUDE.md` above the marker.
- **What it keeps:** `.harness/` (memory, lessons, overlays, specs), skills you created, everything below the marker, your `.claude/settings.json` and `.mcp.json` (it lists what they lack, and hooks that run missing scripts), and any file in `scripts/agent/` it doesn't ship.
- **Safety:** nothing changes unless rendering succeeds; every touched file is backed up to `.harness/.backup_<timestamp>/` (last three kept); it never downgrades without `--force`; when the new version ships a different `upgrade.dart`, the new one applies the upgrade.
- Pre-1.6 `AGENTS.md`/`CLAUDE.md` (no marker): every line no harness template contained is kept below the marker, under "Kept from your previous version of this file".

### Upgrading from 1.7.0 or older

The installed `upgrade.dart` runs the upgrade, and engines up to 1.7.0 render whichever `harness` brick mason resolves (your project's `mason.yaml` pin first), replace `scripts/agent/` wholesale, and drop team lines from pre-1.6 contracts. Install the current engine first, then run it:

```bash
curl -sSL https://raw.githubusercontent.com/jenilseawind-glitch/Flutter-RxDart-Base/main/bricks/harness/__brick__/scripts/agent/upgrade.dart -o scripts/agent/upgrade.dart
dart run scripts/agent/upgrade.dart
```

Your app ids come from `.harness/version.json` (or, for old projects, `CLAUDE.md` and the platform files), never a `com.example` guess. After upgrading, add `"Bash(dart run scripts/agent/learn.dart:*)"` to `.claude/settings.json` if the upgrade lists it.

---

See [`CHANGELOG.md`](https://github.com/jenilseawind-glitch/Flutter-RxDart-Base/blob/main/bricks/harness/CHANGELOG.md) for version history.
