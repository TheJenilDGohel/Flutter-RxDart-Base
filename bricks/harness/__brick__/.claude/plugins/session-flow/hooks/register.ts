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

async function refresh($: any) {
  try {
    $.ui.status(line(await snapshot($)))
  } catch {
    $.ui.status(undefined)
  }
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
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
}
