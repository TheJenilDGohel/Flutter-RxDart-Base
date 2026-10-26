# AI Harness R&D (October 2026)

**Question:** the AI layer felt like the weakest part of the bricks. What is actually wrong with it, what do current tools support, and what should we build?

**Short answer:** the harness's *content* was decent, but its *wiring* was weak. The main target, Claude Code, never loaded most of it. It also relied on agents remembering rules instead of running tools. Harness **1.6.0** fixes the wiring and adds feedback loops. The biggest remaining gap is that we cannot yet *measure* whether the harness makes agents better, so an eval suite is the top roadmap item.

## How this was evaluated

- Read every harness file, then generated a real app (Flutter 3.47.6 / Dart 3.13.5) with `project` + `harness` + `bloc` and exercised each piece.
- Checked current agent-tool conventions: [AGENTS.md](https://www.morphllm.com/agents-md-guide) (Linux Foundation / Agentic AI Foundation, read natively by Codex, Copilot, Cursor, Gemini CLI, and by Claude Code [when no CLAUDE.md exists](https://www.highcircl.com/en/blog/claude-code-agents-md-support)), the [Agent Skills standard](https://codex.danielvaughan.com/2026/05/05/agent-skills-open-standard-portable-skills-codex-cli-cross-agent/) (`SKILL.md`; `.agents/skills/` for Codex/OpenCode, `.claude/skills/` for Claude Code, [Cursor reads both](https://cursor.com/docs/skills)), Claude Code [subagent discovery](https://code.claude.com/docs/en/sub-agents) (`.claude/agents/`), the [official Dart & Flutter MCP server](https://docs.flutter.dev/ai/tools), Flutter's [AI rules](https://docs.flutter.dev/ai/ai-rules), and the first-party [analyzer plugin system](https://dart.dev/tools/analyzer-plugins).
- Probed `dart mcp-server` over stdio, and ran the hook, gate, snapshot and upgrade against real files.

## Findings (before 1.6.0), most severe first

| # | Problem | Evidence | Effect on agents |
|---|---|---|---|
| 1 | **Claude Code never saw the golden rules** | `CLAUDE.md` said "the full contract lives in `AGENTS.md`" but did not import it. Claude Code only falls back to `AGENTS.md` when there is *no* `CLAUDE.md`. | The 12 rules were in context only if the model chose to open another file. |
| 2 | **Skill and QA agent were in folders Claude Code doesn't scan** | Claude Code discovers `.claude/skills/` and `.claude/agents/`; the harness shipped `.agents/skills/` and `.agents/agents/`. | The senior-dev skill and `flutter-qa` were never auto-offered. |
| 3 | **No machine feedback while editing** | Everything depended on the agent remembering to run `verify` at the end. | Errors piled up across files before anyone saw them. |
| 4 | **Agents couldn't use Dart tooling directly** | No MCP config, although the SDK ships `dart mcp-server`. | Agents guessed APIs and shelled out, with no runtime view of the app. |
| 5 | **The gate didn't run tests**; a fresh app failed its own format gate | `verify.sh` was format + analyze + lints + snapshot. 26 generated files were unformatted under the Dart 3.13 formatter. | "All gates passed" did not mean the code worked. Day-one agents hit a red gate they did not cause. |
| 6 | **Reference docs were stale and contradicted the code** | `architecture.md` described harness 1.1.0 (OverlaySupport, `screens/`, 8 exceptions, empty `model/`). The skill sent shared widgets to `utils/widgets/common/` (doesn't exist). Rule 11 described token behaviour that is now wrong. | Confidently wrong code. This is the worst failure mode, because agents trust these files. |
| 7 | **`upgrade.dart` could silently damage projects** | It stamped success when `mason make` failed, overwrote app ids with `com.example.<name>`, duplicated the memory transclusion on every run, and its test exercised a *different copy* of the engine. | Upgrades were unsafe to run unattended. |
| 8 | **Snapshot was noisy** | A timestamp and git log changed it on every run, and it ran a second full analyzer pass. | Committing it produced diff noise; leaving it out lost it. |

## What 1.6.0 changes

| Problem | Change | Verified by |
|---|---|---|
| 1 | `CLAUDE.md` = `@AGENTS.md` + Claude-specific notes + memory transclusion | Generated file inspected |
| 2 | `.claude/skills/flutter-senior-dev/` entry point → shared skill; `flutter-qa` moved to `.claude/agents/` | Upgrade test asserts the move |
| 3 | `PostToolUse` hook → `scripts/agent/on_edit.dart`: formats and analyzes each edited Dart file and returns issues with exit 2 | Clean file → 0; broken file → formatted, diagnostics, 2; non-Dart and garbage input → 0 |
| 4 | `.mcp.json` / `.cursor/mcp.json` register `dart mcp-server`, and it is pre-approved in Claude Code | Server v1.1.2 handshake: 14 tools (`analyze_files`, `lsp`, `pub`, `pub_dev_search`, `read_package_uris`, `hot_reload`, `hot_restart`, `get_runtime_errors`, `widget_inspector`, `flutter_driver_command`, …) |
| 5 | `verify.dart`: format → analyze → custom lints → **tests** → snapshot (`--fast` mode). `project` and `bloc` hooks format their output. | Generated app: 5/5 gates pass. The base repo's smoke test now uses the strict format check. |
| 6 | Content rewritten against the generated code, and the skill points at `AGENTS.md` instead of restating rules. **New `tool/harness_check.dart` in CI** fails when harness docs name a path, project type or lint rule the bricks don't generate. | Catches an invented `AppStreamView`; passes on the real docs |
| 7 | `upgrade.dart` rewritten: no change unless rendering succeeds, ids kept in `version.json`, `harness:project-rules` marker merge, legacy migration, backups, history, `$GITHUB_OUTPUT` | `tool/test_harness_upgrade.dart`: 23/23 checks on the real script, including idempotent re-runs |
| 8 | Deterministic snapshot (features without tests, routes, endpoints, state fields, deps), with no analyzer re-run | Second run reports "unchanged" |

Also new: golden rule 13 (lint-enforced), a permission allowlist for safe dev commands, a deny-list for force-push and signing keys, and `bash scripts/agent/verify.sh` (mason drops the executable bit).

**Measured gate cost on a fresh app:** format 0.3 s, analyze 4.2 s, custom_lint **40.1 s**, tests 13.8 s, snapshot 0.4 s. custom_lint takes about two-thirds of the gate, and it is why the edit hook can only run the analyzer.

## What 1.7.0 adds: task skills and a learning loop

1.6.0 made agents *load* the harness. 1.7.0 gives them a procedure for each kind of work, and a way to keep what they learn.

| Gap after 1.6.0 | 1.7.0 change |
|---|---|
| One planning skill; hands-on work (an endpoint, a paginated list, a red gate) had only the golden rules to go on | Seven task skills: `add-feature`, `add-endpoint`, `manage-state`, `build-ui`, `write-tests`, `fix-bug`, `evolve-harness`. Each is a numbered procedure with exact commands, cites rules instead of restating them, and is checked by `tool/harness_check.dart`. |
| Subtle BLoC concurrency was left to the agent: one cancel token shared by two loaders, stale search results, load-more racing a refresh | `manage-state/bloc-recipes.md`: complete recipes. Every CI smoke run pastes them verbatim into a generated app, where they must pass the analyzer, the architecture lints and behavior tests (the double-tap guard, a single debounced search request, load-more failing and racing a refresh, independent sections) |
| Agents repeated a project's mistakes every session; `active-context.md` holds tasks, not lessons | `.harness/lessons.md` + `scripts/agent/learn.dart`. Lessons are recorded at close-out, recalled at each skill's step 0, promoted after a repeat into skill overlays (`.harness/skills/<skill>.md`), `AGENTS.md` §7 or new project skills, and reopened when the rule they became didn't prevent a repeat. `verify` checks the file and surfaces promotion candidates. |
| No path for app-level discoveries to improve the base | The `upstream` promotion target and `learn.dart upstream` collect harness-level lessons for the maintainers. Fixes ship as new skill versions that `upgrade.dart` brings to every app, while project knowledge in `.harness/` and project-created skills is never touched. |

Roadmap item 4 (spec-first workflow) is delivered as the `add-feature` skill, apart from automatic contract-to-code generation. Item 7 (memory hygiene) is partly covered by the lessons loop's stale/duplicate/cap review.

## What 2.0.0 adds: Token Shield, Specialist Swarm, Maestro QA, Repo Recipes, and 5-Tier Memory

Observation of production apps (`AI-LMS-NEW`, `Edu Tech Era`) revealed critical failure modes in the 1.7.0 setup:
1. **Context rot and the flat-file lessons tax**: `lessons.md` grew to 72 entries, polluting prompt contexts with transient local machine IPs (`192.168.29.138`) and emulator bugs. The mandatory close-out questionnaire added unacceptable token overhead.
2. **Generalist context exhaustion**: A single agent attempting to handle networking, BLoC state, UI layouts, and tests in one session quickly hit context degradation.
3. **Vision/OCR test overhead**: Using screenshot OCR or accessibility trees (OpenMob/Appium) consumed tens of thousands of tokens and suffered from timing flakiness.

| Gap after 1.7.0 | 2.0.0 Solution |
|---|---|
| Large monolithic prompt contexts; repetitive rule re-reads across long sessions | **Token Shield (`.claude/settings.json`)**: 1-hour prompt caching (`promptCacheTtl: "1h"`, `subagentPromptCacheTtl: "1h"`), 4KB bash terminal output clamp (`bashOutputMaxChars: 4000`), and strict `permissions.deny` blocking `.dart_tool/`, `build/`, `*.g.dart`, and signing keys. |
| All architecture rules loaded into context upfront regardless of task | **Context-Slicing Path Rules (`.claude/rules/`)**: `bloc.md`, `ui.md`, `endpoints.md`, `testing.md`. Injected dynamically only when matching directories/files are edited (**0 baseline tokens**). |
| Single generalist agent context exhaustion | **Specialist Agent Swarm (`.claude/agents/`)**: Lean subagents (`@bloc-specialist`, `@ui-artisan`, `@device-qa`, `@flutter-qa`) configured with `omitClaudeMd: true` to prevent prompt cache duplication. |
| Inability to run concurrent multi-agent work | **Team Protocol & Worktrees (`.harness/team-protocol.md`)**: Single-terminal in-process handoffs or concurrent Git worktrees (`.worktreeinclude`) coordinated via `scripts/team/task_handoff.dart` and `scripts/team/heartbeat.dart`. |
| Brittle, token-draining mobile UI automation | **Maestro Declarative Mobile Automation (`.maestro/flows/smoke_launch.yaml`)**: Zero-token declarative YAML flows executed via `maestro test` or MCP (`maestro mcp`). |
| Missing production-tested repository patterns | **Production Repository Recipes (`repo-recipes.md`)**: CRUD with `_sanitizeFilters`, capability mixins (`SoftDeletableRepoMixin`, `ActiveToggleRepoMixin`), multipart upload, unpaginated bulk fetch (`all=true`), binary PDF downloads, and cache-aside with TTL. |
| Ceremonial task close-out tax and flat-file memory bloat | **5-Tier Memory & Learning Model**: Ambient session memory via Claude Auto-Memory (`MEMORY.md` + Auto-Dream); on-demand Knowledge Graph via Anthropic MCP (`@modelcontextprotocol/server-memory`); path rules; `AGENTS.md` §7; and optional offline CLI tracking (`scripts/agent/learn.dart`). |

## Roadmap (not built yet), in priority order

1. **Agent eval suite (do this next).** Without it, every harness change is a guess.
   - Keep 10–20 realistic tasks (for example "add a profile screen for `GET /me` from this Postman file", "add pull-to-refresh pagination", "fix this 401 loop").
   - Run each task headless (`claude -p`, `codex exec`) in a fresh generated app.
   - Score each run with signals we already have: `verify.dart` passes, zero lint findings, the generated BLoC tests still pass, plus a rubric review by `flutter-qa`.
   - Track pass rate and cost per harness version in CI on a schedule (each run costs API tokens).
2. **Move `redux_rxdart_lints` to the first-party analyzer plugin API** (`analysis_server_plugin`, Dart ≥ 3.10).
   - The rules would run inside `dart analyze` / `flutter analyze`, so the edit hook, the MCP `analyze_files` tool and every IDE enforce them instantly. That replaces the 40 s custom_lint step.
   - Watch the open [performance issue](https://github.com/dart-lang/sdk/issues/63292) and measure before switching.
   - [Migration guide](https://leancode.co/blog/migrating-to-dart-analyzer-plugin-system).
3. **More lint rules for what is mechanical.** These are the strongest kind of guardrail, because the agent cannot forget them:
   - `fetch` must call `createNewToken()` first.
   - No `e.toString()` / `$e` in widget text.
   - No `withOpacity`.
   - No string literals in `Text(...)` inside `lib/features/` (l10n).
   - BLoC subjects must be closed in `dispose()`.
4. **Contract ingestion** (the spec-first workflow itself shipped in 1.7.0 as `add-feature`).
   - OpenAPI/Postman → repo method, model `fromJson` and JSON fixtures for tests, generated instead of written by the agent. This targets agents' most common failure, which is inventing response shapes.
5. **Opt-in `Stop` hook** that runs `verify.dart --fast` before the agent reports "done", so a red gate cannot be handed back. It is opt-in because it adds about 5 s to every finished turn.
6. **Runtime loop.** Document a debug-run workflow (`flutter run` + MCP `hot_reload` / `get_runtime_errors` / `widget_inspector`). Add golden/screenshot tests, so agents get a visual signal for UI work instead of none.
7. **Memory hygiene.**
   - Auto-append `progress.md` from commit messages (a git hook), so agents spend fewer tokens maintaining logs.
   - Flag `active-context.md` entries that are older than N commits as possibly stale.
8. **More tools.** Add `.vscode/mcp.json` and `.gemini/settings.json` only if the team uses those tools. Copilot and Gemini CLI already read `AGENTS.md`.

## What we deliberately did not do

- **No hooks in the harness brick.** It stays a pure template because hook compilation caused the Windows `MAX_PATH` failures fixed in 1.4.x. Everything new is plain files.
- **No `.cursor/rules/*.mdc` or Copilot instruction duplicates.** Those tools read `AGENTS.md`, and every extra copy is another place for rules to drift.
- **No custom_lint in the edit hook.** At 40 s per edit it would make agents slower without making them better.
