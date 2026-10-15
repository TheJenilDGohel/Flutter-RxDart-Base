import type { Register } from 'claude-code'

const git = async ($: any, args: string[]) => {
  try {
    const r = await $.process.run(['git', ...args], { timeoutMs: 15000 })
    return r.exitCode === 0 ? String(r.stdout).trim() : ''
  } catch {
    return ''
  }
}

const snapshot = async ($: any) => {
  const branch = (await git($, ['rev-parse', '--abbrev-ref', 'HEAD'])) || '?'
  const porcelain = await git($, ['status', '--porcelain'])
  const dirty = porcelain ? porcelain.split('\n').filter(Boolean).length : 0
  const ahead = Number((await git($, ['rev-list', '--count', '@{u}..HEAD'])) || 0)
  const hasUpstream = (await git($, ['rev-parse', '--abbrev-ref', '@{u}'])) !== ''
  const trees = (await git($, ['worktree', 'list', '--porcelain']))
    .split('\n')
    .filter((l: string) => l.startsWith('worktree ')).length
  return { branch, dirty, ahead, hasUpstream, trees }
}

const line = (s: Awaited<ReturnType<typeof snapshot>>) => {
  const push = !s.hasUpstream ? 'no upstream' : s.ahead > 0 ? `${s.ahead} unpushed` : 'pushed'
  return `${s.branch} | ${s.dirty ? s.dirty + ' dirty' : 'clean'} | ${push} | ${s.trees} worktree${s.trees === 1 ? '' : 's'}`
}

