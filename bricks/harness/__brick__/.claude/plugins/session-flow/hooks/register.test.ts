import { test, expect } from 'claude-code/testing'
import type { SessionStartInput } from 'claude-code'

const start: SessionStartInput = { surface: 'terminal', isInteractive: true, cwd: '/work' }
const ok = (stdout: string) => ({ value: { exitCode: 0, stdout, stderr: '' } })
const settle = () => new Promise(r => setTimeout(r, 50))

const statusAfterStart = async ($: any, on: any, git: Record<string, string>) => {
  const shown: (string | undefined)[] = []
  on('ui.status', (_$: any, e: any) => { shown.push(e.text ?? e); return { value: undefined } })
  on('process.run', async (_$: any, e: any) => {
    const a = e.argv.join(' ')
    const hit = Object.keys(git).find(k => a.includes(k))
    return ok(hit ? git[hit] : '')
  })
  on('session.start', (_$: any, e: any) => ({ cwd: e.cwd }))
  await $.session.start(start)
  await settle()
  return shown.at(-1)
}

test('status line shows branch, dirty count, unpushed commits and worktrees', async ($, on) => {
  const shown = await statusAfterStart($, on, {
    'rev-parse --abbrev-ref HEAD': 'feature/homework',
    'status --porcelain': ' M a.dart\n?? b.dart\n',
    'rev-list': '2',
    '@{u}': 'origin/feature/homework',
    'worktree list --porcelain': 'worktree /a\nworktree /b',
  })
  expect(shown).toBe('feature/homework | 2 dirty | 2 unpushed | 2 worktrees')
})

test('status line without an upstream says so', async ($, on) => {
  const shown = await statusAfterStart($, on, {
    'rev-parse --abbrev-ref HEAD': 'main',
    'worktree list --porcelain': 'worktree /a',
  })
  expect(shown).toBe('main | clean | no upstream | 1 worktree')
})
