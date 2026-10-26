# Authoring a project skill

Create one when a multi-step workflow unique to this project has come up at least twice (for example "add a payment method", "add a report export", "onboard a new tenant") and an overlay on an existing skill would be the wrong home. Skills follow the open [Agent Skills](https://agentskills.io) format, so Claude Code, Codex, Cursor, Gemini CLI and others can all use them.

## Layout
Two files, because Claude Code discovers `.claude/skills/` and the other agents discover `.agents/skills/`:

```
.agents/skills/<name>/SKILL.md     # the skill (plus flat reference files if needed)
.claude/skills/<name>/SKILL.md     # entry point: same frontmatter, body points at the file above
```

The entry point, copied from any shipped one:

```markdown
---
name: <name>
description: <identical to the .agents copy>
---

Read and follow `.agents/skills/<name>/SKILL.md`.
```

`upgrade.dart` only replaces the skills the harness ships, which are listed under `managed_skills` in `.harness/version.json`. Yours are never touched, as long as you don't reuse one of those names.

## Frontmatter
- `name`: lowercase letters, digits and single hyphens, at most 64 characters, and identical to the folder name.
- `description`: at most 1024 characters. It's the only part an agent sees before deciding to load the skill, so state **what it does and when to use it**, with the words users actually type ("payout", "refund", "invoice PDF"). Name this stack (Flutter, RxDart, the base) so it doesn't fire on unrelated work.

## Body (aim for under 150 lines)
1. One paragraph: the outcome, and the one idea that makes it go right.
2. **0. Load what this project learned**: read `.harness/skills/<name>.md` and run `learn.dart list <name>`, the same as the shipped skills.
3. Numbered steps with exact commands and file paths from this repository. Reference golden rules by number instead of restating them.
4. **Done means**: checkable conditions, ending with `dart run scripts/agent/verify.dart` passing.
5. **Close out**: `AGENTS.md` §6.

Move long examples into a flat reference file next to `SKILL.md` and link it from the step that needs it. Agents load references only on demand.

## After creating it
- Add one line to `AGENTS.md` §7 (below the marker) naming the skill and when to use it. Agents that don't support skills still read that.
- `learn.dart` accepts the new name as a scope right away. Re-scope related `general` lessons to it.
- Dry-run it: could a fresh agent, given only this file and the repository, finish the task? Wherever it would have to guess, add the missing step.
- If it would help every project on the base, propose it upstream (`.agents/skills/evolve-harness/SKILL.md` step 5).
