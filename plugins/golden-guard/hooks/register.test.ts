import { test, expect } from 'claude-code/testing'

const ok = (stdout: string) => ({ value: { exitCode: 0, stdout, stderr: '' } })

const BAD_WIDGET = `
class Page extends StatelessWidget {
  Widget build(c) => Text(error.toString());
}
class _Card extends StatelessWidget {
  Widget build(c) => SizedBox(width: 100.w);
}
`

test('audit flags repo parsing, setState, private ScreenUtil, DateFormat', async ($, on) => {
  on('process.run', async (_$, e) => {
    const a = e.argv.join(' ')
    if (a.includes('ls-files')) return ok('lib/features/auth/x/repo/x_repo.dart\nlib/features/auth/x/x_view.dart')
    return ok('')
  })
  on('fs.read', async (_$, e) => ({
    value: e.path.endsWith('x_repo.dart')
      ? 'Future<User> get() async => User.fromJson(await h.get());'
      : `${BAD_WIDGET}
void f(){ setState(() {}); DateFormat("d"); }`,
  }))

  const out = await $.command.run({ command: 'audit', args: 'lib/features/auth/x' })
  const ctx = out.context?.[0] ?? ''

  expect(ctx).toContain('R1 repo parses JSON')
  expect(ctx).toContain('R2 shows e.toString()')
  expect(ctx).toContain('R3 setState')
  expect(ctx).toContain('R13 ScreenUtil unit in private widget _Card')
  expect(ctx).toContain('S DateFormat outside AppDateFormat')
})

test('stop gate blocks on a golden-rule hit', async ($, on) => {
  on('process.run', async (_$, e) => {
    const a = e.argv.join(' ')
    if (a.includes('diff --name-only')) return ok('lib/features/auth/x/x_view.dart')
    return ok('')
  })
  on('fs.read', async () => ({ value: 'void f(){ setState(() {}); }' }))

  on('classic.Stop', async () => ({}))
  const out = await $.classic.Stop({ stop_hook_active: false })

  expect(out.block).toContain('R3 setState')
})

test('stop gate lets a clean diff through', async ($, on) => {
  on('process.run', async (_$, e) => {
    const a = e.argv.join(' ')
    if (a.includes('diff --name-only')) return ok('lib/features/auth/x/x_view.dart')
    return ok('')
  })
  on('fs.read', async () => ({ value: 'void f(){}' }))

  on('classic.Stop', async () => ({}))
  const out = await $.classic.Stop({ stop_hook_active: false })

  expect(out.block).toBeUndefined()
})
