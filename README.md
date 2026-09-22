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

## ðŸ“– The "Hybrid" Philosophy

Most Flutter apps struggle because they force one state management tool to do everything. This architecture splits responsibilities exactly where they belong:

- ðŸŒ  **Redux (Global)**: Persisted session state that survives navigation (Auth Tokens, User Profiles, Locale).
- âš¡ **RxDart (Local)**: Fast, ephemeral state per screen (API fetches, Form validations, UI toggles). Disposed instantly when you leave the screen.

No more polluted global stores. No more prop-drilling. Just clean, predictable state.

---

## âœ¨ Features That Set This Apart

- ðŸ › **Mason Bricks**: Scaffold entire projects or feature modules instantly using `mason make project` or `mason make bloc`.
- ðŸ¤– **AI Agent Harness**: Comes with a built-in `harness` brick that injects AI rules (`CLAUDE.md`, `.agents/`) so tools like Cursor, Copilot, or Claude Code write code perfectly matching this architecture.
- ðŸ‘® **Custom Lints (`redux_rxdart_lints`)**: The architectural rules aren't just proseâ€”they are strictly enforced `flutter analyze` errors. Try to use `setState` or bleed RxDart into the UI, and the linter will stop you.
- ðŸ”Œ **Declarative UI**: Forget manual `StreamBuilder` logic. Use the provided `AppResponseBuilder` to automatically handle loading spinners, error states, and retry callbacks declaratively.
- ðŸŒ  **Dio HTTP/2**: Built-in `CancelTokenOwner` automatically aborts pending network requests if the user navigates away, preventing memory leaks.

---

## ðŸš€ Quick Start

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

## ðŸ“š Extensive Documentation

We've moved the deep architectural documentation, component guides, and roadmap to a beautiful, searchable GitHub Pages site.

ðŸ‘‰ **[Explore the Full Documentation Here](https://TheJenilDGohel.github.io/Flutter-RxDart-Base/)**

---

### Contributing & License
Found an issue or want to contribute? Check out the [Contributing Guidelines](https://TheJenilDGohel.github.io/Flutter-RxDart-Base/contributing/).
Released under the MIT License.
