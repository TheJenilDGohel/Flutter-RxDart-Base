# Maintainer Rules

Rules for changing this workspace: `bricks/project`, `bricks/bloc`, `bricks/harness`,
`packages/redux_rxdart_lints`.

## 1. Every behavior change to a Brick bumps its version + CHANGELOG

If you touch `hooks/pre_gen.dart`, `hooks/post_gen.dart`, or any file under `__brick__/` in a way
that changes generated output or hook behavior:

- Bump `version:` in that brick's `brick.yaml` (semver — patch for fixes, minor for new
  capabilities, major for breaking template/var changes).
- Add an entry to that brick's `CHANGELOG.md` (create one if it doesn't exist yet — `harness` has
  one, `project`/`bloc` don't yet; add when they get their first post-1.0.0 change).

Cosmetic-only changes (formatting, comments) don't require a bump.

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

- `dart format --set-exit-if-changed .` and `dart analyze` clean on every touched Dart file —
  including brick hook files (`bricks/*/hooks/`) and `packages/redux_rxdart_lints`, each of which
  has its own `pubspec.yaml`/`.dart_tool` and must be checked from its own directory.
- If you change `wire_route.dart` or a hook's file-injection logic, dry-run it against the real
  templates in a scratch copy before trusting the regex — don't assume it's correct from reading
  it. (Silent no-ops in generated/injected files are the failure mode to watch for.)

## 6. URLs point at one canonical org

All git-dependency URLs, `mason add -g --git-url` examples, and README links use
`https://github.com/TheJenilDGohel/Flutter-RxDart-Base.git`. If the working remote (`git remote -v`)
ever differs from this, that's a signal to ask before writing new URLs, not to guess.

## 7. Commit policy

Per `AGENTS.md` Golden Rule (section 6): never commit unprompted. Conventional Commits format
(`feat(bricks): ...`, `fix(harness): ...`) with rationale, only when explicitly asked.
