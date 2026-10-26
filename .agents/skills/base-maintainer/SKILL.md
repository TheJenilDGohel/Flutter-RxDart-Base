---
name: base-maintainer
description: Maintains the Flutter-RxDart-Base Mason workspace itself - changing the project, bloc or harness bricks, their hooks and templates, the harness skills and scripts, the redux_rxdart_lints package, docs and CI - with the version bumps, CHANGELOGs, mirrored docs, lint fixtures and gates each change needs, plus taking in lessons that apps propose upstream. Use for any edit in this repository (not in an app generated from it), including "add a lint rule", "update the bloc template", "improve a harness skill", "release the harness" or "apply these upstream lessons".
---

# Maintain the base

This repository is the source every app on the architecture is generated from, and the harness skills teach agents in those apps. A wrong line here becomes confidently wrong code in every app. Changes are small and verified, and they ship with their version bump, docs and tests.

## 0. Load the rules
Root `AGENTS.md` (gates and maintainer rules) and `docs/contributing.md` (the details) are the contract. Also read `## Learned` at the bottom of this file.

## 1. Map the change to everything it touches
| You change... | Also update |
|---|---|
| A template or hook under `bricks/<brick>/` (generated output or behavior) | `version:` in `brick.yaml` (semver), a `## <version>` entry in its `CHANGELOG.md`, `bricks/<brick>/README.md` **and** its mirror `docs/bricks/<brick>.md`, the version in the brick tables of `README.md` and `docs/index.md` |
| The harness version | Also `bricks/harness/__brick__/.harness/version.json` (`tool/version_gate.dart` checks they match) |
| A golden rule in `bricks/harness/__brick__/AGENTS.md` that a tool could enforce | A rule in `packages/redux_rxdart_lints/lib/src/rules/`, registered in `lib/redux_rxdart_lints.dart`, with `expect_lint` positives and clean negatives in `packages/redux_rxdart_lints/example/`, plus the package version and CHANGELOG |
| Anything the harness docs name (a class, a folder, an exception) | Every harness doc that names it. `dart run tool/harness_check.dart` lists them. |
| A harness skill | See step 2 |
| `wire_route.dart` or hook file injection | Dry-run against real templates in a scratch app; silent no-ops are the failure mode |
| A repository URL | `docs/contributing.md` §6: fork URLs stay until the upstream merge |
| SDK floors | The lowest versions dependencies need, never your local toolchain (`docs/contributing.md` §1) |

## 2. Harness skills
- They live in `bricks/harness/__brick__/.agents/skills/<name>/`. The entry point `.claude/skills/<name>/SKILL.md` copies `name` and `description` verbatim.
- Describe the generated code as it is: read the template before quoting a signature. Cite golden rules by number.
- Code blocks must compile and behave. `tool/smoke.dart` pastes every block of `manage-state/bloc-recipes.md` verbatim into its generated app (markers in `tool/recipe_fixture/`, behavior tests in `tool/recipe_fixture/test/recipes_test.dart`). Adding, removing or reordering a block means updating those markers. Snippets in other skill files: paste them into a generated app by hand, and run `flutter analyze --fatal-infos` plus a test.
- New, renamed or removed skill → update `managed_skills` in `.harness/version.json` (sorted). `upgrade.dart` replaces exactly those skills in apps and removes ones no longer listed. Lessons scoped to a removed skill show up as orphans in each app's `learn.dart review`, so name the replacement in the CHANGELOG.
- Mason renders every brick file as a mustache template, so a shipped script or skill must not contain a `{{...}}` tag (it would be rewritten in apps; `harness_check` fails on it). Build such strings without a literal double brace.
- Renaming or removing a file in `scripts/agent/` or a shipped skill: add its old path to `_retiredFiles` in `upgrade.dart`. The upgrade deletes only files listed there or shipped by the brick, and keeps everything else as the project's own.
- Every task skill keeps the same frame: step 0 loads `.harness/skills/<skill>.md` plus `learn.dart list <skill>`, and the end is the `AGENTS.md` §6 close-out. That frame is how apps learn.
- Never write to project-owned paths from the brick: `.harness/` memory and anything below the `harness:project-rules` marker.

## 3. Lessons proposed by apps (upstream intake)
Apps send output from `dart run scripts/agent/learn.dart upstream`: one line per lesson, with its skill scope and hit count.
1. **Verify** each against the current bricks. Is the skill really wrong or missing a step, or was the app off-architecture? Reproduce it in a generated app when it's about code.
2. **Fix it at the narrowest durable place**: a sentence or step in the skill, a recipe, a template fix, or, if it's mechanical, a lint rule (which beats prose because agents can't forget it).
3. **Ship** it as a normal harness change (step 1), with a CHANGELOG line naming the lesson ("from app lessons: ..."). Apps get it through `upgrade.dart` and can then delete their local overlay entry.
4. A lesson several apps report as a project skill is a candidate for a new shipped skill.

## 4. Gates (all must pass)
```bash
dart run tool/docs_check.dart
dart run tool/harness_check.dart
dart run tool/test_harness_learn.dart
dart run tool/test_harness_upgrade.dart      # needs mason get
dart run tool/version_gate.dart origin/main
dart format --set-exit-if-changed tool bricks/project/hooks bricks/bloc/hooks
dart analyze --fatal-infos tool bricks/project/hooks bricks/bloc/hooks
dart analyze --fatal-infos packages/redux_rxdart_lints
(cd packages/redux_rxdart_lints && dart run tool/check_fixture.dart)
dart run tool/smoke.dart                     # full generation, ~5 min
```
Harness scripts (`scripts/agent/*.dart`) are not in the workspace analysis. Check them inside a generated app, which `tool/smoke.dart` does.

## 5. Commit
Only when asked, using Conventional Commits (`feat(harness): ...`, `fix(bloc): ...`, `docs: ...`) with the reason in the body.

## Learned
<!-- One line per lesson about maintaining this repository, newest last, with proof
     (commit:hash or file:path). Promote a line into the steps above once it recurs. -->
- Brick READMEs have a mirror in `docs/bricks/`; links differ (relative vs GitHub URLs), so edit both by hand (file:docs/bricks/harness.md).
- flutter_dotenv 6 loads test env with `dotenv.loadFromString(envString: ...)`; older `testLoad` snippets are wrong (file:bricks/harness/__brick__/.agents/skills/write-tests/SKILL.md).
