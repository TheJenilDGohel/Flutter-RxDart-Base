# Changelog

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
