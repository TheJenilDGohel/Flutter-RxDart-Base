# Changelog

## 2.0.2

- **`crossSessionInbound` is no longer set by the harness**: 2.0.1's `"hold"` in the project `.claude/settings.json` blocked swarm hand-offs (a project-manager session assigning work to another session). A repo setting can only tighten this value, so a developer's own `"accept"` could not override it. The key is removed; each developer chooses in `~/.claude/settings.json`. Apps keep their own `settings.json` on upgrade, so delete the line there by hand.
- **`upgrade.dart` skips `.claude/worktrees` and deep trees during backup**: Claude Code worktrees contain full git checkouts. Backing them up recursed into nested backups or exceeded path length limits on Windows (`PathNotFoundException`). The backup step now safely skips `worktrees`, `.git`, `.dart_tool`, and old backups, and handles unreadable entities gracefully.

## 2.0.1

- **`--check-only` no longer hangs in IDE terminals**: VS Code-based terminals export `GIT_ASKPASS`, which beats `core.askPass=` and made `git ls-remote` wait on a credential prompt for a missing or private upstream. The probe now clears `GIT_ASKPASS` and `SSH_ASKPASS`.
- **Valid `crossSessionInbound` value**: `.claude/settings.json` shipped `"notify"`, which Claude Code rejects (allowed: `accept`, `hold`, `refuse`) and reports on every start. It is now `"hold"`: messages from other local sessions wait for your approval, as they already did while the value was ignored. Apps keep their own `settings.json` on upgrade, so change the value there by hand.
- **Upgrade handover runs on the current Dart VM**: `upgrade.dart` now starts the newer engine with `Platform.resolvedExecutable` instead of re-resolving `fvm dart`. In FVM projects the nested `fvm` call could hit a pub-global `fvm.bat` shim whose snapshot was built by another SDK, printing `Can't load Kernel binary: Invalid kernel binary format version` before falling back. The running VM is already the project SDK.

## 2.0.0

- **Multi-Agent Specialist Swarm & Token Shield Architecture**:
  - **Token Shield Configuration (`.claude/settings.json`)**: Configured 1-hour prompt cache TTL (`promptCacheTtl: "1h"`, `subagentPromptCacheTtl: "1h"`), clamped terminal bash outputs to 4,000 characters (`bashOutputMaxChars: 4000`), configured cross-session notification handling (`crossSessionInbound: "notify"`), and configured automatic teammate multiplexing (`teammateMode: "auto"`). Deny rules expanded to block reads on `.dart_tool/`, `build/`, `*.g.dart`, and `*.freezed.dart`.
  - **Context-Slicing Path Rules (`.claude/rules/`)**: Path-scoped architecture rules dynamically load into context only when matching files are edited:
    - `bloc.md`: BLoC stream lifecycle, subject guarding, error mapping, and live search rules.
    - `ui.md`: Zero setState, ScreenUtil in public widgets, ResColors, and AppResponseBuilder.
    - `endpoints.md`: Repository transport boundaries, ApiBaseHelper, and defensive model deserialization.
    - `testing.md`: BLoC behavioral coverage, fake repositories, and RxDart stream test assertions.
  - **Specialist Agent Swarm (`.claude/agents/`)**: Introduced ultra-lean, role-bounded specialist subagents with `omitClaudeMd: true` to prevent prompt cache duplication:
    - `bloc-specialist.md`: Focused on reactive streams, subjects, and BLoC unit tests.
    - `ui-artisan.md`: Focused on design system widgets, ScreenUtil, and theme tokens.
    - `device-qa.md`: Automated mobile device testing via Maestro CLI.
    - `flutter-qa.md`: Streamlined one-shot architecture conformance reviewer.
  - **OpenMob Replacement via Maestro Automation**: Integrated Maestro declarative YAML mobile test runner (`maestro mcp` in `.mcp.json`) and shipped baseline launch flow `.maestro/flows/smoke_launch.yaml`, eliminating token-heavy accessibility tree and screenshot inspections.
  - **Single-Terminal & Multi-Session Swarm Protocol**:
    - `.harness/team-protocol.md`: Documents in-process multiplexing and concurrent multi-session Git worktree workflows (`.worktreeinclude`).
    - `scripts/team/task_handoff.dart`: Manages layer-isolated task handoffs with concurrency locks, session tracking, and atomic file writes in `.harness/tasks/active.json`.
    - `scripts/team/heartbeat.dart`: Safe swarm inspection without triggering uncached wakeups.
  - **Production Repository Recipes (`.agents/skills/add-endpoint/repo-recipes.md`)**: Codified production-tested patterns from real apps:
    - Recipe A: Standard REST CRUD with query param sanitization (`_sanitizeFilters`).
    - Recipe B: Capability mixins (`SoftDeletableRepoMixin`, `ActiveToggleRepoMixin`).
    - Recipe C: Multipart & media upload mixin (`UploadMediaRepoMixin`, form data, MIME detection).
    - Recipe D: Bulk & "all" unpaginated fetches (`all=true` with batching fallback).
    - Recipe E: Binary document and PDF streaming downloads.
    - Recipe F: Cache-aside repository pattern with TTL and memory invalidation.
    - Recipe G: Long-running operation polling with status callbacks.
  - **5-Tier Zero-Token Memory & Learning Architecture**:
    - Replaced the ceremonial task close-out tax with a multi-tier memory system.
    - **Tier 1 (Ambient)**: Claude Code Auto-Memory (`MEMORY.md` + Auto-Dream) for ambient session learnings.
    - **Tier 2 (Structured Knowledge Graph)**: Registered `@modelcontextprotocol/server-memory` in `.mcp.json` and pre-approved `mcp__memory` in `.claude/settings.json` for on-demand knowledge graph entities and observations (0 baseline tokens).
    - **Tier 3 (Path Rules)**: Domain standards dynamically injected via `.claude/rules/*.md`.
    - **Tier 4 (Team Rules)**: Permanent team non-negotiables in `AGENTS.md` §7.
    - **Tier 5 (Offline CLI)**: `scripts/agent/learn.dart` preserved for offline CLI tracking and upstream base contributions.
  - **Fast In-Flight Quality Gate (`scripts/agent/on_edit.dart`)**: Lightning-fast (<1.5s) formatting and analysis check for modified files during active editing.
  - **Expanded Upgrade Engine (`scripts/agent/upgrade.dart`)**: Syncs team scripts, specialist agents, path rules, Maestro flows, worktree configs, and reports missing MCP server configurations.