const readContext = async ($: any) => {
  try {
    const text: string = await $.fs.read('.harness/active-context.md')
    const focusMatch = text.match(/## Current Focus([\s\S]*?)(?=\n## |$)/)
    const currentFocus = focusMatch ? focusMatch[1].trim() : text.slice(0, 1500).trim()
    
    // Extract unchecked markdown tasks: - [ ] task description
    const taskMatches = text.match(/^[ \t]*-[ \t]*\[ \][ \t]*(.+)$/gm) || []
    const pendingTasks = taskMatches.map((t: string) => t.replace(/^[ \t]*-[ \t]*\[ \][ \t]*/, '').trim())

    return {
      currentFocus: currentFocus || '(no focus specified)',
      pendingTasks,
      raw: text.slice(-2000),
    }
  } catch {
    return {
      currentFocus: '(no .harness/active-context.md)',
      pendingTasks: [],
      raw: '',
    }
  }
}

async function refresh($: any) {
  try {
    $.ui.status(line(await snapshot($)))
  } catch {
    $.ui.status(undefined)
  }
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'handoff',
      description: 'Close the session: analyze, commit, push the branch, update active-context, print next-session prompt',
      argumentHint: '[note]',
    })
    await $.command.register({
      name: 'pickup',
      description: 'Open the session: branch state, worktrees, recent commits, current focus, next step',
      argumentHint: '[task]',
    })
    void refresh($)
    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    void refresh($)
    return next(e)
  })

  on('tool.call', { tool: 'Bash' }, async ($, e, next) => {
    const ran = await next(e)
    if (/\bgit\s+(commit|push|checkout|switch|merge|worktree|pull|add)\b/.test(e.command)) void refresh($)
    return ran
  }).catch(($, e, next) => next(e))

  on('command.run', { command: 'pickup' }, async ($, e) => {
    const s = await snapshot($)
    const log = await git($, ['log', '--oneline', '-5'])
    const trees = await git($, ['worktree', 'list'])
    const rawStatus = await git($, ['status', '--short'])
    const statusLines = rawStatus ? rawStatus.split('\n').filter(Boolean) : []
    const status = statusLines.slice(0, 25).join('\n')
    const ctx = await readContext($)
    const explicitTask = e?.args?.trim() || ''

    const report = [
      `State: ${line(s)}`,
      `Recent commits:\n${log || '(none)'}`,
      `Worktrees:\n${trees || '(default)'}`,
      `Uncommitted files (${statusLines.length}):\n${status || '(none)'}`,
      `Current focus (.harness/active-context.md):\n${ctx.currentFocus}`,
      ctx.pendingTasks.length ? `Pending checklist items (- [ ]):\n${ctx.pendingTasks.map((t: string, i: number) => `  ${i + 1}. ${t}`).join('\n')}` : '',
    ].filter(Boolean).join('\n\n')

    const taskDirectives = explicitTask
      ? `The person ran /pickup with an explicit task: "${explicitTask}". Immediately begin working on this requested task.`
      : [
          `The person ran /pickup without arguments. Determine the next task using these priorities:`,
          `1. Active WIP: If uncommitted files exist above (e.g., in features, flows, tests), continue working on that in-progress work first.`,
          `2. Checklist Tasks: If pending checklist items are listed above, pick up the top item: "${ctx.pendingTasks[0] || ctx.currentFocus}".`,
          `3. Genuinely Ambiguous / Multiple Competing Choices:`,
          `   DO NOT STOP SILENTLY OR GIVE A VAGUE 1-LINE DEAD END.`,
          `   Instead, present a clear numbered choice menu:`,
          `   - List the candidate tasks with numbers [1], [2], etc., noting where each comes from (e.g., active uncommitted files, active-context.md, branch name).`,
          `   - Explain what decision or input is needed from the user.`,
          `   - Prompt the user to reply with a number or run \`/pickup <task>\` to begin immediately.`,
        ].join('\n')

    return {
      text: `Pickup: ${line(s)}`,
      context: [
        [
          `The person ran /pickup. Raw state below.`,
          `First reply: give a concise 3-5 line status summary: branch + whether it is pushed, what the last session did, what is uncommitted, and the selected next task. If another worktree is listed, name it and remind not to touch it. Do not re-run git commands already shown.`,
          taskDirectives,
          `Once the task is identified, invoke the matching project skill, follow project rules, and work until done or a concrete blocker is hit. Never edit inside another worktree.`,
          `\n${report}`,
        ].join('\n\n'),
      ],
    }
  })

  on('command.run', { command: 'handoff' }, async ($, e) => {
    const s = await snapshot($)
    const stat = await git($, ['diff', '--stat'])
    const status = (await git($, ['status', '--short'])).split('\n').slice(0, 60).join('\n')
    return {
      text: `Handoff started: ${line(s)}`,
      context: [
        [
          `The person ran /handoff${e.args ? ` with note: "${e.args}"` : ''}. Wrap this session now. This command is their request to commit and push; nothing else is authorized.`,
          `State: ${line(s)}`,
          `git status --short:\n${status || '(clean)'}`,
          `git diff --stat:\n${stat || '(none)'}`,
          `Steps, in order. Stop and report if any step fails.`,
          `1. Run \`fvm dart analyze lib test\` (or \`dart analyze lib test\`). Any error: fix it first, never commit red. Trust its output over any earlier note.`,
          `2. Read git status and git diff --stat. Unexpected deletions or files from another session/worktree: restore or leave them out, never commit them. Stage only this branch's files by path.`,
          `3. Commit with a Conventional Commit (feat/fix/refactor/test/chore + scope). Message in normal prose. End with the attribution lines from the system reminder.`,
          `4. Push the current branch to origin (feature/<name>); never merge directly into protected branches or main.`,
          `5. Only if a feature or milestone finished: update .harness/active-context.md (Current Focus 2-3 lines, Recent Tasks newest first max 5, Key Decisions, Known Issues). Small edits: skip.`,
          `6. Print: branch, commit hash, pushed yes/no, then a ready-to-paste prompt for the next session (branch, spec path, open backend questions, the next task). Then stop and tell the person to /clear. Do not start the next task.`,
        ].join('\n'),
      ],
    }
  })
}

