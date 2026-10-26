# redux_rxdart_lints

Dart analyzer plugin (`analysis_server_plugin`) enforcing the Redux+RxDart+Dio
architecture golden rules documented in the harness's `AGENTS.md`, at
`dart analyze` / `flutter analyze` time instead of relying on an AI agent (or
human) remembering them.

## Rules

All path checks use the path **relative to `lib/`**, so results never depend
on where the project is checked out.

| Rule | Golden Rule | Flags |
|---|---|---|
| `no_rxdart_in_ui` | #4 Zero RxDart Outside BLoC | `import`/`export` of `package:rxdart/...` anywhere except `bloc/` folders, `*_bloc.dart`, `redux/`, `networking/`, `services/` and non-widget `utils/` (`utils/widgets/` is UI and is checked) |
| `no_setstate_in_widget` | #3 Zero setState | calls that resolve to Flutter's `State.setState`. Design-system primitives in `lib/utils/widgets/ui/` are exempt (purely visual state) |
| `no_screenutil_in_private_widget` | #13 ScreenUtil only in public widgets | `flutter_screenutil` extensions (`.w .h .r .sp ...`, resolved to the package — your own `.w` extension is ignored) inside a private (`_Foo`) widget of any kind, or the `State` of one. ScreenUtil 5.9.x does not rebuild private widgets on resize |
| `repo_transport_only` | #1 Repository is Transport ONLY | `fromJson` / `fromMap` calls **and tear-offs** (`.map(Model.fromJson)`) in a repository: files under `repo/` or `repository/`, or named `*_repo.dart` / `*_repository.dart` |
| `no_exception_tostring` | #2 BLoC owns errors, UI shows `userFacingMessage` | `toString()` on an error variable (`e`, `err`, `error`, `exception`) in UI code; BLoCs, repos, `networking/`, `redux/` and `services/` are exempt |
| `no_with_opacity` | #14 No withOpacity in UI | `.withOpacity()` in widgets; recommends `Color.withValues(alpha: ...)` or design-system color tokens for predictable performance |
| `no_unclosed_subject` | #15 Dispose all RxDart subjects | `BehaviorSubject`, `PublishSubject`, `ReplaySubject` field in BLoC not closed in `dispose()` |
| `no_fetch_without_token` | #8 Fetch cancellation | BLoC `fetch()` method that does not call `createNewToken()` to cancel overlapping requests |

## Testing

`example/` is a fixture Flutter project. Lines that must be flagged carry
`// expect_lint: <rule>` on the line above; every other line must stay clean.
From this package's root:

```bash
dart run tool/check_fixture.dart
```

It adds this package to `example/analysis_options.yaml` with an absolute path
while it runs, analyzes the fixture and fails on a missing *or* an unexpected
diagnostic. CI runs it on every push. Add a positive and a negative case to
the fixture with every rule change.

## Usage

Nothing goes in `pubspec.yaml`. In the consuming project's
`analysis_options.yaml`, add a **top-level** `plugins:` block (not under
`analyzer:`):

```yaml
plugins:
  redux_rxdart_lints:
    git:
      url: https://github.com/jenilseawind-glitch/Flutter-RxDart-Base.git
      path: packages/redux_rxdart_lints
      ref: main
```

The analysis server resolves the plugin itself, so `flutter analyze`,
`dart analyze`, the IDE, the Dart MCP server's `analyze_files` and the
harness's `scripts/agent/verify.dart` all report the rules. Restart the
analysis server after changing the block.

- **SDK**: the plugin needs Dart 3.11+. A `git:` source needs Dart 3.13+
  (Flutter 3.47+); older analysis servers skip it **silently** (no rule runs,
  no warning). On Dart 3.11–3.12 use a `path:` source.
- **Local checkout**: `path: <absolute path>/packages/redux_rxdart_lints`. The
  path must be absolute; a relative one is not picked up.
- **Updates**: the server pins `ref: main` to a commit the first time it
  resolves the plugin (`resolved-ref` in its cache). To pick up newer rules,
  delete the analysis server's plugin cache (`.dartServer/.plugin_manager` in
  your home or `%LOCALAPPDATA%` folder) and restart it, or pin a commit with
  `ref:`.
