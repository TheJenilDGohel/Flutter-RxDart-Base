# Multi-Agent Swarm Protocol

Guidelines for single-terminal multiplexing and concurrent multi-session agent swarms.

## 1. Operating Modes

### Mode A: Single-Terminal Multiplexing (`teammateMode: "in-process"`)
- Specialists run sequentially or cooperatively within a single terminal window.
- Inbound cross-session messages are handled cooperatively.
- Ideal when working on a single branch without requiring multiple windows or terminal multiplexers.

### Mode B: Concurrent Multi-Session Swarm (`teammateMode: "auto"` / Git Worktrees)
- Multiple terminal sessions, windows, or tmux panes run independently and in parallel.
- Each session registers via `dart run scripts/team/task_handoff.dart register-session --session "<session_id>" --agent "<agent>"`.
- To avoid working directory and Git index contention across concurrent sessions:
  - Automate worktree provisioning: `dart run scripts/team/worktree.dart create <feature_branch>`.
  - `.worktreeinclude` automatically mirrors local `.env`, `.claude/`, and `.harness/` configuration into new worktrees.
- Atomic file writes in `task_handoff.dart` guard `.harness/tasks/active.json` against concurrent file-write corruption.

## 2. Layer Isolation & File Locks
To eliminate merge conflicts across sessions, each agent role strictly owns its architectural layer:
- `@bloc-specialist`: Owns `lib/features/<name>/bloc/`, `lib/features/<name>/repo/`, and `lib/features/<name>/model/`.
- `@ui-artisan`: Owns `lib/features/<name>/widgets/`, `lib/features/<name>/<name>_page.dart`, and `lib/utils/widgets/ui/`.
- `@device-qa`: Owns `.maestro/flows/` and end-to-end device test execution.
- `@flutter-qa`: Read-only architecture reviewer.
- `@skeptic`: Read-only adversarial plan reviewer (attacks designs before code is written).
- `@docs-scout`: Read-only documentation and API researcher (token-shielded digests).

## 3. Distributed Task Lifecycle & Concurrency Control
1. **Discover**: Check pending work with `dart run scripts/team/task_handoff.dart list` and check mailbox with `dart run scripts/team/task_handoff.dart inbox --agent "<agent>"`.
2. **Claim**: Claim a task: `dart run scripts/team/task_handoff.dart claim --id "<id>" --assignee "<agent>" --session "<session_id>"`.
   - If another session already claimed the task, the script rejects the claim with a concurrency conflict.
3. **Execute**: Develop exclusively within the assigned role's directory boundary.
4. **Fast Verify**: Run `dart run scripts/agent/on_edit.dart` on touched files (<1.5s) or check `.harness/diagnostics.json` from `dart run scripts/agent/watch.dart`.
5. **Human Blocker (if needed)**: If user decision/clarification is needed, pause task: `dart run scripts/team/task_handoff.dart wait-human --id "<id>" --reason "<reason>"`. Resume once decided: `dart run scripts/team/task_handoff.dart resume --id "<id>"`.
6. **Message / Handoff**: Notify peer agents: `dart run scripts/team/task_handoff.dart send --to "<agent>" --subject "<title>" --body "<body>"`.
7. **Complete**: Mark complete: `dart run scripts/team/task_handoff.dart complete --id "<id>" --summary "<summary>" --session "<session_id>"`.
8. **Inspect Swarm**: Run `dart run scripts/team/heartbeat.dart` for a one-line summary of sessions, tasks, and human blockers.

## 4. Context & Cache Hygiene
- Subagents set `omitClaudeMd: true` to prevent re-ingesting top-level instructions into prompt cache.
- Path-scoped rules in `.claude/rules/` automatically supply layer-specific guidelines when relevant files are touched.
- Keep agent descriptions under 25 words to minimize system prompt token footprints.
