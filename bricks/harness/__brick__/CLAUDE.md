# {{project_name}} — Claude Code memory

@AGENTS.md

## Claude Code specifics
- Android package `{{android_package_name}}`, iOS bundle id `{{ios_bundle_id}}`.
- Skills (AGENTS.md §4) carry the procedures; path-scoped rules in `.claude/rules/` load when matching files are touched. Neither needs repeating here.
- **One session, Sonnet** (`.claude/settings.json` sets `model`; cross-session inbound is held). Switch to Opus with `/model` only for planning or a hard bug. Subagents only when their output would flood the context, on the cheapest model that works.
- **Tests per change**: `dart run scripts/agent/affected_tests.dart` (changed features only, failures only). Full `verify.dart` before commits that touch shared code and at milestones. Device checks: Maestro flows at milestones, pass/fail only.
- **Context**: `/clear` at task end (`/clear` is free, `/compact` is a large request). Keep CLAUDE.md, AGENTS.md and `.harness/active-context.md` short: they load on every request. Never read `*.g.dart`, `*.freezed.dart`, `build/`, `.dart_tool/`.
- In FVM projects (`.fvm/` or `.fvmrc`), prefix CLI commands with `fvm`.

<!-- harness:project-rules — Everything below this line is yours. `upgrade.dart` keeps it verbatim. -->

---
@.harness/active-context.md