## 1.8.0

- **Native analyzer plugin support**:
  - `verify.dart`: Removed `dart run custom_lint` step; the Analyzer step (`flutter analyze --fatal-infos`) now executes the native `redux_rxdart_lints` plugin directly.
  - `.claude/settings.json`: Removed legacy `custom_lint` bash execution permissions.
  - `upgrade.dart`: Added `GIT_TERMINAL_PROMPT: 0` to `git ls-remote` to prevent terminal hanging on remote inspection.
  - Skills updated: `fix-bug` (architecture lints reported by Analyzer, added Rule 2 `no_exception_tostring`), `flutter-senior-dev` (architecture and dependencies updated).

## 1.7.4

- **Compiler-enforced Golden Rules:** Added `no_exception_tostring` custom lint to `redux_rxdart_lints` to statically enforce Rule 2 (never displaying `e.toString()` in UI widgets).
- **Tooling optimization:** Deleted `scripts/agent/on_edit.dart` and its Claude Code hook. Synchronous analyzer runs on every file edit added unacceptable latency to the AI loop; agents now rely on the comprehensive `verify.dart` gate at the end of a task.
- **Skill enhancements:** Updated `add-endpoint` skill to explicitly instruct agents to use the Dart MCP `lsp` references tool instead of regex or `grep`.

## 1.7.3

- **Repository patterns & capability mixins.** Expanded Golden Rule 1 in `AGENTS.md` and the `add-endpoint` skill to formally codify repository architecture learned from production apps:
  - **One BLoC, one repo:** a BLoC holds only its own feature repository. Never inject multiple repositories into a BLoC.
  - **Capability composition via mixins:** when multiple features need secondary capabilities (dropdown option fetches, tags, profile info, logout), compose them using `mixin <Capability>Mixin` (`with FooMixin`) rather than `extends OtherFeatureRepo` (which leaks sensitive or unrelated methods).
  - **Sanitized query & body parameters:** dedicated `_filterParams` helper pattern preventing empty strings or null keys (`?search=&tag=`) from reaching backends.
  - **Multipart file uploads:** clean `postFormData`/`putFormData` with `MultipartFile.fromFile`.
  - **Large data & export timeout overrides:** patterns for bulk calls (`all=true`) with `Options(receiveTimeout: ...)`.
  - **Binary / non-JSON responses:** patterns for streaming bytes (e.g. invoice PDFs) with status validation and JSON error envelope parsing.
