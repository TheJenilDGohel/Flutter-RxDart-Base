# Changelog

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
