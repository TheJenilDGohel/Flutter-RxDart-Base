# `harness` Brick

Makes AI coding agents (Claude Code, Codex, Cursor, Copilot, Gemini CLI, ...) build your app the way this architecture expects, and get better at it over time. Installed by `project` when `include_harness` is on (the default), or on its own:

```bash
mason make harness --project_name my_app \
  --android_package_name com.acme.my_app --ios_bundle_id com.acme.my-app
```

The brick has no hooks and does not edit `pubspec.yaml`. `project` adds the `redux_rxdart_lints` analyzer plugin in `analysis_options.yaml`; on an existing project, add it yourself (see [`redux_rxdart_lints`](../../packages/redux_rxdart_lints/README.md)).

---

## What your app gets

| Path | What it does |
|---|---|
| `AGENTS.md` | The rulebook every agent reads: architecture, 13 golden rules (🔒 = enforced by lints), skill index, tooling, memory. Everything below the `harness:project-rules` marker is yours. |
| `CLAUDE.md` | Claude Code's entry: imports `AGENTS.md`, adds the app ids, loads `.harness/active-context.md`. |
| `.agents/skills/` | Eight skills, one per kind of work (table below). Claude Code reads the entry points in `.claude/skills/`. |
| `.claude/rules/` | Path-scoped rules loaded on-demand: `bloc.md`, `ui.md`, `endpoints.md`, `testing.md`. |
| `.claude/agents/` | Specialist subagent swarm: `@bloc-specialist`, `@ui-artisan`, `@device-qa`, `@flutter-qa`, `@skeptic`, `@docs-scout`. |
| `scripts/agent/on_edit.dart` | Fast (<1.5s) in-flight format and analyze check on touched files. |
| `scripts/team/` | Distributed swarm coordination: `task_handoff.dart` and `heartbeat.dart` (`.harness/team-protocol.md`). |
| `.maestro/` | Declarative E2E mobile testing flows (`flows/smoke_launch.yaml`). |
| `scripts/agent/verify.dart` | The quality gate: format → analyze (including architecture lints) → tests → lessons → snapshot (`--fast` = format + analyze). |
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
| `manage-state` | Where state lives; BLoC recipes (submit, search, pagination, events, several loads, timers); Redux changes |
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

Coordination works across single-terminal in-process handoffs and concurrent multi-session Git worktrees (`.worktreeinclude`) via `scripts/team/task_handoff.dart` and `scripts/team/heartbeat.dart` (`.harness/team-protocol.md`).

### Declarative Device Automation (Maestro)

Mobile QA runs deterministically without token-draining screenshot OCR or raw accessibility trees:
- Flows live in `.maestro/flows/` (e.g. `smoke_launch.yaml`).
- Pre-approved in `.mcp.json` (`maestro mcp`) and CLI (`maestro test .maestro/flows/smoke_launch.yaml`).
- Subagent `@device-qa` drives full user journeys across real emulators and devices.

### 5-Tier Memory & Self-Learning Architecture

Instead of a ceremonial task close-out tax that inflates prompt context, memory is structured in five tiers:
1. **Tier 1 (Ambient)**: Claude Code Auto-Memory (`MEMORY.md` + Auto-Dream) captures personal session insights without manual friction.
2. **Tier 2 (Structured Knowledge Graph)**: `@modelcontextprotocol/server-memory` registered in `.mcp.json` stores technical domain entities, relations, and observations locally with **0 baseline prompt tokens**.
3. **Tier 3 (Path-Scoped Rules)**: Invariant standards codified in `.claude/rules/*.md` (`bloc.md`, `ui.md`, `endpoints.md`, `testing.md`) load only when editing matching files.
4. **Tier 4 (Permanent Team Rules)**: Non-negotiable team rules live below `harness:project-rules` in `AGENTS.md` §7.
5. **Tier 5 (Offline CLI)**: `scripts/agent/learn.dart` remains available for offline CLI tracking and packaging upstream proposals (`learn.dart upstream`).

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

See [`CHANGELOG.md`](CHANGELOG.md) for version history.
