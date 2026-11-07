import { test, expect } from 'claude-code/testing'

const stat = (size: number) => ({ value: { kind: 'file', size, mtimeMs: 1, isLink: false } })

test('refuses generated and build files', async ($, on) => {
  on('tool.call', async () => ({ result: 'ok' }) as any)
  const r: any = await $.tool.call({ tool: 'Read', file_path: 'lib/a.g.dart' } as any)
  expect(r.deny).toContain('read-guard')
})

test('refuses a big file without offset, allows it with limit', async ($, on) => {
  on('fs.stat', async () => stat(90000) as any)
  on('tool.call', async () => ({ result: 'ok' }) as any)
  const big: any = await $.tool.call({ tool: 'Read', file_path: 'DESIGN.md' } as any)
  expect(big.deny).toContain('Grep or offset/limit')
  const part: any = await $.tool.call({ tool: 'Read', file_path: 'DESIGN.md', limit: 50 } as any)
  expect(part.deny).toBe(undefined)
})

test('lets a small file through', async ($, on) => {
  on('fs.stat', async () => stat(2000) as any)
  on('tool.call', async () => ({ result: 'ok' }) as any)
  const r: any = await $.tool.call({ tool: 'Read', file_path: 'lib/a.dart' } as any)
  expect(r.deny).toBe(undefined)
})
