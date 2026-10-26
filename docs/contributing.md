# Maintainer Rules

Rules for changing this workspace: `bricks/project`, `bricks/bloc`, `bricks/harness`,
`packages/redux_rxdart_lints`.

## 1. Every behavior change to a Brick bumps its version + CHANGELOG

If you touch `hooks/pre_gen.dart`, `hooks/post_gen.dart`, or any file under `__brick__/` in a way
that changes generated output or hook behavior:

- Bump `version:` in that brick's `brick.yaml` (semver — patch for fixes, minor for new
  capabilities, major for breaking template/var changes).
- Add an entry to that brick's `CHANGELOG.md` (`bricks/project/CHANGELOG.md`, `bricks/bloc/CHANGELOG.md`, and `bricks/harness/CHANGELOG.md` are all actively maintained).

Cosmetic-only changes (formatting, comments) don't require a bump.

**SDK floors** (`environment: sdk:` / `flutter:` in hook, template and package pubspecs) are the
*lowest* versions the code and its dependencies need, checked against each dependency's own
constraint on pub.dev. Never set them to the toolchain you happened to test on: a floor that is
too high breaks `mason upgrade` for everyone one Flutter release behind. CI runs the smoke test on
the minimum supported Flutter to catch this.

## 2. README is documentation, not a changelog — but it must not go stale

Every README (`README.md`, `bricks/*/README.md`, `packages/*/README.md`) documents *current*
generated output and hook behavior. When you change what a hook does or what a template
generates, update the README in the same change — don't defer it.

This bit us once already: `bricks/project/hooks/post_gen.dart` had `flutter gen-l10n` and the
`mason make harness` auto-install step added without `bricks/project/README.md`'s "Hook Execution
Summary" being updated to match. Don't let that gap reopen — grep the relevant README before
calling a hook/template change done.

## 3. New Brick checklist

- `brick.yaml` (name, description, version, mason environment constraint).
- `__brick__/` templates.
- `hooks/pre_gen.dart` / `post_gen.dart` only if needed — don't add hooks with no behavior.
- `README.md` — usage, prompted vars table, what gets generated, hook execution summary.
- Register it in root `mason.yaml`.
- Add a row to the root `README.md`'s "Mason Bricks at a Glance" table.

## 4. Golden Rules changes propagate to the lint plugin

If you change a Golden Rule in `bricks/harness/__brick__/AGENTS.md` that's mechanically
enforceable (repo-transport-only, zero setState, zero RxDart outside BLoC, or a new one), update
the matching rule in `packages/redux_rxdart_lints/lib/src/rules/`. A rule documented in AGENTS.md
but not enforced by the plugin is a silent drift risk — either enforce it or don't claim it's
analyzer-enforced.

## 5. Verify before committing

- **Docs & Link Integrity**: Run `dart run tool/docs_check.dart` from the repository root. Validates that all relative links and cross-references in `README.md`, `docs/`, and brick documentation resolve to real files.
- **Full E2E Smoke Test**: Run `dart run tool/smoke.dart` from the repository root. Exercises the full end-to-end flow: `flutter create` -> `mason make project` -> `mason make bloc` -> `dart format` -> `flutter analyze` -> `flutter test`.
- **Linter Package Analysis**: Run `dart analyze --fatal-infos` inside `packages/redux_rxdart_lints/`.
- **Formatting & Analysis**: Run `dart format --set-exit-if-changed .` and `dart analyze` across all touched packages and hook directories (`bricks/*/hooks/`).
- **Harness checks**: `dart run tool/harness_check.dart` (docs name only generated paths, types
  and lint rules; skills are consistent), `dart run tool/test_harness_upgrade.dart` and
  `dart run tool/test_harness_learn.dart` (the real `upgrade.dart` and `learn.dart`, end to end).
- If you change `wire_route.dart` or a hook's file-injection logic, dry-run it against the real
  templates in a scratch copy before trusting the regex — don't assume it's correct from reading
  it. (Silent no-ops in generated/injected files are the failure mode to watch for.)

### Harness skills

