# Flutter RxDart Base

Generate a Flutter app with one fixed architecture (Redux for the session, one RxDart BLoC per screen, Dio for networking), lint rules that enforce it, and an AI agent harness that teaches coding agents to follow it.

[![Flutter](https://img.shields.io/badge/Flutter-3.38%2B-02569B?logo=flutter)](https://flutter.dev)
[![Mason](https://img.shields.io/badge/Mason-bricks-blue)](https://pub.dev/packages/mason_cli)
[![Lints](https://img.shields.io/badge/architecture-analyzer_enforced-green)](docs/packages/redux_rxdart_lints.md)

---

## Quick start

```bash
# 1. Install the bricks (once per machine)
#    fork-url: the fork until upstream (TheJenilDGohel) merges the 1.6+ work.
mason add -g project --git-url https://github.com/jenilseawind-glitch/Flutter-RxDart-Base.git --git-path bricks/project
mason add -g bloc    --git-url https://github.com/jenilseawind-glitch/Flutter-RxDart-Base.git --git-path bricks/bloc
mason add -g harness --git-url https://github.com/jenilseawind-glitch/Flutter-RxDart-Base.git --git-path bricks/harness

# 2. Create an app and apply the architecture
flutter create my_app && cd my_app
mason make project      # asks for the project name, app ids, harness (Y) and secure storage (N)

# 3. Add a screen: scaffolds the feature and wires its route
dart run scripts/agent/wire_route.dart profile

# 4. Check everything: format, analyze, architecture lints, tests
dart run scripts/agent/verify.dart
```

`flutter run` works straight away and opens a showcase screen. Without the harness, use `mason make bloc` and add the route by hand.

---

## What's in the box

| | Version | How you use it | What it gives you |
|---|---|---|---|
| [`project`](docs/bricks/project.md) | `1.5.0` | `mason make project`, once | Redux session store, Dio client with 5 interceptors, typed errors, router, design tokens, UI kit, l10n (en, hi), showcase screen |
| [`bloc`](docs/bricks/bloc.md) | `1.2.1` | `mason make bloc`, once per screen | BLoC, repo, model, page, content widget and 7 passing BLoC tests |
| [`harness`](docs/bricks/harness.md) | `2.3.0` | installed by `project` | `AGENTS.md`, Token Shield, Cursor rules, anti-loop guard, specialist swarm, Maestro testing, quality gates, lessons loop |
| [`redux_rxdart_lints`](docs/packages/redux_rxdart_lints.md) | `0.4.0` | wired in by `project` | Turns five golden rules into analyzer errors |

---

## The architecture in one minute

- **Redux holds only the session**: auth token, user data, locale. It's persisted and survives restarts. Nothing else goes there.
- **Each screen has one RxDart BLoC** for everything it shows: fetching, forms, search, paging. The page creates it and disposes it.
- **Dio does the networking** behind `ApiBaseHelper`, through a fixed chain: connectivity → auth → platform → retry → error mapping. Every failure is a typed `ApiException`, and screens receive a sealed `ApiResponse<T>` (initial, loading, success, or error with retry).

```
Page ──stream──▶ BLoC ──await──▶ Repo ──▶ ApiBaseHelper ──▶ Dio + interceptors
                 parses JSON     returns the raw Map
Page dispatches to Redux only when the session changes (sign-in, profile, logout)
```

A feature is one folder:

```
lib/features/profile/
├── bloc/profile_bloc.dart              # state and logic; public streams end in $
├── repo/profile_repo.dart              # HTTP only, returns the raw Map
├── model/profile_model.dart            # defensive fromJson
├── widgets/profile_content_widget.dart # draws the parsed model
└── profile_page.dart                   # owns the BLoC, renders with AppResponseBuilder
```

The architecture lints (in the IDE and in `verify.dart`) reject parsing in repos, `setState` in feature widgets, RxDart in widgets, and ScreenUtil sizes in private widgets. All 13 golden rules are in the generated `AGENTS.md`, and the design is explained in [Architecture](docs/architecture.md).

---

## The Opinionated AI Agent Setup (Harness v2.1.1)

This repository couples architecture with a battle-tested **AI Agent Harness** engineered specifically for frontier coding agents (Claude Code, Cursor, Codex, Gemini CLI). It transforms chaotic LLM edits into a deterministic, token-efficient assembly line:

### 1. 🛡️ Token Shield & Context Slicing
- **1-Hour Prompt Caching**: Configured `promptCacheTtl: "1h"` and `subagentPromptCacheTtl: "1h"` in `.claude/settings.json` to leverage Anthropic prompt caching across deep conversations.
- **Context-Slicing Path Rules (`.claude/rules/`)**: Architecture standards (`bloc.md`, `ui.md`, `endpoints.md`, `testing.md`) cost **0 baseline tokens**. They are injected dynamically by Claude Code and Cursor only when matching paths are edited.
- **Output Clamping & Deny Boundaries**: Terminal outputs clamped to 4,000 chars (`bashOutputMaxChars: 4000`) preventing token-draining build logs. Deny rules strictly guard keystores, provisioning profiles, `.dart_tool/`, and generated files (`*.g.dart`, `*.freezed.dart`).

### 2. 🐝 Specialist Agent Swarm & Coordination
Instead of one generalist agent running out of context, tasks multiplex across lean specialist agents (`.claude/agents/`) configured with `omitClaudeMd: true`:
- `@bloc-specialist`: RxDart stream lifecycles, composite subscriptions, emit guards, and concurrency recipes.
- `@ui-artisan`: ScreenUtil public widgets, ResColors tokens, `AppResponseBuilder`, l10n, and zero `setState`.
- `@device-qa`: Declarative end-to-end device testing via Maestro CLI and MCP.
- `@flutter-qa`: One-shot architectural conformance, layer boundary enforcement, and lint audits.
- `@skeptic`: Adversarial plan reviewer attacking reactive state and stream edge cases before coding begins.
- `@docs-scout`: Token-efficient library and documentation researcher (<200 words) shielding the main context.
- **Coordination**: Supports single-terminal in-process handoffs and concurrent multi-session Git worktrees (`.worktreeinclude`) via `scripts/team/task_handoff.dart` and `scripts/team/heartbeat.dart` (`.harness/team-protocol.md`).

### 3. 📱 Declarative Device Automation (Maestro)
Replaces brittle accessibility tree parsing and screenshot OCR with deterministic **Maestro YAML flows** (`.maestro/flows/smoke_launch.yaml`). The agent tests real mobile apps on emulators and devices via `maestro test` with zero prompt token bloat.

### 4. 📚 Production Repository Recipes
Codifies production-grade patterns in `.agents/skills/add-endpoint/repo-recipes.md`:
- Standard CRUD with defensive query filtering (`_sanitizeFilters`).
- Capability mixins (`SoftDeletableRepoMixin`, `ActiveToggleRepoMixin`).
- Multipart file and media uploads (`UploadMediaRepoMixin`).
- Bulk and unpaginated fetches (`all=true` with batching fallback).
- Binary streaming and PDF document downloads.
- Cache-aside repositories with in-memory TTL.

### 5. 🧠 5-Tier Memory & Learning Model
Eliminates ceremonial task close-out blockers in favor of a layered memory architecture:
1. **Tier 1 (Ambient)**: Claude Code Auto-Memory (`MEMORY.md` + Auto-Dream) for ambient personal learning across sessions.
2. **Tier 2 (Structured Knowledge Graph)**: Anthropic `@modelcontextprotocol/server-memory` registered in `.mcp.json` for persistent technical facts and API quirks on demand.
3. **Tier 3 (Path-Scoped Rules)**: Invariant standards codified in `.claude/rules/*.md`.
4. **Tier 4 (Permanent Team Rules)**: Repository-wide non-negotiables in `AGENTS.md` §7.
5. **Tier 5 (Offline CLI)**: `scripts/agent/learn.dart` for offline verification and proposing upstream fixes.

Try: *"Add a profile screen for `GET /me`; the Postman collection is in `docs/`."* More in [the harness docs](docs/bricks/harness.md).

---

## Upgrading the harness in an app

```bash
dart run scripts/agent/upgrade.dart
```

It renders the latest release, updates only harness files, and keeps your memory, lessons, own scripts and project rules. On 1.7.0 or older, install the new `upgrade.dart` first; see [Upgrading from 1.7.0 or older](docs/bricks/harness.md#upgrading-from-170-or-older).

---

## Documentation

- [Architecture](docs/architecture.md): layers, the state rule, networking, trade-offs
- Bricks: [`project`](docs/bricks/project.md) · [`bloc`](docs/bricks/bloc.md) · [`harness`](docs/bricks/harness.md) · lints: [`redux_rxdart_lints`](docs/packages/redux_rxdart_lints.md)
- [AI harness research](docs/ai-harness-rnd.md): why the harness works the way it does
- [Roadmap](docs/roadmap.md) · [Contributing](docs/contributing.md)

## Contributing

Every template change bumps its brick's version and CHANGELOG, and CI generates a real app to test it: see [Contributing](docs/contributing.md). AI agents working on this repository should use the `base-maintainer` skill in `.agents/skills/base-maintainer/`.

Released under the [MIT License](LICENSE).
