---
name: evolve-harness
description: The one learning loop for this Flutter RxDart project - lesson, seen twice, rule line or lint, delete the lesson. Use when the user corrects you, says "remember this", when you hit a backend quirk or repeated mistake, or when lessons.md needs review.
---

# Evolve the harness

One loop, no archive: **lesson → seen twice → rule line or lint → delete the lesson.**

Project knowledge never goes in shipped files (`scripts/agent/`, the template part of `AGENTS.md`/`CLAUDE.md`, shipped skills): `upgrade.dart` replaces them. It goes in `.harness/`, `.claude/rules/`, and `AGENTS.md` below the `harness:project-rules` marker.

## Steps
1. **Start of a task**: `dart run scripts/agent/learn.dart list <skill>`.
2. **Something went wrong or the user corrected you**: if a lesson matches, `learn.dart hit L<id> --proof <ref>`; otherwise `learn.dart add <skill|general> "<trigger and fix, one line>" --proof <ref>`. Never record secrets or guesses.
3. **Seen twice** (`learn.dart review` lists them): turn it into the cheapest enforcement that works:
   - mechanical and checkable → a lint in `packages/redux_rxdart_lints` (propose with `promote L<id> upstream`);
   - layer or API fact → one line in `.claude/rules/<domain>.md` (≤ 2k chars, with `paths:`; mirror in `.cursor/rules/`);
   - team-wide → one line in `AGENTS.md` §7.
4. **Delete the lesson**: `learn.dart promote L<id> <file>` (the file must already carry the rule). Git keeps the history.
5. **Prune**: `learn.dart prune` deletes lessons seen once and untouched for 90 days; `retire L<id>` deletes wrong ones.
6. A repeat of a promoted lesson is a new lesson: strengthen the rule or add the lint, do not add prose.

## Where things go
| Fact | Home |
|---|---|
| Personal habits, editor preferences | Claude Auto-Memory (outside the repo) |
| Layer or API quirk | `.claude/rules/<domain>.md` |
| Team convention | `AGENTS.md` §7 |
| Per-skill project steps | `.harness/skills/<skill>.md` (the skill's overlay; it wins over the skill) |
| Anything checkable by a script | a lint or a test, not prose |

## Size gate
`budget.dart` (limits in `AGENTS.md` §6): fix a failure by moving or deleting, never by raising the limits.
