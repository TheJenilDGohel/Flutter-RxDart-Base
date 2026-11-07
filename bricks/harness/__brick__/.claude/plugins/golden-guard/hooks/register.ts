import type { Register } from 'claude-code'

type Hit = { file: string; line: number; rule: string }

const git = async ($: any, args: string[]) => {
  try {
    const r = await $.process.run(['git', ...args], { timeoutMs: 20000 })
    return r.exitCode === 0 ? String(r.stdout).trim() : ''
  } catch {
    return ''
  }
}

const lines = (s: string) => (s ? s.split('\n').map(x => x.trim()).filter(Boolean) : [])

const isDart = (f: string) => /^(lib|test)\/.*\.dart$/.test(f) && !/\.(g|freezed)\.dart$/.test(f)

// Same allow-list as redux_rxdart_lints no_rxdart_in_ui.
const rxdartAllowed = (file: string): boolean => {
  const seg = file.replace(/^lib\//, '').split('/')
  if (seg[seg.length - 1].endsWith('_bloc.dart') || seg.includes('bloc')) return true
  if (['redux', 'networking', 'services'].includes(seg[0])) return true
  return seg[0] === 'utils' && seg[1] !== 'widgets'
}

// The golden-rule lints. Three are warnings, so keeping analyzer errors alone
// would let them through.
const GOLDEN_LINTS =
  /\b(repo_transport_only|no_exception_tostring|no_setstate_in_widget|no_rxdart_in_ui|no_fetch_without_token|no_screenutil_in_private_widget|no_with_opacity|no_unclosed_subject)\b/

// A project's own regex rule from `.harness/guard-rules.json`. `upgrade.dart`
// never touches that file, so app conventions live there, not in this mod.
type ProjectRule = { pattern: RegExp; message: string; paths?: RegExp; exclude?: RegExp }

export const GUARD_RULES = '.harness/guard-rules.json'

// Invalid entries (no pattern or message, bad regex) are skipped, never fatal.
export const parseProjectRules = (json: string): { rules: ProjectRule[]; audit: string } => {
  let data: any
  try {
    data = JSON.parse(json)
  } catch {
    return { rules: [], audit: '' }
  }
  const re = (s: unknown) => (typeof s === 'string' && s ? new RegExp(s) : undefined)
  const rules: ProjectRule[] = []
  for (const r of Array.isArray(data?.rules) ? data.rules : []) {
    try {
      const pattern = re(r?.pattern)
      if (!pattern || typeof r?.message !== 'string' || !r.message) continue
      rules.push({ pattern, message: r.message, paths: re(r.paths), exclude: re(r.exclude) })
    } catch {
      // bad regex: skip this rule
    }
  }
  return { rules, audit: typeof data?.audit === 'string' ? data.audit.trim() : '' }
}

async function projectRules($: any) {
  try {
    return parseProjectRules(String(await $.fs.read(GUARD_RULES)))
  } catch {
    return { rules: [] as ProjectRule[], audit: '' }
  }
}

// Pure text scan of one Dart file against the AGENTS.md golden rules. It mirrors
// the redux_rxdart_lints scopes, so it still guards SDKs where the analyzer
// plugin does not run (Dart < 3.13). Only rules that AGENTS.md or a shipped
// skill states belong here: anything else is a false positive in every app.
// [extra] are the project's rules (`P` hits).
const scan = (file: string, text: string, extra: ProjectRule[] = []): Hit[] => {
  const hits: Hit[] = []
  const rows = text.split('\n')
  const isLib = file.startsWith('lib/')
  const isBloc = /_bloc\.dart$/.test(file)
  const isRepo = /_repo\.dart$|\/repo\//.test(file)
  const isFeature = file.startsWith('lib/features/')
  const add = (i: number, rule: string) => hits.push({ file, line: i + 1, rule })

  if (!isLib) return hits

  rows.forEach((row, i) => {
    if (/^\s*\/\//.test(row)) return
    if (isRepo && /\.(fromJson|fromMap)\b|\bfromJson\b\s*\)/.test(row)) add(i, 'R1 repo parses JSON (transport only)')
    if (isFeature && !isBloc && /Text\(\s*(e|err|error|exception)\.toString\(\)/.test(row)) add(i, 'R2 shows e.toString() (use userFacingMessage)')
    if (isFeature && !isBloc && /\bsetState\s*\(/.test(row) && !/\b(void|Future<[^>]*>)\s+setState/.test(row)) {
      add(i, 'R3 setState in feature widget')
    }
    if (/^\s*(import|export)\s+'package:rxdart\//.test(row) && !rxdartAllowed(file)) {
      add(i, 'R4 rxdart import outside a BLoC')
    }
    if (/\.withOpacity\s*\(/.test(row)) add(i, 'R14 withOpacity (use withValues(alpha:) or a token)')
    if (isFeature && /\bColor\(0x/.test(row)) add(i, 'S inline Color(0x...) (use a ResColors token)')
    for (const r of extra) {
      if (r.paths && !r.paths.test(file)) continue
      if (r.exclude && r.exclude.test(file)) continue
      if (r.pattern.test(row)) add(i, `P ${r.message}`)
    }
  })

  // R13: ScreenUtil units inside a private widget class.
  const parts = text.split(/\n(?=class\s)/)
  let offset = 0
  for (const part of parts) {
    const m = part.match(/^class\s+(_\w+)\s+extends\s+(StatelessWidget|StatefulWidget|State<\s*(\w+))/)
    // A State of a public widget rebuilds with it on resize: only State<_Private> counts.
    if (m && !(m[3] && !m[3].startsWith('_'))) {
      const hit = part.match(/\b\d+(\.\d+)?\.(w|h|r|sp)\b/)
      if (hit && hit.index !== undefined) {
        const ln = text.slice(0, offset + hit.index).split('\n').length
        hits.push({ file, line: ln, rule: `R13 ScreenUtil unit in private widget ${m[1]}` })
      }
    }
    offset += part.length + 1
  }
  return hits
}

const show = (hits: Hit[], max = 30) =>
  hits.slice(0, max).map(h => `${h.file}:${h.line} ${h.rule}`).join('\n') +
  (hits.length > max ? `\n...and ${hits.length - max} more` : '')

async function scanFiles($: any, files: string[]): Promise<Hit[]> {
  const all: Hit[] = []
  const { rules } = await projectRules($)
  for (const f of files) {
    try {
      const text: string = await $.fs.read(f)
      all.push(...scan(f, text, rules))
    } catch {
      // deleted or unreadable file: skip
    }
  }
  return all
}

async function changedDart($: any): Promise<string[]> {
  const tracked = lines(await git($, ['diff', '--name-only', 'HEAD']))
  const fresh = lines(await git($, ['ls-files', '--others', '--exclude-standard']))
  return [...new Set([...tracked, ...fresh])].filter(isDart)
}

// Mods cannot read the OS (`process` is not defined in a hooks module): run
// the command directly, and through cmd when that fails, for Windows `.bat`
// launchers such as flutter\bin\dart.bat or fvm.bat.
async function runTool($: any, argv: string[]) {
  try {
    return await $.process.run(argv, { timeoutMs: 120000 })
  } catch {
    return await $.process.run(['cmd', '/c', ...argv], { timeoutMs: 120000 })
  }
}

// `C:\a b\app` or `/home/a/app` -> `file:///C:/a%20b/app` / `file:///home/a/app`.
export const fileUri = (dir: string): string =>
  'file:///' + encodeURI(dir.split(String.fromCharCode(92)).join('/').replace(/^\/+/, ''))

// Warm path: the `dart` MCP server's analyzer answers in milliseconds once warm
// (a CLI `dart analyze` measured ~23 s: ~8 s analyzer start + ~15 s lint
// plugin start). It reports compile errors and SDK lints but not analyzer
// plugins, so the golden rules stay with the regex scan. Errors in [files]
// only; null when the server is not connected or the call fails.
async function analyzeWarm($: any, files: string[]): Promise<string | null> {
  try {
    const root = fileUri(await $.session.cwd())
    try {
      await $.mcp.call('dart', 'roots', { command: 'add', uris: [root] })
    } catch {
      // the client may already provide the root
    }
    const r = await $.mcp.call('dart', 'analyze_files', { roots: [{ root }] })
    if (!r || r.isError) return null
    const text = (r.content ?? []).map((c: any) => String(c?.text ?? '')).join('\n')
    const norm = (s: string) => s.split(String.fromCharCode(92)).join('/')
    return lines(text)
      .filter(l => /^error\s*•/.test(l) && files.some(f => norm(l).includes(`• ${f}:`)))
      .slice(0, 15)
      .join('\n')
  } catch {
    return null
  }
}

async function analyze($: any, files: string[]): Promise<string> {
  const warm = await analyzeWarm($, files)
  if (warm !== null) return warm
  try {
    const args = ['dart', 'analyze', '--no-fatal-warnings', ...files]
    // FVM only when the project uses it, like scripts/agent/*.dart.
    const fvm = (await $.fs.exists('.fvmrc')) || (await $.fs.exists('.fvm'))
    const r = await runTool($, fvm ? ['fvm', ...args] : args)
    const out = String(r?.stdout || '') + String(r?.stderr || '')
    return lines(out)
      .filter(l => /^error\b|^\s*error\s+-/.test(l) || GOLDEN_LINTS.test(l))
      .slice(0, 15)
      .join('\n')
  } catch {
    return ''
  }
}

async function computeKey($: any, files: string[]): Promise<string> {
  const parts: string[] = []
  for (const f of files) {
    try {
      const text: string = await $.fs.read(f)
      parts.push(`${f}:${text.length}`)
    } catch {
      parts.push(`${f}:0`)
    }
  }
  return parts.join('|')
}

// origin's default branch (main, master, develop, ...), else main.
async function baseBranch($: any): Promise<string> {
  const ref = await git($, ['symbolic-ref', '--quiet', '--short', 'refs/remotes/origin/HEAD'])
  return ref ? ref.replace(/^origin\//, '') : 'main'
}

async function auditTarget($: any, arg: string) {
  let files: string[] = []
  let target = 'current diff'
  let fromBranch = ''
  if (arg.startsWith('lib/') || arg.startsWith('test/')) {
    target = arg
    files = lines(await git($, ['ls-files', '--cached', '--others', '--exclude-standard', '--', arg])).filter(isDart)
  } else if (arg) {
    const base = await baseBranch($)
    target = `branch ${arg} vs ${base}`
    fromBranch = arg
    files = lines(await git($, ['diff', '--name-only', `${base}...${arg}`])).filter(isDart)
  } else {
    files = await changedDart($)
    if (files.length === 0) {
      const base = await baseBranch($)
      target = `this branch vs ${base}`
      files = lines(await git($, ['diff', '--name-only', `${base}...HEAD`])).filter(isDart)
    }
  }
  const hits: Hit[] = []
  const { rules, audit } = await projectRules($)
  for (const f of files.slice(0, 400)) {
    let text = ''
    try {
      text = fromBranch ? await git($, ['show', `${fromBranch}:${f}`]) : await $.fs.read(f)
    } catch {
      text = ''
    }
    if (text) hits.push(...scan(f, text, rules))
  }
  return { files, target, hits, audit }
}

let lastPassed = ''
let stopBlockCount = 0

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'audit',
      description: 'Golden-rule audit of a branch, a folder, or the current diff',
      argumentHint: '[branch | lib/path]',
    })
    return next(e)
  })

  on('classic.Stop', async ($, e, next) => {
    if (e.stop_hook_active) return next(e)
    const files = await changedDart($)
    if (files.length === 0) return next(e)
    const key = await computeKey($, files)
    if (key === lastPassed) return next(e)

    const problems: string[] = []
    const errs = await analyze($, files)
    if (errs) problems.push(`Analyzer errors and golden-rule lints:\n${errs}`)
    const hits = await scanFiles($, files)
    if (hits.length) problems.push(`Golden-rule hits (AGENTS.md):\n${show(hits, 20)}`)

    if (problems.length === 0) {
      lastPassed = key
      stopBlockCount = 0
      return next(e)
    }

    if (stopBlockCount >= 2) {
      // Avoid infinite block loops if agent cannot resolve hits
      stopBlockCount = 0
      return next(e)
    }
    stopBlockCount++

    return {
      block: `done-gate: fix before finishing, or say why a hit is a false positive.\n${problems.join('\n\n')}`,
    }
  }).catch(($, e, next) => next(e))

  on('command.run', { command: 'audit' }, async ($, e) => {
    const { files, target, hits, audit } = await auditTarget($, e.args.trim())
    if (files.length === 0) return { text: `audit: no Dart files for ${target}.` }
    const body = hits.length ? show(hits, 60) : 'no regex hits'
    return {
      text: `audit ${target}: ${files.length} files, ${hits.length} hits`,
      context: [
        `The person ran /audit on ${target}. Regex scan below. Report PASS/FAIL per rule with file:line, marking each hit real or false positive. Then spot-check what regex cannot see, in these files only: a BLoC holding two repos, a repo extending another feature's repo, widgets importing rxdart, error text not localized (keys in both lib/l10n/app_en.arb and app_hi.arb), missing regression tests.${audit ? ` Project checks: ${audit}` : ''} Fix nothing unless the person asks.\n\nFiles (${files.length}):\n${files.slice(0, 80).join('\n')}\n\nScan:\n${body}`,
      ],
    }
  })
}
