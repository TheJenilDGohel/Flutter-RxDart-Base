# `harness` Brick

Scaffolds an AI Agent Harness onto any Flutter project: a universal cognitive
contract (`AGENTS.md`), a 1-line native transclusion for Claude Code
(`CLAUDE.md`), a universal senior-dev skill (`.agents/skills/`, mirrored to
`.cursor/skills/`), deterministic CLI tooling, and analyzer-enforced golden
rules. Works standalone on any Flutter project, or auto-installed by `project`
via the `include_harness` prompt.

---

## 📋 Usage

```bash
mason make harness
```

`project_name` is auto-detected from `pubspec.yaml` if left blank (no prompt
needed for CI/CD or AI agents running non-interactively).

---

## 🏗️ What Gets Generated

- **`AGENTS.md`**: architecture contract — Redux+RxDart+Dio layering, 12
  inviolable golden rules, backend API discovery convention, deterministic
  commands, git commit policy. Read by any AGENTS.md-compatible agent
  (Claude Code, Cursor, Copilot, Codex, 20+ tools).
- **`.agents/skills/flutter-senior-dev/`**: Universal skill that acts as a
  senior Flutter developer for this stack. Auto-discovered by any tool that
  reads `.agents/skills/` (Antigravity, Gemini, and the growing list of
  AGENTS.md-ecosystem tools). Includes golden-rules summary, architecture
  snapshot, planning checklist (neutral-mode-first), and known base gaps.
  References `AGENTS.md` as the authoritative source. Includes focused
  reference docs (`api-layer.md`, `redux-vs-rxdart.md`, `ui-conventions.md`)
  loaded only when needed.
- **`.agents/agents/flutter-qa.md`**: On-demand QA reviewer agent. Runs once
  on Sonnet, checks 5 critical areas, and reports findings. Invoked explicitly.
- **`CLAUDE.md`**: Lean always-loaded project memory (~50 lines) with the
  state-placement rule, folder map, daily workflow, and hard rules. References
  `AGENTS.md` for the full golden rules contract.
- **`scripts/agent/wire_route.dart`**: one command scaffolds a feature (via
  `mason make bloc`, if it doesn't exist yet) *and* wires its route constant +
  `onGenerateRoute` case into `routes.dart` / `app_router.dart`. Detects
  incompatible declarative routers (`go_router`, `auto_route`) and fails loud
  with manual-wiring instructions instead of guessing.
- **`.harness/` Context Store**: token-efficient cross-session memory for AI
  agents. Contains `system-snapshot.md` (auto-generated, always accurate project
  state) and `active-context.md` (agent-maintained handoff log).
- **`scripts/agent/snapshot.dart`**: generates deterministic, LLM-free project
  snapshots (features, routes, commits, analysis) for the context store.
- **`scripts/agent/verify.ps1` / `verify.sh`**: deterministic quality gate —
  `dart format --set-exit-if-changed .` + `flutter analyze --fatal-infos` +
  `dart run scripts/agent/snapshot.dart`.
- **Analyzer enforcement**: patches the project's `pubspec.yaml` (adds
  `custom_lint` + `redux_rxdart_lints` dev-dependency) and
  `analysis_options.yaml` (`analyzer.plugins: [custom_lint]`) so Golden Rules
  #1 (repo-transport-only), #3 (zero setState), #4 (zero RxDart outside BLoC)
  are `flutter analyze` errors, not just prose an agent has to remember. See
  [`packages/redux_rxdart_lints`](../../packages/redux_rxdart_lints/README.md).

Run `dart pub get` (or `flutter pub get`) after install to fetch the lint
plugin.

---

## ⚙️ Generation Architecture

`harness` v1.4.1 is a pure-template brick (zero hooks):
- Templates for `.agents/skills/`, `.cursor/skills/`, `.harness/`, `scripts/agent/`, `AGENTS.md`, and `CLAUDE.md` are rendered directly from `__brick__/`.
- No hook compilation or sub-process execution occurs during `mason make`, eliminating Windows path-length (`MAX_PATH`) and directory-scanning issues.
- Generation completes deterministically in ~50ms across all platforms.

See [`CHANGELOG.md`](CHANGELOG.md) for version history.
