# Antigravity & AI Agent Instructions — Flutter-RxDart-Base Workspace

This repository is the Mason Workspace source repository providing templates, bricks, tooling, and the custom linter for the **Flutter RxDart Base Architecture**.

## 🧭 Repository Layout

```
.
├── bricks/
│   ├── project/                  # Scaffolds initial Flutter app architecture (v2.0.0)
│   ├── bloc/                     # Scaffolds feature modules with BLoC and tests (v1.2.2)
│   └── harness/                  # Scaffolds AI Agent Harness onto apps (v2.6.2)
├── packages/
│   ├── redux_rxdart_lints/       # Custom lint package enforcing golden rules (v0.6.0)
│   └── adaptive_units/           # ScreenUtil-compatible sizes: scale below 600dp, 1:1 above (v0.1.0)
├── tool/
│   ├── smoke.dart                # E2E: create -> project -> bloc -> strict format -> recipes -> analyze -> test -> lint
│   ├── harness_recipes.dart      # Pastes the harness BLoC recipes (verbatim) into the smoke app; fixture in recipe_fixture/
│   ├── docs_check.dart           # Validates markdown links
│   ├── harness_check.dart        # Harness docs may only reference generated paths/types/lint rules
│   ├── test_harness_upgrade.dart # E2E test of the harness's scripts/agent/upgrade.dart
│   ├── test_harness_learn.dart   # E2E test of the harness's scripts/agent/learn.dart (lessons loop)
│   ├── test_harness_budget.dart  # E2E test of the harness's scripts/agent/budget.dart
│   ├── eval.dart                 # Harness compliance gates (budget, mods wired, root marketplace = brick mods)
│   ├── adversarial_test.dart     # Generated app: hostile edits caught, wire_route, full verify.dart
│   └── version_gate.dart         # Version bump + CHANGELOG entry required for shipped changes
├── .claude-plugin/               # Marketplace serving the harness brick's Claude Code mods (no copies)
├── docs/                         # Extended architectural guides, brick references, and roadmap
└── .github/workflows/            # ci.yml, version-gate.yml, docs.yml, dependency-audit.yml, dependency-gate.yml, changelog.yml
```

## ⚡ Maintainer Verification Quality Gates

Run these commands before committing any changes:

1. **Docs Link Integrity**:
   ```bash
   dart run tool/docs_check.dart
   ```
2. **Full E2E Generation Smoke Test**:
   ```bash
   dart run tool/smoke.dart
   ```
3. **Linter Package Analysis + Rule Fixtures**:
   ```bash
   dart analyze --fatal-infos packages/redux_rxdart_lints
   (cd packages/redux_rxdart_lints && dart run tool/check_fixture.dart)
   ```
4. **Workspace Formatting & Code Analysis** (brick templates are excluded; they are checked through the smoke test):
   ```bash
   dart format --set-exit-if-changed tool bricks/project/hooks bricks/bloc/hooks bricks/harness/__brick__/scripts/agent
   dart analyze --fatal-infos tool bricks/project/hooks bricks/bloc/hooks bricks/harness/__brick__/scripts/agent
   ```
5. **Harness Checks**:
   ```bash
   dart run tool/harness_check.dart
   dart run tool/eval.dart
   dart run tool/test_harness_upgrade.dart
   dart run tool/test_harness_learn.dart
   dart run tool/test_harness_budget.dart
   dart run tool/adversarial_test.dart
   dart run tool/version_gate.dart origin/main
   ```
6. **Claude Code mods** (not in CI: needs the `claude` CLI). For each mod under `bricks/harness/__brick__/.claude/plugins/`: `claude plugin test` and `claude plugin validate --strict .` inside it; `claude plugin validate --strict .` at the root and in `bricks/harness/__brick__/.claude/plugins` for the two marketplaces.

## 🔒 Maintainer Rules

1. **Brick Versioning & CHANGELOG**: Every template or hook change to a brick requires bumping `version` in its `brick.yaml` and documenting changes in that brick's `CHANGELOG.md`.
2. **Documentation Currency**: Keep `README.md`, `docs/`, and brick documentation synchronized with template changes.
3. **Golden Rules Consistency**: Enforceable Golden Rules in `bricks/harness/__brick__/AGENTS.md` must be mirrored in `packages/redux_rxdart_lints`, with an `expect_lint` case in its `example/` fixture.
4. **Canonical Repo vs Fork URLs**: Upstream is `TheJenilDGohel/Flutter-RxDart-Base`. Some functional URLs deliberately point at the fork `jenilseawind-glitch` until upstream merges the 1.6 work — do not "fix" them early, and switch them right after the upstream merge. See [`docs/contributing.md` §6](docs/contributing.md#6-urls-point-at-one-canonical-org).
5. **Git Commit Policy**: Conventional Commits format (`feat(...)`, `fix(...)`, `docs(...)`). Never commit without explicit instruction.
6. **Harness Skills**: the eight skills in `bricks/harness/__brick__/.agents/skills/` must describe only real generated code (`tool/harness_check.dart`), keep their `.claude/skills/` entry points identical in name and description, and be listed in `.harness/version.json` → `managed_skills`. Recipe code is compiled in a generated app before release.

## 🧰 Skill for Maintainers

For any change to this workspace, use the `base-maintainer` skill (`.agents/skills/base-maintainer/SKILL.md`; Claude Code: `.claude/skills/base-maintainer/`). It maps each kind of change to the files and gates it touches, and covers taking in lessons that apps propose upstream (`learn.dart upstream`).

See [`docs/contributing.md`](docs/contributing.md) for complete maintainer details.