- **Token & context optimization suite:**
  - **Scoped skill routing:** Scoped down `flutter-senior-dev` description frontmatter to prevent Claude Code and agents from greedily injecting the full architectural skill into context on generic mentions of core terms (e.g. `AppStore`, `ApiResponse`, `golden rules`). Hands-on tasks route directly to specific task skills (`add-feature`, `add-endpoint`, `manage-state`, `build-ui`, `write-tests`, `fix-bug`).
  - **Lazy reference loading:** Explicitly configured entry points to prevent eager loading of `architecture.md`, `planning-checklist.md`, and `base-gaps.md` unless specifically required.
  - **Cheaper & scoped subagent:** Configured `flutter-qa` (`.claude/agents/flutter-qa.md`) with `model: haiku` (drastically reducing subagent token costs) and bounded its review scope to the target feature folder (`lib/features/<name>/`) rather than scanning whole project trees.
  - **Session context hygiene:** Added explicit `/clear` and `/compact` lifecycle rules in `CLAUDE.md` to prevent context bloating past 150k tokens during multi-turn workflows.

## 1.7.2

- **FVM support across all harness scripts and tooling.** Agent scripts (`verify.dart`, `wire_route.dart`, `upgrade.dart`, `on_edit.dart`) and shell wrappers (`verify.sh`, `verify.ps1`) auto-detect `.fvm/` or `.fvmrc` and invoke `fvm dart` / `fvm flutter` / `fvm exec mason` instead of bare `dart` / `flutter` / `mason`. `.claude/settings.json` pre-approves FVM-prefixed commands. `AGENTS.md` and `CLAUDE.md` instruct agents to prefix bare CLI commands with `fvm`. Previously, the harness failed on FVM-managed projects because system Dart was too old for the project's SDK constraint, causing agents to abandon the harness procedures.

## 1.7.1

Upgrade fixes from a real project's 1.5 → 1.6 upgrade, which stayed on an old version, deleted team scripts and dropped team rules.

- **Renders the version you asked for.** `upgrade.dart` renders the harness in a throwaway mason workspace that names `upstream_repo`, so a project `mason.yaml`/`mason-lock.json` pin or a stale global brick can no longer serve an old version (the cause of "upstream is at 1.7.0 but the brick renders 1.6.1" even after `mason upgrade -g`). `--ref <git-ref>` picks a branch, tag or commit; `--brick <dir>` renders a local brick. Offline, it falls back to the registered brick and says so. It never downgrades without `--force`.
- **The new engine applies its own upgrade.** When the rendered harness ships a different `upgrade.dart`, that engine applies the upgrade, so fixes like these take effect on the upgrade that ships them instead of the one after.
- **Never deletes your files.** `scripts/agent/` and shipped skill folders are no longer replaced wholesale: every file the brick ships is written, files older harness versions shipped and later retired are removed (including the stale `.cursor/skills/flutter-senior-dev/` mirror from 1.4.x), and anything else (`check_ids.dart`, `stop-gate.ps1`, notes) is kept and listed.
- **Keeps your `upstream_repo`.** A project pointing `.harness/version.json` at its own fork or mirror keeps it across upgrades; only the stock repositories follow the template.
- **Settings report.** A hook in `.claude/settings.json` that runs a missing script is reported, and so are template hooks and permissions the project's settings lack.
- **Pre-1.6 contracts keep every team line.** Instead of dropping whole sections whose heading the harness once shipped, `AGENTS.md`/`CLAUDE.md` migration drops only lines that a 1.4.0–1.5.1 template actually contained. A rule added inside "Hard Rules", a line added to the "Folder Map" block or a hand-written `AGENTS.md` now lands below the project-rules marker under "Kept from your previous version of this file".
- Upgrading from ≤ 1.7.0: the old engine runs the upgrade, so fetch this one first (see README, "Upgrading from 1.7.0 or older").

## 1.7.0

Task skills and a self-learning loop: agents get a procedure for each kind of work on this architecture, and every session's mistakes become lessons that the next session loads.

