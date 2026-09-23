<div align="center">
  <img src="https://storage.googleapis.com/cms-storage-bucket/0dbfcc7a59cd1cf16282.png" alt="Flutter" width="100"/>
  <h1>The Opinionated Flutter RxDart Base Architecture</h1>
  <p><strong>A production-grade Mason Workspace with Autonomous AI Agent Harness & 3-Tier Migration Engine.</strong></p>
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
  [![Mason](https://img.shields.io/badge/Mason-CLI-blue)](https://pub.dev/packages/mason_cli)
  [![Redux](https://img.shields.io/badge/Redux-Session_Persistence-764ABC?logo=redux)](https://pub.dev/packages/redux)
  [![RxDart](https://img.shields.io/badge/RxDart-Ephemeral_BLoC-D60000)](https://pub.dev/packages/rxdart)
  [![Custom Lints](https://img.shields.io/badge/Lints-Analyzer_Enforced-green)](packages/redux_rxdart_lints/README.md)
  [![Docs](https://img.shields.io/badge/docs-GitHub_Pages-brightgreen)](https://TheJenilDGohel.github.io/Flutter-RxDart-Base/)
</div>

---

## 🎯 Why "Opinionated"?

Most Flutter codebases suffer from **decision fatigue** and **architectural drift**. Different developers (and AI coding assistants) invent different state patterns, mix business logic into widgets, and leak network tokens across screens.

This architecture is **unapologetically opinionated**:

1. **Strict Separation of Concerns**:
   - 🌐 **Redux (Global)**: Strictly for data that must survive navigation or cold restarts (Auth JWT, User Profile, Locale). Persisted to disk pre-first-frame.
   - ⚡ **RxDart (Local)**: Strictly for per-screen, ephemeral state (API fetches, form validation, UI toggles). Created in `initState()`, disposed in `dispose()`, never touches disk.
2. **Compiler-Enforced Guardrails (`redux_rxdart_lints`)**:
   Our Golden Rules aren't just documentation—they are compile-time `flutter analyze` errors:
   - ❌ Calling `Model.fromJson` inside a Repository $\rightarrow$ **Compile Error** (Repositories are transport only).
   - ❌ Calling `setState()` in a presentation widget $\rightarrow$ **Compile Error** (Declarative streams only).
   - ❌ Importing RxDart inside UI widgets $\rightarrow$ **Compile Error** (Widgets consume standard Dart `Stream<T>` / `ApiResponse<T>`).
3. **Deterministic AI Agent Harness**:
   Includes an integrated cognitive harness (`AGENTS.md`, `CLAUDE.md`, `.agents/skills/`) so AI assistants (Cursor, Claude Code, Antigravity) generate production-grade code that matches your stack on the first attempt.
4. **Self-Healing 3-Tier Migration Engine**:
   Upgrades upstream harness tooling (`scripts/agent/upgrade.dart`) without wiping ongoing sprint memory or custom team rules.

---

## 🏛️ Architectural Dataflow & Lifecycles

```text
┌────────────────────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER (UI / Widgets)                    │
│   • Views (StatefulWidget / StatelessWidget)                            │
│   • Declarative Binding: AppResponseBuilder<T> (handles spin/error/data)│
│   • Form & Action Toolkit: CommonButton, AppTextFormField, AppDialog   │
│   • Design System Tokens: ResColors.withValues(), AppTypography        │
└───────────────────▲────────────────────────────────▲───────────────────┘
                    │                                │
          Stream Subscription /                    StoreConnector /
          AppResponseBuilder (RxDart)              StoreBuilder (Redux)
                    │                                │
┌───────────────────┴──────────────────┐  ┌──────────┴──────────────────┐
│   LOCAL STATE (RxDart, ephemeral)    │  │  GLOBAL STATE (Redux,        │
│   • Feature BLoC (BehaviorSubject)   │  │  persistence-only)           │
│   • CancelTokenOwner lifecycle mixin │  │  • authToken, userData       │
│   • Reactive $ stream convention     │  │  • synced to SharedPrefs     │
│   • CompositeSubscription disposal   │  │                              │
└───────────────────▲──────────────────┘  └──────────▲──────────────────┘
                    │                                │
                    └────────────────┬───────────────┘
                                     │ Injected repository call with CancelToken
┌────────────────────────────────────┴───────────────────────────────────┐
│                       REPOSITORIES & SERVICES                          │
│   • Feature Repositories (Transport ONLY: raw Map<String, dynamic>)     │
│   • Global Services (NotificationService, DeviceInfoService)          │
└────────────────────────────────────▲───────────────────────────────────┘
                                     │ Requests raw JSON / Throws ApiException
┌────────────────────────────────────┴───────────────────────────────────┐
│                      NETWORKING LAYER (Dio Engine)                     │
│   • ApiBaseHelper (GET, POST, PUT, DELETE, postFormData, putFormData)  │
│   • CancelTokenOwner (automatic request abort on screen pop)           │
│   • DioClient (HTTP/2 Engine with 5-step Interceptor chain)            │
│   • Interceptors: Connectivity → Auth → Platform → Retry → ErrorMap    │
│   • Sealed ApiException Hierarchy (8 subtypes) + safe UI mapping       │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 💻 Code in Action

### 1. The Clean BLoC (`lib/features/profile/bloc/profile_bloc.dart`)
```dart
class ProfileBloc with CancelTokenOwner {
  final ProfileRepo _repo;
  final _profileSubject = BehaviorSubject<ApiResponse<UserProfile>>.seeded(
    const ApiResponse.initial(),
  );

  ProfileBloc({ProfileRepo? repo}) : _repo = repo ?? ProfileRepo();

  Stream<ApiResponse<UserProfile>> get profile$ => _profileSubject.stream;

  Future<void> fetchProfile() async {
    final token = createNewToken(); // Auto-cancels in-flight requests on refetch
    _profileSubject.add(const ApiResponse.loading());

    try {
      final rawJson = await _repo.fetchProfile(cancelToken: token);
      final model = UserProfile.fromJson(rawJson);
      if (!_profileSubject.isClosed) {
        _profileSubject.add(ApiResponse.completed(model));
      }
    } on ApiException catch (e) {
      if (!_profileSubject.isClosed && e is! RequestCancelledException) {
        _profileSubject.add(ApiResponse.error(e, retry: fetchProfile));
      }
    }
  }

  void dispose() {
    cancelRequests(); // Aborts active HTTP calls immediately when leaving page
    _profileSubject.close();
  }
}
```

### 2. The Declarative UI (`lib/features/profile/profile_page.dart`)
```dart
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = ProfileBloc()..fetchProfile();
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'User Profile',
      body: AppResponseBuilder<UserProfile>(
        stream: _bloc.profile$,
        builder: (context, profile) => ProfileContentWidget(profile: profile),
      ),
    );
  }
}
```

---

## 🧩 Mason Bricks at a Glance

| Brick / Package | Version | Command | Execution Frequency | Key Responsibilities |
|-----------------|---------|---------|---------------------|----------------------|
| **[`project`](docs/bricks/project.md)** | `1.2.1` | `mason make project` | **Once** per app | Scaffolds Redux store, Dio HTTP/2 engine with 5 interceptors, `ApiExceptionUIExt`, AppRouter, Toast helper (`ShowMessage`), CommonUtils, ResColors, AppTypography, L10n, and Showcase Demo. |
| **[`bloc`](docs/bricks/bloc.md)** | `1.1.0` | `mason make bloc` | **Repeatedly** per feature | Generates BLoC with `CancelTokenOwner`, injectable Repo, Model folder, Page, Content Widget, and Unit Tests. |
| **[`harness`](docs/bricks/harness.md)** | `1.5.0` | `mason make harness` | **Once** per project (auto-run by `project`) | Scaffolds `AGENTS.md`, compact `CLAUDE.md`, `.agents/skills/`, `.agents/agents/flutter-qa.md`, `.harness/` context store, `wire_route.dart`, and **`upgrade.dart`**. |
| **[`redux_rxdart_lints`](docs/packages/redux_rxdart_lints.md)** | `1.0.0` | Wired in `analysis_options.yaml` | Continuous analysis | Custom analyzer plugin turning Golden Rules #1, #3, and #4 into compile-time analyzer errors. |

---

## 🔄 Autonomous 3-Tier Harness Migration Engine

Upgrading scaffolding bricks in existing production apps is notoriously dangerous because naive tools overwrite active project context. 

The harness includes an **Autonomous 3-Tier Migration Engine** (`scripts/agent/upgrade.dart`):

```bash
# Upgrade harness to the latest release safely:
dart run scripts/agent/upgrade.dart
```

```
┌────────────────────────────────────────────────────────────────────────┐
│                        3-TIER MIGRATION ENGINE                         │
├────────────────────────────────────────────────────────────────────────┤
│ 1. Tier 1 (Core Engine): scripts/agent/ & .agents/skills/              │
│    -> OVERWRITE CLEANLY with latest upstream enhancements & fixes      │
│                                                                        │
│ 2. Tier 2 (Session Memory): .harness/active-context.md & progress.md   │
│    -> STRICTLY PROTECTED (0 bytes lost, preserves all ongoing tasks)   │
│                                                                        │
│ 3. Tier 3 (Shared Contract): AGENTS.md & CLAUDE.md                     │
│    -> SMART-MERGE: Adopts upstream rules, preserves custom team notes  │
└────────────────────────────────────────────────────────────────────────┘
```

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

## 📁 Generated Architecture Overview

```
AGENTS.md                                 # Universal AI agent contract (if include_harness)
CLAUDE.md                                 # Lean ~48-line memory transclusion (if include_harness)
scripts/agent/                            # wire_route.dart, upgrade.dart, verify.ps1, verify.sh
lib/
├── features/                             # Feature-first modules (showcase & user features)
├── l10n/                                 # Localization ARB files (en, hi)
├── networking/                           # Network engine layer
│   ├── interceptors/                     # 5-step Dio interceptor chain (Connectivity → Auth → Platform → Retry → ErrorMap)
│   ├── api_base_helper.dart              # Facade with GET/POST/PUT/DELETE & postFormData/putFormData
│   ├── api_constants.dart                # Base URL & endpoint registry
│   ├── api_exceptions.dart               # Sealed ApiException hierarchy (8 subtypes)
│   ├── api_response.dart                 # Sealed ApiResponse<T> (Initial, Loading, Success, Error)
│   ├── cancel_token_owner.dart           # CancelTokenOwner mixin for lifecycle request cancellation
│   └── dio_client.dart                   # HTTP/2 Dio client configuration
├── redux/                                # Global session persistence layer (Auth, Profile, Locale ONLY)
│   ├── middleware/                       # Logging & SharedPreferences persistence middleware
│   ├── reducers/                         # Pure reducer with exhaustive switch matching
│   ├── actions.dart                      # Sealed AppAction hierarchy
│   ├── app_state.dart                    # Immutable AppState
│   └── app_store.dart                    # Pre-frame store hydration & token provider
├── resources/                            # Design tokens (ResColors, Material 3 AppTypography)
├── services/                             # Notification & DeviceInfo stubs
├── utils/                                # Extensions, AppRouter, ShowMessage toasts
│   └── widgets/ui/                       # UI toolkit (AppResponseBuilder, CommonButton, AppDialog, AppCard)
└── main.dart                             # Pre-frame store hydration, ScreenUtil, AppRouter
```

---

## 📚 Documentation Directory

We provide in-depth documentation covering architecture, component guides, and roadmap:

- 🏛️ **[Architecture Specification](docs/architecture.md)** — Deep dive into Redux persistence, RxDart ephemeral BLoCs, and Dio interceptors.
- 🧱 **[Project Brick](docs/bricks/project.md)** — Full reference for the initial application bootstrapper brick.
- ⚡ **[BLoC Brick](docs/bricks/bloc.md)** — Feature module scaffolding and unit testing patterns.
- 🤖 **[Harness Brick](docs/bricks/harness.md)** — Cognitive contract, AI tooling, and 3-tier migration engine.
- 👮 **[Custom Lints (`redux_rxdart_lints`)](docs/packages/redux_rxdart_lints.md)** — Analyzer rules enforcing architectural boundaries.
- 🛠️ **[Maintainer & Contributing Guide](docs/contributing.md)** — Verification rules, brick versioning, and test gates.
- 🗺️ **[Improvement Roadmap](docs/roadmap.md)** — Completed milestones and future enhancement pipeline.

👉 **[Explore the Hosted GitHub Pages Documentation](https://TheJenilDGohel.github.io/Flutter-RxDart-Base/)**

---

### Contributing & License
Found an issue or want to contribute? Check out the [Contributing Guidelines](docs/contributing.md).  
Released under the [MIT License](https://github.com/TheJenilDGohel/Flutter-RxDart-Base/blob/main/LICENSE).
