import { test, expect } from 'claude-code/testing'

const ok = (stdout: string) => ({ value: { exitCode: 0, stdout, stderr: '' } })

const BAD_WIDGET = `import 'package:flutter_screenutil/flutter_screenutil.dart';
class Page extends StatelessWidget {
  Widget build(c) => Text(error.toString());
}
class _Card extends StatelessWidget {
  Widget build(c) => SizedBox(width: 100.w);
}
`

test('audit flags repo parsing, setState, private ScreenUtil, withOpacity', async ($, on) => {
  on('process.run', async (_$, e) => {
    const a = e.argv.join(' ')
    if (a.includes('ls-files')) return ok('lib/features/auth/x/repo/x_repo.dart\nlib/features/auth/x/x_view.dart')
    return ok('')
  })
  on('fs.read', async (_$, e) => ({
    value: e.path.endsWith('x_repo.dart')
      ? 'Future<User> get() async => User.fromJson(await h.get());'
      : `${BAD_WIDGET}
void f(){ setState(() {}); c.withOpacity(0.5); }`,
  }))

  const out = await $.command.run({ command: 'audit', args: 'lib/features/auth/x' })
  const ctx = out.context?.[0] ?? ''

  expect(ctx).toContain('R1 repo parses JSON')
  expect(ctx).toContain('R2 shows e.toString()')
  expect(ctx).toContain('R3 setState')
  expect(ctx).toContain('R13 ScreenUtil unit in private widget _Card')
  expect(ctx).toContain('R14 withOpacity')
})

