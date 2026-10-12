# {{project_name}} — Claude Code memory

@AGENTS.md

## Claude Code specifics
- Android package `{{android_package_name}}`, iOS bundle id `{{ios_bundle_id}}`.
- Skills in `.claude/skills/` (listed in AGENTS.md §4) carry the procedures: `add-feature`, `add-endpoint`, `manage-state`, `build-ui`, `write-tests`, `fix-bug`, `evolve-harness`, and `flutter-senior-dev` for planning and review. Invoke the matching one before starting work.
- Path-scoped architecture rules in `.claude/rules/` (`bloc.md`, `ui.md`, `endpoints.md`, `testing.md`) dynamically enforce golden rules when files are edited.
- Specialist swarm in `.claude/agents/`: `@bloc-specialist`, `@ui-artisan`, `@device-qa` (Maestro device testing), `@flutter-qa` (architecture review), `@skeptic` (hostile design reviewer), and `@docs-scout` (fast documentation digest).
- Coordination: single-terminal in-process or multi-session Git worktrees via `scripts/team/task_handoff.dart` (`.harness/team-protocol.md`).
- Fast verification: `dart run scripts/agent/on_edit.dart` after modifying files.
- Memory & learning: Ambient session learning is handled via Claude Code Auto-Memory; persistent project domain facts live in the MCP Knowledge Graph (`mcp__memory`) or `.claude/rules/`. `dart run scripts/agent/learn.dart` is pre-approved for offline CLI tracking.
- Context hygiene: Run `/clear` when switching tasks to keep sessions under 50k context. Run `/compact` mid-task after completing a layer (e.g. data + BLoC done, before UI). Grep or read line ranges rather than loading entire large files into context.
- MCP servers: `dart` (`mcp__dart__*`), `maestro` (`mcp__maestro__*`), and `memory` (`mcp__memory__*`) are pre-approved in `.mcp.json`.
- In FVM projects (`.fvm/` or `.fvmrc`), prefix CLI commands with `fvm` (e.g. `fvm dart run scripts/agent/verify.dart`, `fvm flutter test`).

<!-- harness:project-rules — Everything below this line is yours. `upgrade.dart` keeps it verbatim. -->

---
@.harness/active-context.md