- **Seven task skills** (Agent Skills format, in `.agents/skills/` with `.claude/skills/` entry points): `add-feature` (spec-first, from contract to green gate), `add-endpoint` (contract → `ApiConstants` → transport-only repo → defensive model → BLoC → tests), `manage-state` (where state lives, plus BLoC recipes for submit, live search, pagination, one-off events, several loads, dependent calls, local UI state and timers that the base repo's CI compiles, lints and behavior-tests in a generated app; Redux session changes step by step), `build-ui`, `write-tests`, `fix-bug` (symptom → layer table and a fix for every gate step and lint rule) and `evolve-harness`. `flutter-senior-dev` stays the planning and review skill and routes hands-on work to them.
- **Learning loop.** `scripts/agent/learn.dart` keeps `.harness/lessons.md`: `list` (each skill's step 0), `add` (with a duplicate guard), `hit`, `promote` (to a skill overlay `.harness/skills/<skill>.md`, `AGENTS.md` §7, a project skill or `upstream`), `retire`, `review` (ready to promote, reopened, duplicates, stale, orphans, cap) and `upstream` (proposals for the base repository). A promoted lesson that happens again reopens, because the rule it became did not work. Memory-poisoning guard: `add` refuses, and `check` fails on, secrets (tokens, keys, credentialed URLs, `password=`-style assignments) and injected-instruction phrasing; `check` also scans overlays, specs, `active-context.md` and `progress.md` for credentials. `evolve-harness` allows lessons only from verified work or explicit user instructions.
- **`verify.dart`** gains a Lessons step: it fails on a malformed lessons file and prints how many lessons are ready to promote.
- **`AGENTS.md` §4/§6**: skill index, plus the close-out step that records lessons. `CLAUDE.md` lists the skills; `learn.dart` is pre-approved in `.claude/settings.json`. `flutter-qa` ends its review with suggested lesson commands.
- **`upgrade.dart`** replaces every skill the brick ships (listed in `.harness/version.json` → `managed_skills`), removes shipped skills that are no longer shipped, and never touches skills the project created, `.harness/lessons.md` or overlays. It lists template permissions missing from an existing `.claude/settings.json` instead of silently skipping them.
- `references/redux-vs-rxdart.md`: a new `AppState` field (an onboarding flag, a theme) needs the owner's approval, matching `AGENTS.md` §1 and the `AppState` doc comment. Previously it read as allowed by default.
- Upgrading from 1.6.x: run `dart run scripts/agent/upgrade.dart`. Your `.claude/settings.json` is kept, so add `"Bash(dart run scripts/agent/learn.dart:*)"` to its allow list (the upgrade prints this).

## 1.6.1

- **Fix: "Harness is already up to date" on old projects.** Neither repository has git tags, so pre-1.6 `upgrade.dart` always fell back to `1.5.0` and compared it with the `1.5.0` stamp. `--check-only` now reads the version from upstream's `bricks/harness/brick.yaml` (tags are only a fallback) and says so plainly when it cannot reach upstream, instead of claiming "up to date".
- `upgrade.dart` warns when the mason-registered brick is older than upstream (stale `mason add -g` cache), and "Already on X" now points to `mason upgrade -g`.
- Docs: "Upgrading a project from harness ≤ 1.5.x", a 3-step bootstrap, because the old script cannot upgrade itself.

## 1.6.0

Agent discovery, tooling and feedback loops (see `docs/ai-harness-rnd.md` in the base repo for the research behind each change).

- **Claude Code actually loads the harness.** `CLAUDE.md` now imports `@AGENTS.md` (it previously only *mentioned* it, so the golden rules were not in context). The skill gets a `.claude/skills/` entry point and the QA subagent moved to `.claude/agents/` — Claude Code never discovered them under `.agents/`.
- **Dart & Flutter MCP server** registered in `.mcp.json` and `.cursor/mcp.json` (`dart mcp-server`, in the SDK): analyzer, LSP, pub.dev search, hot reload, runtime errors, widget inspector.
- **Edit hook** (`.claude/settings.json` → `scripts/agent/on_edit.dart`): formats and analyzes each edited Dart file and feeds issues back to the agent immediately. Plus a permission allowlist for the safe dev commands and a force-push deny.
- **`verify.dart`**: one cross-platform gate (format → analyze → custom lints → **tests** → snapshot; tests were never part of the gate). `verify.sh` / `verify.ps1` are thin wrappers. `--fast` mode.
- **Snapshot** is deterministic (no timestamp, git log or second analyzer run) and more useful: features without tests, route paths, API endpoints, `AppState` fields, dependencies.
- **`upgrade.dart` rewritten.** Fixed: stamping success when `mason make` failed; overwriting the Android/iOS ids with `com.example.<name>`; duplicating the `@.harness/active-context.md` line on every run; deprecated `::set-output`; no backup of Tier-1 files; versions taken from a git tag instead of the rendered brick. Contracts now merge on an explicit `harness:project-rules` marker; legacy files are migrated. `version.json` records the install vars and an upgrade history.
- **Content corrected against the 1.4.0 project brick**: rule 2 (`userFacingMessage(context)`), rule 8 (cancellation, `retry: fetch`), rule 11 (token scoped to `BASE_URL`, 401 → logout), new rule 13 (ScreenUtil in public widgets, lint-enforced), all four lint rules listed, `architecture.md` rewritten (it described harness 1.1.0), `utils/widgets/common/` → `ui/`, exception list, skill reference paths. The skill now points at `AGENTS.md` instead of restating the rules.
- Docs no longer claim the brick patches `pubspec.yaml`, mirrors to `.cursor/skills/` or auto-detects `project_name`.
- **Repository URLs** still point at the fork (`jenilseawind-glitch`) on purpose: upstream `TheJenilDGohel` ships an older `redux_rxdart_lints` that breaks new apps. Switch to upstream right after the upstream merge (checklist in `docs/contributing.md` §6).

## 1.5.1

- **Context bloat reduction**: Tightened `active-context.md` template with enforced line-length caps (Current Focus: 2-3 lines, Recent Tasks: 1-2 lines each, Key Decisions: 1-2 lines each), overflow-to-`progress.md` instructions, Known Issues cleanup rules (delete resolved items), `⏸ deferred by decision` line type, and `commit:pending` anti-staleness guidance.
- **AGENTS.md §7**: Expanded project context rules to match the tighter `active-context.md` guardrails — explicit format constraints, overflow protocol, and Known Issues lifecycle.
- **`progress.md`**: Enforced one-line Conventional Commits format: `[YYYY-MM-DD] type(scope): what, why if not obvious (proof)`. No paragraphs.
- **`snapshot.dart` route de-bloat**: Replaced full route enumeration (`Name → /path | ...`) with route count + pointer to `routes.dart`. Saves thousands of tokens on real apps where `routes.dart` is already the canonical list.

## 1.5.0

- **Autonomous 3-Tier Migration Engine (`scripts/agent/upgrade.dart`)**: Self-contained migration tool allowing consuming projects to upgrade harness bricks without data loss.
  - **Tier 1 (Core Engine & Tools)**: Safely overwrites `scripts/agent/` and `.agents/skills/` with latest templates.
  - **Tier 2 (User Memory & State)**: Strictly protects `.harness/active-context.md` and `.harness/progress.md`—zero loss of ongoing tasks, commit proofs, or architecture decisions.
  - **Tier 3 (Shared Contract)**: Smart-merges `AGENTS.md` and `CLAUDE.md`, preserving custom team sections and project workarounds while adopting upstream rule evolutions.
- **Machine-Readable Version Manifest (`.harness/version.json`)**: Tracks installed brick version, upgrade history, and upstream repository for automated CI bots and AI agents.
- **Universal Migration CLI (`tool/upgrade_harness.dart`)**: Workspace-level tool capable of migrating legacy projects (like pre-1.4.2 apps) with pre-flight safety backups.
- **Opinionated Architecture Stance**: Officially codified the architecture as "The Opinionated Flutter RxDart Base Architecture", emphasizing strict compiler-enforced convention over configuration.

## 1.4.2

- **Hybrid Token-Efficient Memory**: Lean `CLAUDE.md` (~500 tokens) with direct transclusion of `@.harness/active-context.md` for zero-cost cross-session memory retention.
- **Accurate ApiResponse Signatures**: Updated `architecture.md`, `references/api-layer.md`, and `references/ui-conventions.md` to use the canonical sealed subtypes (`InitialResponse`, `LoadingResponse`, `SuccessResponse`, `ErrorResponse`) and replaced all stale `Completed` references.
- **Golden Rule #1 Enforcement**: Fixed erroneous instructions in `api-layer.md` to ensure repositories return raw `Map<String, dynamic>` rather than calling `Model.fromJson`.
- **Flutter 3.27+ Standard Alignment**: Updated design token documentation and `flutter-qa` reviewer checks to mandate `withValues(alpha:)` over deprecated `withOpacity()`.

## 1.4.1

- Flattened skill files directly into `.agents/skills/flutter-senior-dev/` and
  `.cursor/skills/flutter-senior-dev/` (removed nested `references/` directory).
- Prevents Windows 260-character path overflow (`references\*`) during Mason template scanning.
- Pure template brick (zero hooks), deterministic, works out of the box on Windows.

## 1.4.0

- Converted harness to a pure, zero-hook brick by placing `.agents/`, `.cursor/`,
  and `.harness/` directly into `__brick__/`.
- Eliminates hook compilation in Mason git cache, completely bypassing the Windows
  260-character `MAX_PATH` limit (OS error 122) and eliminating terminal hangs.
- Instant, deterministic generation across all platforms in under 100ms.

## 1.3.2

- Generate `CLAUDE.md` programmatically in `post_gen.dart` instead of statically in
  `__brick__/` to prevent Mason interactive conflict prompts when a project already has
  an existing `CLAUDE.md`.
- Prepends harness transclusions to existing `CLAUDE.md` files without overwriting or losing
  pre-existing project instructions.
- Added 5-second timeout to `Process.run('dart', ['format', ...])` in `post_gen.dart` so hook
  execution never hangs if the Dart format process stalls.
- Pre-formatted all scripts in `__brick__/scripts/agent/`.

## 1.3.1

- Fix Windows `mason upgrade` / `mason get` failure caused by hidden dot-directories
  (`.agents/`, `.harness/`) in the brick template tree and recursive directory scanning.
- Moved `.harness/` context store files and `.agents/skills/flutter-senior-dev/` skill
  files into self-contained hook assets (`hooks/assets.dart`), generated programmatically
  by `post_gen.dart`.
- `__brick__/` now contains zero dot-prefixed directories, avoiding Windows wildcard
  expansion errors (`references\*`).
- `post_gen.dart` now mirrors skill files to `.cursor/skills/` using explicit file-by-file
  copy instead of recursive filesystem listing.

## 1.3.0

- Added `.agents/skills/flutter-senior-dev/` — a universal skill that acts as a
  senior Flutter developer for projects on this stack. The skill summarises the
  golden rules, architecture, planning checklist (neutral-mode-first) and known
  base gaps. Auto-discovered by any tool reading `.agents/skills/`.
- `post_gen.dart` mirrors the skill into `.cursor/skills/` for Cursor IDE
  auto-discovery. One canonical source, two discovery paths.
- `CLAUDE.md` now transcluds the skill and its planning/gap references alongside
  `AGENTS.md` and `.harness/` context, so Claude Code gets the full depth.
- The harness now scaffolds agent contracts for three ecosystems from one source:
  universal (`AGENTS.md` + `.agents/skills/`), Claude Code (`CLAUDE.md`), and
  Cursor IDE (`.cursor/skills/` mirror).

## 1.2.0

- Added token-efficient cross-session context memory for AI agents via a new `.harness/` directory.
- `scripts/agent/snapshot.dart`: New script that deterministically scans the project (features, routes, commits, analysis) and generates `system-snapshot.md` without using LLMs.
- `verify.ps1` and `verify.sh`: Now automatically run the snapshot script as the final quality gate step.
- `AGENTS.md`: Added Section 7 with strict rules for agents to read `system-snapshot.md` and maintain `active-context.md` with proof-of-work (commit hashes/file paths) to prevent context hallucination.

## 1.1.0

- `wire_route.dart` now auto-scaffolds the feature via `mason make bloc --feature_name <name>`
  if it doesn't exist yet, before wiring the route. One command instead of two.
- `wire_route.dart` fails loud (instead of silently no-op'ing) when no `switch (settings.name)` /
  `default:` pattern is found to inject into.
- `wire_route.dart` detects incompatible declarative routers (`go_router`, `auto_route`) in
  `pubspec.yaml` and exits with a manual-wiring instruction instead of mis-injecting an
  `onGenerateRoute`-style case.
- `post_gen.dart` now wires the `redux_rxdart_lints` custom_lint plugin into the consuming
  project's `pubspec.yaml` (dev_dependency) and `analysis_options.yaml` (`analyzer.plugins`),
  enforcing Golden Rules #1, #3, #4 at `flutter analyze` time.
- AGENTS.md: documented the above; added section 5 (Golden Rules Are Analyzer-Enforced);
  renumbered Git Commit Policy to section 6.

## 1.0.0

- Initial release: AGENTS.md contract, CLAUDE.md transclusion, `wire_route.dart`,
  `verify.ps1` / `verify.sh` quality gate, install-time project-name detection.
