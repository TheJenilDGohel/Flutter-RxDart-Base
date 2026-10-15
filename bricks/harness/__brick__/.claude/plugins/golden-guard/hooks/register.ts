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

// Pure text scan of one Dart file against the AGENTS.md golden rules.
const scan = (file: string, text: string): Hit[] => {
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
    if (/import\s+'package:rxdart\//.test(row) && !isBloc && !isRepo && !/\/bloc\//.test(file) && !/lib\/(core|utils\/streams)/.test(file)) {
      add(i, 'R4 rxdart import outside a BLoC')
    }
    if (isFeature && /\bColor\(0x/.test(row)) add(i, 'S inline Color(0x...) (use a token)')
    if (/\bDateFormat\s*\(/.test(row) && !/date_format_utils\.dart$/.test(file)) add(i, 'S DateFormat outside AppDateFormat')
    if (/Future\.delayed\s*\(/.test(row)) add(i, 'S Future.delayed in lib (no fake delays)')
    if (/SharedPreferences|FlutterSecureStorage/.test(row) && !file.startsWith('lib/storage/') && /import|\.getInstance|FlutterSecureStorage\(/.test(row)) {
      add(i, 'S raw storage outside lib/storage')
    }
    if (/LogoutAction\s*\(/.test(row) && isFeature) add(i, 'S LogoutAction from a screen (use AuthSession.signOut)')
    if (isBloc && /(message|error|title)\s*:\s*'[A-Z][^']{6,}'/.test(row)) add(i, 'S hardcoded user text in BLoC (localize)')
    if (isFeature && /fileName\s*:\s*'[^']+\.[a-z]{3,4}'/.test(row)) add(i, 'S static file name literal')
  })

  // R13: ScreenUtil units inside a private widget class.
  const parts = text.split(/\n(?=class\s)/)
  let offset = 0
  for (const part of parts) {
    const m = part.match(/^class\s+(_\w+)\s+extends\s+(StatelessWidget|StatefulWidget|State<)/)
    if (m) {
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
  for (const f of files) {
    try {
      const text: string = await $.fs.read(f)
      all.push(...scan(f, text))
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

async function analyze($: any, files: string[]): Promise<string> {
  try {
    const r = await $.process.run(['cmd', '/c', 'fvm', 'dart', 'analyze', '--no-fatal-warnings', ...files], { timeoutMs: 120000 })
    const out = String(r.stdout) + String(r.stderr)
    return lines(out).filter(l => /^error\b|^\s*error\s+-/.test(l)).slice(0, 15).join('\n')
  } catch {
    return ''
  }
}

async function auditTarget($: any, arg: string) {
  let files: string[] = []
  let target = 'current diff'
  let fromBranch = ''
  if (arg.startsWith('lib/') || arg.startsWith('test/')) {
    target = arg
    files = lines(await git($, ['ls-files', '--cached', '--others', '--exclude-standard', '--', arg])).filter(isDart)
  } else if (arg) {
    target = `branch ${arg} vs main`
    fromBranch = arg
    files = lines(await git($, ['diff', '--name-only', `main...${arg}`])).filter(isDart)
  } else {
    files = await changedDart($)
    if (files.length === 0) {
      target = 'this branch vs main'
      files = lines(await git($, ['diff', '--name-only', 'main...HEAD'])).filter(isDart)
    }
  }
  const hits: Hit[] = []
  for (const f of files.slice(0, 400)) {
    let text = ''
    try {
      text = fromBranch ? await git($, ['show', `${fromBranch}:${f}`]) : await $.fs.read(f)
    } catch {
      text = ''
    }
    if (text) hits.push(...scan(f, text))
  }
  return { files, target, hits }
}

let lastPassed = ''

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
    const key = files.join('|')
    if (key === lastPassed) return next(e)

    const problems: string[] = []
    const errs = await analyze($, files)
    if (errs) problems.push(`Analyzer errors:\n${errs}`)
    const hits = await scanFiles($, files)
    if (hits.length) problems.push(`Golden-rule hits (AGENTS.md):\n${show(hits, 20)}`)

    if (problems.length === 0) {
      lastPassed = key
      return next(e)
    }
    return {
      block: `done-gate: fix before finishing, or say why a hit is a false positive.\n${problems.join('\n\n')}`,
    }
  }).catch(($, e, next) => next(e))

  on('command.run', { command: 'audit' }, async ($, e) => {
    const { files, target, hits } = await auditTarget($, e.args.trim())
    if (files.length === 0) return { text: `audit: no Dart files for ${target}.` }
    const body = hits.length ? show(hits, 60) : 'no regex hits'
    return {
      text: `audit ${target}: ${files.length} files, ${hits.length} hits`,
      context: [
        `The person ran /audit on ${target}. Regex scan below. Report PASS/FAIL per rule with file:line, marking each hit real or false positive. Then spot-check what regex cannot see, in these files only: a BLoC holding two repos, a repo extending another feature's repo, widgets importing rxdart, error text not localized (en/hi/gu ARB keys), missing regression tests. Fix nothing unless the person asks.\n\nFiles (${files.length}):\n${files.slice(0, 80).join('\n')}\n\nScan:\n${body}`,
      ],
    }
  })
}
