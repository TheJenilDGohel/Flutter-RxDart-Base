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
  const dirty = porcelain ? porcelain.split('\n').length : 0
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

const focus = async ($: any) => {
  try {
    const text: string = await $.fs.read('.harness/active-context.md')
    const m = text.match(/## Current Focus([\s\S]*?)\n## /)
    return (m ? m[1] : text.slice(0, 1500)).trim().slice(-1800)
  } catch {
    return '(no .harness/active-context.md)'
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

  on('command.run', { command: 'pickup' }, async $ => {
    const s = await snapshot($)
    const log = await git($, ['log', '--oneline', '-5'])
    const trees = await git($, ['worktree', 'list'])
    const status = (await git($, ['status', '--short'])).split('\n').slice(0, 25).join('\n')
    const f = await focus($)
    const report = [
      `State: ${line(s)}`,
      `Recent commits:\n${log}`,
      `Worktrees:\n${trees}`,
      `Uncommitted:\n${status || '(none)'}`,
      `Current focus (.harness/active-context.md):\n${f}`,
    ].join('\n\n')
    return {
      text: `Pickup: ${line(s)}`,
      context: [
        `The person ran /pickup. Raw state below. First reply in at most 5 lines: branch + whether it is pushed, what the last session did, what is uncommitted, the single next task, anything blocked on backend. If another worktree is listed, name it and say not to touch it. Do not re-run git. Then pick up that next task and start it: invoke the matching project skill, follow the project rules, and work until done. Never edit inside another worktree. Stop instead, and say why in one line naming the cause, when: the next task is unclear or .harness/active-context.md contradicts the commits, the next step is blocked on a backend answer, or the task needs a decision only the person can make. Never stop silently.\n\n${report}`,
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
          `1. Run \`fvm dart analyze lib test\`. Any error: fix it first, never commit red. Trust its output over any earlier note.`,
          `2. Read git status and git diff --stat. Unexpected deletions or files from another session/worktree: restore or leave them out, never commit them. Stage only this branch's files by path.`,
          `3. Commit with a Conventional Commit (feat/fix/refactor/test/chore + scope). Message in normal prose. End with the attribution lines from the system reminder.`,
          `4. Push the current branch to origin (feature/<name>); never merge into wip/storage-layer or main.`,
          `5. Only if a feature or milestone finished: update .harness/active-context.md (Current Focus 2-3 lines, Recent Tasks newest first max 5, Key Decisions, Known Issues). Small edits: skip.`,
          `6. Print: branch, commit hash, pushed yes/no, then a ready-to-paste prompt for the next session (branch, spec path, open backend questions, the next task). Then stop and tell the person to /clear. Do not start the next task.`,
        ].join('\n'),
      ],
    }
  })
}
