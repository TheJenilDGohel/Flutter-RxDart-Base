# Changelog

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
