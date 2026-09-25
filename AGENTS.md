# Antigravity & AI Agent Instructions — Flutter-RxDart-Base Workspace

This repository is the Mason Workspace source repository providing templates, bricks, tooling, and the custom linter for the **Flutter RxDart Base Architecture**.

## 🧭 Repository Layout

```
.
├── bricks/
│   ├── project/                  # Scaffolds initial Flutter app architecture (v1.3.1)
│   ├── bloc/                     # Scaffolds feature modules with BLoC and tests (v1.1.0)
│   └── harness/                  # Scaffolds AI Agent Harness onto apps (v1.4.2)
├── packages/
│   └── redux_rxdart_lints/       # Custom lint package enforcing golden rules (v1.0.0)
├── tool/
│   ├── smoke.dart                # E2E test: create -> project -> bloc -> format -> analyze -> test -> lint
│   └── docs_check.dart           # Validates all markdown links and documentation cross-references
├── docs/                         # Extended architectural guides, brick references, and roadmap
└── .github/workflows/            # GitHub Actions CI matrix (ci.yml, version-gate.yml, docs.yml)
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
3. **Linter Package Analysis**:
   ```bash
   dart analyze --fatal-infos packages/redux_rxdart_lints
   ```
4. **Workspace Formatting & Code Analysis**:
   ```bash
   dart format --set-exit-if-changed .
   dart analyze
   ```

## 🔒 Maintainer Rules

1. **Brick Versioning & CHANGELOG**: Every template or hook change to a brick requires bumping `version` in its `brick.yaml` and documenting changes in that brick's `CHANGELOG.md`.
2. **Documentation Currency**: Keep `README.md`, `docs/`, and brick documentation synchronized with template changes.
3. **Golden Rules Consistency**: Enforceable Golden Rules in `AGENTS.md` must be mirrored in `packages/redux_rxdart_lints`.
4. **Git Commit Policy**: Conventional Commits format (`feat(...)`, `fix(...)`, `docs(...)`). Never commit without explicit instruction.

See [`docs/contributing.md`](docs/contributing.md) for complete maintainer details.