test('base code raises no false positives', async ($, on) => {
  on('process.run', async (_$, e) => {
    const a = e.argv.join(' ')
    if (a.includes('ls-files')) {
      return ok('lib/redux/app_store.dart\nlib/networking/x.dart\nlib/features/profile/profile_page.dart')
    }
    return ok('')
  })
  on('fs.read', async (_$, e) => ({
    value: e.path.endsWith('profile_page.dart')
      ? 'void out() { store.dispatch(const LogoutAction()); }'
      : e.path.endsWith('x.dart')
        ? "import 'package:rxdart/rxdart.dart';"
        : "import 'package:shared_preferences/shared_preferences.dart';\nfinal p = SharedPreferences.getInstance();",
  }))

  const out = await $.command.run({ command: 'audit', args: 'lib/' })

  expect(out.text).toContain('0 hits')
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

test('stop gate surfaces warning-level golden lints from the analyzer', async ($, on) => {
  const ran: string[] = []
  on('process.run', async (_$, e) => {
    const a = e.argv.join(' ')
    if (a.includes('diff --name-only')) return ok('lib/features/auth/x/bloc/x_bloc.dart')
    if (a.includes('analyze')) {
      ran.push(a)
      return ok(
        '  warning - lib/features/auth/x/bloc/x_bloc.dart:9:3 - Close _data in dispose(). - no_unclosed_subject\n' +
          '  info - lib/features/auth/x/bloc/x_bloc.dart:2:1 - Unused import. - unused_import',
      )
    }
    return ok('')
  })
  on('fs.read', async () => ({ value: 'final class XBloc {}' }))
  on('fs.exists', async () => ({ value: false }) as any)

  on('classic.Stop', async () => ({}))
  const out = await $.classic.Stop({ stop_hook_active: false })

  expect(ran[0]).toContain('dart analyze')
  expect(out.block).toContain('no_unclosed_subject')
  expect(out.block).not.toContain('unused_import')
})

test('stop gate uses the warm dart MCP analyzer, errors in changed files only', async ($, on) => {
  const cli: string[] = []
  const mcp: string[] = []
  on('process.run', async (_$, e) => {
    const a = e.argv.join(' ')
    if (a.includes('diff --name-only')) return ok('lib/features/a/a_page.dart')
    if (a.includes('analyze')) cli.push(a)
    return ok('')
  })
  on('fs.read', async () => ({ value: 'void f(){}' }))
  on('fs.exists', async () => ({ value: false }) as any)
  on('session.cwd', async () => ({ value: 'C:/work/my app' }) as any)
  on('mcp.call', async (_$, e: any) => {
    mcp.push(`${e.server} ${e.tool}`)
    if (e.tool !== 'analyze_files') return { value: { content: [], isError: false } } as any
    expect(e.args.roots[0].root).toBe('file:///C:/work/my%20app')
    return {
      value: {
        isError: false,
        content: [
          {
            type: 'text',
            text:
              'error • lib/features/a/a_page.dart:3:9 • Undefined name x. • undefined_identifier\n' +
              'error • lib/features/b/b_page.dart:1:1 • Not mine. • undefined_identifier\n' +
              'info • lib/features/a/a_page.dart:4:1 • Prefer const. • prefer_const_constructors',
          },
        ],
      },
    } as any
  })

  on('classic.Stop', async () => ({}))
  const out = await $.classic.Stop({ stop_hook_active: false })

  expect(mcp).toContain('dart analyze_files')
  expect(cli).toEqual([])
  expect(out.block).toContain('undefined_identifier')
  expect(out.block).toContain('a_page.dart:3:9')
  expect(out.block).not.toContain('b_page.dart')
  expect(out.block).not.toContain('prefer_const_constructors')
})

test('stop gate falls back to the CLI when the dart MCP server is unavailable', async ($, on) => {
  const cli: string[] = []
  on('process.run', async (_$, e) => {
    const a = e.argv.join(' ')
    if (a.includes('diff --name-only')) return ok('lib/features/c/c_page.dart')
    if (a.includes('analyze')) {
      cli.push(a)
      return ok('  error - lib/features/c/c_page.dart:2:1 - Missing semicolon. - expected_token')
    }
    return ok('')
  })
  on('fs.read', async () => ({ value: 'void g(){}' }))
  on('fs.exists', async () => ({ value: false }) as any)
  on('session.cwd', async () => ({ value: '/home/me/app' }) as any)
  on('mcp.call', async () => {
    throw new Error('server dart is not connected')
  })

  on('classic.Stop', async () => ({}))
  const out = await $.classic.Stop({ stop_hook_active: false })

  expect(cli.length).toBe(1)
  expect(out.block).toContain('expected_token')
})

test('project rules from .harness/guard-rules.json: Stop gate and /audit', async ($, on) => {
  const rules = JSON.stringify({
    rules: [
      { pattern: String.raw`\bDateFormat\s*\(`, message: 'DateFormat outside AppDateFormat', exclude: String.raw`date_format_utils\.dart$` },
      { pattern: String.raw`Future\.delayed`, message: 'Future.delayed in a feature', paths: '^lib/features/' },
      { pattern: '(', message: 'bad regex is skipped' },
      { pattern: 'x' },
    ],
    audit: 'ARB keys in en, hi and gu.',
  })
  on('process.run', async (_$, e) => {
    const a = e.argv.join(' ')
    if (a.includes('diff --name-only')) {
      return ok('lib/features/a/a_page.dart\nlib/utils/date_format_utils.dart\nlib/core/clock.dart')
    }
    if (a.includes('ls-files')) return ok('lib/features/a/a_page.dart')
    return ok('')
  })
  on('fs.read', async (_$, e) => ({
    value: e.path.endsWith('guard-rules.json')
      ? rules
      : 'final f = DateFormat("d");\nawait Future.delayed(d);',
  }))
  on('fs.exists', async () => ({ value: false }) as any)

  on('classic.Stop', async () => ({}))
  const out = await $.classic.Stop({ stop_hook_active: false })
  expect(out.block).toContain('lib/features/a/a_page.dart:1 P DateFormat outside AppDateFormat')
  expect(out.block).toContain('lib/features/a/a_page.dart:2 P Future.delayed in a feature')
  expect(out.block).toContain('lib/core/clock.dart:1 P DateFormat')
  expect(out.block).not.toContain('date_format_utils.dart:1')
  expect(out.block).not.toContain('lib/core/clock.dart:2')

  const audit = await $.command.run({ command: 'audit', args: 'lib/features/a' })
  expect(audit.context?.[0] ?? '').toContain('Project checks: ARB keys in en, hi and gu.')
})

test('R13 skips adaptive_units, which rebuilds private widgets', async ($, on) => {
  on('process.run', async (_$, e) => {
    const a = e.argv.join(' ')
    if (a.includes('ls-files')) return ok('lib/features/a/a_view.dart')
    return ok('')
  })
  on('fs.read', async () => ({
    value: `import 'package:adaptive_units/adaptive_units.dart';
class _Card extends StatelessWidget {
  Widget build(c) => SizedBox(width: 100.w);
}`,
  }))

  const out = await $.command.run({ command: 'audit', args: 'lib/features/a' })

  expect(out.text).toContain('0 hits')
})