The harness ships eight [Agent Skills](https://agentskills.io) in
`bricks/harness/__brick__/.agents/skills/`, each with a Claude Code entry point in `.claude/skills/`.
Agents follow them literally, so:

- **Only real code.** Paths, project types and lint rules must exist in the bricks;
  `tool/harness_check.dart` enforces it. Cite golden rules by number instead of restating them.
- **Code that compiles and behaves.** `tool/smoke.dart` pastes every code block of
  `manage-state/bloc-recipes.md` verbatim into the generated app (`tool/harness_recipes.dart`,
  scaffolding in `tool/recipe_fixture/`), so `flutter analyze` (which runs the lint plugin) and
  `tool/recipe_fixture/test/recipes_test.dart` fail CI when a recipe stops compiling, breaks a golden
  rule or stops doing what the skill says. Adding or reordering a block means updating the fixture
  markers. Snippets in other skills (for example `redux-changes.md`) are checked by hand in a
  generated app.
- **Frontmatter.** `name` equals the folder, lowercase-hyphenated, at most 64 characters;
  `description` at most 1024 characters and says what the skill does *and when to use it*. The
  `.claude/skills/<name>/SKILL.md` entry point copies both verbatim.
- **Adding, renaming or removing a skill** changes `managed_skills` in
  `bricks/harness/__brick__/.harness/version.json`, which `upgrade.dart` uses to replace shipped skills
  and remove ones no longer shipped. Never touch project-owned files: `.harness/` and everything
  below the `harness:project-rules` marker.
- **Lessons from apps.** Projects promote harness-level lessons with the `upstream` target, and
  `learn.dart upstream` prints them. Verify each against the bricks, fix it where it belongs (skill
  text, recipe, template, lint rule), and bump the harness like any other change. The
  `base-maintainer` skill (`.agents/skills/base-maintainer/`) walks through it.

## 6. URLs point at one canonical org

The canonical repository is **`https://github.com/TheJenilDGohel/Flutter-RxDart-Base.git`**
(the upstream). All git-dependency URLs, `mason add -g --git-url` examples and README links
should use it. If the working remote (`git remote -v`) differs, ask before writing new URLs;
don't guess.

### Temporary exception: fork URLs until upstream merges

Development currently happens in the fork `jenilseawind-glitch/Flutter-RxDart-Base`, which is
ahead of upstream (fork: project 1.5.0, bloc 1.2.1, harness 1.8.0, `redux_rxdart_lints` 0.4.0 as a native
analyzer plugin; upstream: project 1.1.0, bloc 1.0.0, harness 1.4.1). Upstream `main` still ships `redux_rxdart_lints` 0.1.0 on analyzer 7 /
`custom_lint_builder ^0.7`, which conflicts with the template and crashes
on Flutter 3.47. Pointing generated apps at upstream today would break `flutter pub get` in
every new project, so these **functional** URLs intentionally name the fork:

| File | What depends on it |
|---|---|
| `README.md`, `docs/index.md` | Quick Start `mason add -g` commands (upstream's bricks are years behind) |
| `bricks/project/__brick__/analysis_options.yaml` | `redux_rxdart_lints` git plugin of every generated app |
| `bricks/harness/__brick__/.harness/version.json` | `upstream_repo` used by `upgrade.dart` |
| `bricks/harness/__brick__/scripts/agent/upgrade.dart` | fallback `upstream` URL (`--check-only`, `mason add` hint) |
| `packages/redux_rxdart_lints/README.md`, `docs/packages/redux_rxdart_lints.md` | install snippet |
| `docs/bricks/bloc.md`, `docs/bricks/harness.md` | CHANGELOG links |
| `bricks/harness/README.md`, `docs/bricks/harness.md` | `curl` of the current `upgrade.dart` for projects on ≤ 1.7.0 |
| `docs/index.md`, `docs/roadmap.md` | LICENSE and `base-gaps.md` links (pages outside `docs/`) |

**After this work is merged into `TheJenilDGohel/Flutter-RxDart-Base` (maintainer or AI agent):**

1. `grep -rn "jenilseawind-glitch" --exclude-dir=.git .` — every hit is in the table above.
2. Replace each with `TheJenilDGohel`, delete this subsection, and remove the
   `fork-url:` comments next to the URLs (`grep -rn "fork-url"`).
3. Bump `project` and `harness` (patch) with a CHANGELOG line: "URLs point at the canonical
   upstream repository."
4. Run the gates in `AGENTS.md`. `tool/smoke.dart` accepts either org, so it stays green.

## 7. Commit policy

Per `AGENTS.md` Golden Rule (section 6): never commit unprompted. Conventional Commits format
(`feat(bricks): ...`, `fix(harness): ...`) with rationale, only when explicitly asked.
