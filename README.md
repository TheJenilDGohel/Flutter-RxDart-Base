<div align="center">
  <img src="https://storage.googleapis.com/cms-storage-bucket/0dbfcc7a59cd1cf16282.png" alt="Flutter" width="100"/>
  <h1>Flutter RxDart Base Architecture</h1>
  <p><strong>A production-grade Mason Workspace for high-performance Hybrid State Management.</strong></p>
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
  [![Mason](https://img.shields.io/badge/Mason-CLI-blue)](https://pub.dev/packages/mason_cli)
  [![Redux](https://img.shields.io/badge/Redux-Session_Persistence-764ABC?logo=redux)](https://pub.dev/packages/redux)
  [![RxDart](https://img.shields.io/badge/RxDart-Ephemeral_BLoC-D60000)](https://pub.dev/packages/rxdart)
  [![Docs](https://img.shields.io/badge/docs-GitHub_Pages-brightgreen)](https://TheJenilDGohel.github.io/Flutter-RxDart-Base/)
</div>

## 📖 The "Hybrid" Philosophy

Most Flutter apps struggle because they force one state management tool to do everything. This architecture splits responsibilities exactly where they belong:

- 🌐 **Redux (Global)**: Persisted session state that survives navigation (Auth Tokens, User Profiles, Locale).
- ⚡ **RxDart (Local)**: Fast, ephemeral state per screen (API fetches, Form validations, UI toggles). Disposed instantly when you leave the screen.

No more polluted global stores. No more prop-drilling. Just clean, predictable state.

---

## ✨ Features That Set This Apart

- 🧱 **Mason Bricks**: Scaffold entire projects or feature modules instantly using `mason make project` or `mason make bloc`.
- 🤖 **AI Agent Harness**: Comes with a built-in `harness` brick that injects AI rules (`CLAUDE.md`, `.agents/`) so tools like Cursor, Copilot, or Claude Code write code perfectly matching this architecture.
- 👮 **Custom Lints (`redux_rxdart_lints`)**: The architectural rules aren't just prose—they are strictly enforced `flutter analyze` errors. Try to use `setState` or bleed RxDart into the UI, and the linter will stop you.
- 🔌 **Declarative UI**: Forget manual `StreamBuilder` logic. Use the provided `AppResponseBuilder` to automatically handle loading spinners, error states, and retry callbacks declaratively.
- 🌐 **Dio HTTP/2**: Built-in `CancelTokenOwner` automatically aborts pending network requests if the user navigates away, preventing memory leaks.

---

## 🧩 Mason Bricks at a Glance

| Brick / Package | Version | Command | Execution Frequency | Key Responsibilities |
|-----------------|---------|---------|---------------------|----------------------|
| **[`project`](docs/bricks/project.md)** | `1.2.0` | `mason make project` | **Once** per app | Scaffolds Redux store, Dio HTTP/2 engine with 5 interceptors, `ApiExceptionUIExt`, AppRouter, Toast helper (`ShowMessage`), CommonUtils, ResColors, AppTypography, L10n, and Showcase Demo. |
| **[`bloc`](docs/bricks/bloc.md)** | `1.1.0` | `mason make bloc` | **Repeatedly** per feature | Generates BLoC with `CancelTokenOwner`, injectable Repo, Model folder, Page, Content Widget, and Unit Tests. |
| **[`harness`](docs/bricks/harness.md)** | `1.4.2` | `mason make harness` | **Once** per project (auto-run by `project`) | Scaffolds `AGENTS.md`, compact `CLAUDE.md`, `.agents/skills/`, `.agents/agents/flutter-qa.md`, `.harness/` context store, and `wire_route.dart`. |
| **[`redux_rxdart_lints`](docs/packages/redux_rxdart_lints.md)** | `1.0.0` | Wired in `analysis_options.yaml` | Continuous analysis | Analyzer plugin turning Golden Rules #1, #3, and #4 into compile-time analyzer errors. |

---

## 🚀 Quick Start

### 1. Install Bricks Globally via Mason CLI
```bash
mason add -g project --git-url https://github.com/TheJenilDGohel/Flutter-RxDart-Base.git --git-path bricks/project
mason add -g bloc --git-url https://github.com/TheJenilDGohel/Flutter-RxDart-Base.git --git-path bricks/bloc
mason add -g harness --git-url https://github.com/TheJenilDGohel/Flutter-RxDart-Base.git --git-path bricks/harness
```

### 2. Scaffold Your App
```bash
flutter create my_app
cd my_app
mason make project
```

### 3. Add Feature Modules
```bash
# If using the AI Harness, wire the route automatically:
dart run scripts/agent/wire_route.dart auth /auth

# Otherwise, just scaffold the BLoC manually:
mason make bloc
```

---

## 📚 Documentation Directory

We provide in-depth documentation covering architecture, component guides, and roadmap:

- 🏛️ **[Architecture Specification](docs/architecture.md)** — Deep dive into Redux persistence, RxDart ephemeral BLoCs, and Dio interceptors.
- 🧱 **[Project Brick](docs/bricks/project.md)** — Full reference for the initial application bootstrapper brick.
- ⚡ **[BLoC Brick](docs/bricks/bloc.md)** — Feature module scaffolding and unit testing patterns.
- 🤖 **[Harness Brick](docs/bricks/harness.md)** — Cognitive contract and tooling for AI-assisted workflows.
- 👮 **[Custom Lints (`redux_rxdart_lints`)](docs/packages/redux_rxdart_lints.md)** — Analyzer rules enforcing architectural boundaries.
- 🛠️ **[Maintainer & Contributing Guide](docs/contributing.md)** — Verification rules, brick versioning, and test gates.
- 🗺️ **[Improvement Roadmap](docs/roadmap.md)** — Completed milestones and future enhancement pipeline.

👉 **[Explore the Hosted GitHub Pages Documentation](https://TheJenilDGohel.github.io/Flutter-RxDart-Base/)**

---

### Contributing & License
Found an issue or want to contribute? Check out the [Contributing Guidelines](docs/contributing.md).  
Released under the [MIT License](https://github.com/TheJenilDGohel/Flutter-RxDart-Base/blob/main/LICENSE).
