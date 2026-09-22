# Flutter Hybrid Architecture & Mason Workspace

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Mason](https://img.shields.io/badge/Mason-CLI-blue)](https://pub.dev/packages/mason_cli)
[![Docs](https://img.shields.io/badge/docs-GitHub_Pages-brightgreen)](https://TheJenilDGohel.github.io/Flutter-RxDart-Base/)

A production-grade **Mason Workspace** for bootstrapping robust Flutter applications using a high-performance **Hybrid State Management Architecture**.

## ðŸ“– Documentation

All documentation, architecture guides, and setup instructions have been moved to our dedicated documentation site!

**ðŸ‘‰ [View the Full Documentation](https://TheJenilDGohel.github.io/Flutter-RxDart-Base/)**

### Quick Links
- [Architecture Guide](https://TheJenilDGohel.github.io/Flutter-RxDart-Base/architecture/)
- [Project Brick Setup](https://TheJenilDGohel.github.io/Flutter-RxDart-Base/bricks/project/)
- [BLoC Brick Setup](https://TheJenilDGohel.github.io/Flutter-RxDart-Base/bricks/bloc/)
- [Agent Harness](https://TheJenilDGohel.github.io/Flutter-RxDart-Base/bricks/harness/)

---

## âš¡ Quick Start

### 1. Install Bricks Globally via Mason CLI
```bash
mason add -g project --git-url https://github.com/TheJenilDGohel/Flutter-RxDart-Base.git --git-path bricks/project
mason add -g bloc --git-url https://github.com/TheJenilDGohel/Flutter-RxDart-Base.git --git-path bricks/bloc
mason add -g harness --git-url https://github.com/TheJenilDGohel/Flutter-RxDart-Base.git --git-path bricks/harness
```

### 2. Create Your Flutter Project
```bash
flutter create my_app
cd my_app
```

### 3. Bootstrap Architecture (`mason make project`)
From inside your new Flutter project directory:
```bash
mason make project
```

For full details on the `project`, `bloc`, and `harness` commands, visit the [Documentation Site](https://TheJenilDGohel.github.io/Flutter-RxDart-Base/).
