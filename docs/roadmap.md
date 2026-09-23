# Improvement Roadmap

Status: **Executed & Verified.** Phases 0 through 6 are fully implemented and passing end-to-end verification quality gates as of 2026-09-23.

Paths below are relative to `bricks/project/__brick__/` unless stated otherwise.

## 1. Summary

The core design is sound: sealed `ApiException` / `ApiResponse`, per-screen BLoC with `CancelTokenOwner`, disciplined brick versioning, and an honest `base-gaps.md`. All historical gaps around false claims, missing CI, or unverified brick outputs have been resolved with automated end-to-end smoke testing (`tool/smoke.dart`), link validation (`tool/docs_check.dart`), GitHub Actions CI matrix (`ci.yml`, `version-gate.yml`), and a streamlined AI Agent Harness v1.4.2.

## 2. Findings Resolution

### P0: False claims and broken guarantees (All Resolved)

1. ~~**The lint plugin is orphaned.**~~ *(Fixed: Wired `custom_lint` and `redux_rxdart_lints` into project template's `pubspec.yaml` and `analysis_options.yaml` via mustache `{{#include_harness}}`)*
2. ~~**The base breaks its own Rule 3 (zero `setState`).**~~ *(Fixed: Migrated showcase and form toggles to RxDart BLoC pattern with BehaviorSubjects)*
3. ~~**Freshly generated `bloc` output fails quality gate.**~~ *(Fixed: BLoC template imports `api_response.dart` directly; unit test template includes `Fake...Repo` mock with initial stream matcher; all unused fields/imports removed)*
4. ~~**A cancelled request surfaces as an error.**~~ *(Fixed: Added `RequestCancelledException` and proper cancel token handling)*
5. ~~**Non-object bodies escape as `TypeError`.**~~ *(Fixed: Typed network methods in `ApiBaseHelper` with `<dynamic>` to safely accommodate lists and primitive JSON payloads)*
6. ~~**`ApiResponse` subtype names collide.**~~ *(Fixed: Renamed to `ErrorResponse`, `InitialResponse`, `LoadingResponse`, `SuccessResponse`)*
7. ~~**`AppStore` cannot be re-initialised.**~~ *(Fixed: Removed `final` keyword from `_store` to allow clean re-hydration across test suites and hot restarts)*
8. ~~**The SDK constraint is hard-pinned.**~~ *(Fixed: Relaxed to `>=3.0.0 <4.0.0`)*

### P1: Drift, hygiene, developer experience (All Resolved)

- ~~**Doc drift.**~~ *(Fixed: Cleaned up interceptor names, corrected `AppResponseBuilder`, standardized `ui/` component references, eliminated broken code fences in `architecture.md`, and fixed UTF-8 encoding across all docs)*
- ~~**No tests and no CI.**~~ *(Fixed: Added full GitHub Actions CI matrix in `.github/workflows/ci.yml`, `version-gate.yml`, and `docs.yml`)*
- ~~**Duplicated skill and heavy context.**~~ *(Fixed: Harness 1.4.2 trimmed `CLAUDE.md` to ~48 lines (~500 tokens), using `@.harness/active-context.md` transclusion for lean cross-session memory without context bloat)*
- ~~**`snapshot.dart` and `verify`.**~~ *(Fixed: Quality gates verified; deterministic smoke testing added)*
- ~~**`wire_route.dart`.**~~ *(Fixed: Scaffolds feature and injects routes cleanly with validation)*
- ~~**Deprecated UI methods.**~~ *(Fixed: Replaced `.withOpacity(...)` with Flutter 3.27+ `.withValues(alpha: ...)`)*
- ~~**RenderFlex overflow in buttons.**~~ *(Fixed: Wrapped `CommonButton` label in `Flexible` + `TextOverflow.ellipsis`)*
- ~~**No contributor entry point at repo root.**~~ *(Fixed: Added root `AGENTS.md` and `CLAUDE.md` pointing maintainers and agents to `docs/contributing.md`, `tool/smoke.dart`, and `tool/docs_check.dart`)*

---

## 3. Plan & Implementation Status

- [x] **Phase 0: Baseline Smoke Test**
  - Added `tool/smoke.dart`: Runs `flutter create` -> `mason make project` -> `mason make bloc` -> `dart format` -> `flutter analyze` -> `flutter test` -> `custom_lint`.
  - Resolution: 100% pass on Windows and Linux CI.

- [x] **Phase 1: Template Correctness**
  - Resolved P0 items 3-8: clean generated code, `RequestCancelledException`, list handling in `ApiBaseHelper`, sealed `ApiResponse` subtypes, re-initializable `AppStore`, relaxed SDK constraints.
  - Bumped `project` to `1.2.0` and `bloc` to `1.1.0` with full CHANGELOGs.

- [x] **Phase 2: Analyzer & Custom Lint Enforcement**
  - Wired `custom_lint` and `redux_rxdart_lints` into project templates without fragile hooks.
  - Rules 1, 3, and 4 enforced at compile time.

- [x] **Phase 3: CI & Verification Automation**
  - GitHub Actions matrix running smoke tests, lint package validation, format checks, and analyzer gates.
  - Version-gate workflow ensuring any template change includes a version bump and CHANGELOG entry.
  - `tool/docs_check.dart` validating markdown link integrity across all files.

- [x] **Phase 4: Base DX Upgrades**
  - Isolated BLoC unit testing template with `Fake...Repo` mock and stream matchers.
  - `CancelTokenOwner.createNewToken()` returns the instantiated token for direct assignment.
  - Button text overflow resilience.

- [x] **Phase 5: Harness Diet**
  - Harness 1.4.2 pure template brick with zero hooks.
  - `CLAUDE.md` condensed to ~48 lines (~500 tokens).
  - Cross-session memory handled via `@.harness/active-context.md`.

- [x] **Phase 6: Release Hygiene**
  - Synced all READMEs (`README.md`, `bricks/*/README.md`, `packages/*/README.md`).
  - Added repository root `AGENTS.md` and `CLAUDE.md`.
  - All `docs/` and brick cross-references passing link check.
