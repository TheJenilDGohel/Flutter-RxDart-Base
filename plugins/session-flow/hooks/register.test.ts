import { test, expect } from 'claude-code/testing'

const ok = (stdout: string) => ({ value: { exitCode: 0, stdout, stderr: '' } })

test('pickup reports branch state and hands the model the focus', async ($, on) => {
  on('process.run', async (_$, e) => {
    const a = e.argv.join(' ')
    if (a.includes('rev-parse --abbrev-ref HEAD')) return ok('feature/homework')
    if (a.includes('status --porcelain')) return ok(' M a.dart\n?? b.dart')
    if (a.includes('status --short')) return ok(' M a.dart\n?? b.dart')
    if (a.includes('rev-list')) return ok('2')
    if (a.includes('@{u}')) return ok('origin/feature/homework')
    if (a.includes('worktree list --porcelain')) return ok('worktree /a\nworktree /b')
    if (a.includes('worktree list')) return ok('/a  abc [feature/homework]')
    if (a.includes('log')) return ok('5d84f85 merge')
    return ok('')
  })
  on('fs.read', async () => ({ value: '# Active Context\n\n## Current Focus\nBuild homework.\n\n## Recent Tasks\n' }))

  const out = await $.command.run({ command: 'pickup', args: '' })

  expect(out.text).toContain('feature/homework')
  expect(out.text).toContain('2 dirty')
  expect(out.text).toContain('2 unpushed')
  expect(out.context?.[0]).toContain('Build homework.')
})

test('handoff tells the model to analyze before committing and to stop after', async ($, on) => {
  on('process.run', async () => ok(''))
  const out = await $.command.run({ command: 'handoff', args: 'wrap up' })

  expect(out.context?.[0]).toContain('fvm dart analyze lib test')
  expect(out.context?.[0]).toContain('wrap up')
  expect(out.context?.[0]).toContain('Do not start the next task')
})
