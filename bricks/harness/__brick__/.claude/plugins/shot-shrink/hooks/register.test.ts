import { test, expect } from 'claude-code/testing'
import { smallPath, ATTEMPTS } from './register'

const ok = (stdout: string) => ({ value: { exitCode: 0, stdout, stderr: '' } })
const st = (m: number) => ({ value: { kind: 'file', size: 1, mtimeMs: m, isLink: false } })

test('smallPath puts the copy in .small beside the shot', () => {
  expect(smallPath('C:/a b/shots/x.png')).toBe('C:/a b/shots/.small/x.png')
})

test('a big screenshot is read from the 800px copy', async ($, on) => {
  let seen = ''
  on('fs.stat', async () => st(1) as any)
  on('fs.exists', async () => ({ value: false }) as any)
  on('process.run', async () => ok('small') as any)
  on('tool.call', async (_$, e: any) => { seen = e.file_path; return { result: 'ok' } as any })
  await $.tool.call({ tool: 'Read', file_path: 'shots/a.png' } as any)
  expect(seen).toBe('shots/.small/a.png')
})

test('a small image and a non-image are read as is', async ($, on) => {
  let seen = ''
  on('fs.stat', async () => st(1) as any)
  on('fs.exists', async () => ({ value: false }) as any)
  on('process.run', async () => ok('same') as any)
  on('tool.call', async (_$, e: any) => { seen = e.file_path; return { result: 'ok' } as any })
  await $.tool.call({ tool: 'Read', file_path: 'shots/b.png' } as any)
  expect(seen).toBe('shots/b.png')
  await $.tool.call({ tool: 'Read', file_path: 'lib/a.dart' } as any)
  expect(seen).toBe('lib/a.dart')
})

test('falls back to the POSIX resizer when PowerShell is missing', async ($, on) => {
  let seen = ''
  const tried: string[] = []
  on('fs.stat', async () => st(1) as any)
  on('fs.exists', async () => ({ value: false }) as any)
  on('process.run', async (_$, e: any) => {
    tried.push(e.argv[0])
    if (e.argv[0] === 'powershell') throw new Error('ENOENT')
    return ok('small') as any
  })
  on('tool.call', async (_$, e: any) => { seen = e.file_path; return { result: 'ok' } as any })
  await $.tool.call({ tool: 'Read', file_path: 'shots/c.png' } as any)
  expect(tried).toEqual(['powershell', 'sh'])
  expect(seen).toBe('shots/.small/c.png')
})

test('the POSIX resizer covers macOS and Linux', () => {
  const posix = ATTEMPTS[1].join(' ')
  expect(posix).toContain('sips -Z 800')
  expect(posix).toContain('-resize 800x800')
})
