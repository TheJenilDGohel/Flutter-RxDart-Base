# {{project_name}} — Claude Code memory

@AGENTS.md

## Claude Code specifics
- Android package `{{android_package_name}}`, iOS bundle id `{{ios_bundle_id}}`.
- Skills in `.claude/skills/` (listed in AGENTS.md §4) carry the procedures: `add-feature`, `add-endpoint`, `manage-state`, `build-ui`, `write-tests`, `fix-bug`, `evolve-harness`, and `flutter-senior-dev` for planning and review. Invoke the matching one before starting work.
- Path-scoped architecture rules in `.claude/rules/` (`bloc.md`, `ui.md`, `endpoints.md`, `testing.md`) dynamically enforce golden rules when files are edited.
- Specialist swarm in `.claude/agents/`: `@bloc-specialist`, `@ui-artisan`, `@device-qa` (Maestro device testing), `@flutter-qa` (architecture review), `@skeptic` (hostile design reviewer), and `@docs-scout` (fast documentation digest).
- Coordination: single-terminal in-process or multi-session Git worktrees via `scripts/team/task_handoff.dart`, `scripts/team/heartbeat.dart`, and `scripts/team/worktree.dart` (`.harness/team-protocol.md`).
- Fast verification & diagnostics: `dart run scripts/agent/on_edit.dart` after modifying files, or check `.harness/diagnostics.json` if `dart run scripts/agent/watch.dart` is running.
- Context & token hygiene: Run `/clear` when switching tasks to keep sessions under 50k context. Run `/compact` mid-task after completing a layer. Read `.harness/system-snapshot.md` before searching files. Never read generated serialization (`*.g.dart`, `*.freezed.dart`). Delegate library/API research to `@docs-scout`.
- MCP servers: `dart` (`mcp__dart__*`), `maestro` (`mcp__maestro__*`), and `memory` (`mcp__memory__*`) are pre-approved in `.mcp.json`.
- Plugins in `.claude/plugins/`: `golden-guard` (stop gate + `/audit`), `session-flow` (status bar + `/pickup` & `/handoff`), and `output-compactor` (compact test failure summaries).
- In FVM projects (`.fvm/` or `.fvmrc`), prefix CLI commands with `fvm` (e.g. `fvm dart run scripts/agent/verify.dart`, `fvm flutter test`).

<!-- harness:project-rules — Everything below this line is yours. `upgrade.dart` keeps it verbatim. -->

---
@.harness/active-context.md
