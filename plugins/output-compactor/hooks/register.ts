import type { Register } from 'claude-code'

const stripAnsi = (str: string): string =>
  str.replace(/\u001b\[[0-9;]*[a-zA-Z]/g, '')

const compactMaestro = (raw: string): string => {
  const clean = stripAnsi(raw)
  const lines = clean.split('\n')
  const kept: string[] = []

  let inFailure = false
  for (const line of lines) {
    const trimmed = line.trim()
    if (!trimmed) continue

    // Capture the failure header and failing step
    if (
      /failed|error:|exception|assertion failed|element not found|timed out/i.test(trimmed) ||
      /line \d+:/i.test(trimmed) ||
      /^- \w+:/i.test(trimmed)
    ) {
      inFailure = true
      kept.push(trimmed)
      continue
    }

    // Capture hierarchy snippets only if short
    if (inFailure && trimmed.length < 120 && kept.length < 15) {
      if (!/║|═|─|│|env:|appId:|launchApp/i.test(trimmed)) {
        kept.push(trimmed)
      }
    }
  }

  if (kept.length === 0) {
    if (lines.length <= 25) return clean
    return `[Maestro Failure Summary]\n${lines.slice(0, 15).join('\n')}\n...\n${lines.slice(-8).join('\n')}`
  }
  return `[Maestro Failure Summary]\n${kept.slice(0, 15).join('\n')}`
}

const compactFlutterTest = (raw: string): string => {
  const clean = stripAnsi(raw)
  const lines = clean.split('\n')
  const kept: string[] = []

  for (const line of lines) {
    const trimmed = line.trim()
    if (!trimmed) continue

    if (/\[E\]$/.test(trimmed) || /\bExpected:/.test(trimmed) || /\bActual:/.test(trimmed) || /\bWhich:/.test(trimmed)) {
      kept.push(trimmed)
      continue
    }

    // Include app-level stack trace lines, drop Flutter framework internals
    if (/^(package:|test\/)/.test(trimmed) && !/package:(flutter|test_api|matcher|stack_trace)\//.test(trimmed)) {
      kept.push(trimmed)
    }
  }

  if (kept.length === 0) {
    if (lines.length <= 25) return clean
    return `[Flutter Test Failure Summary]\n${lines.slice(0, 15).join('\n')}\n...\n${lines.slice(-8).join('\n')}`
  }
  return `[Flutter Test Failure Summary]\n${kept.slice(0, 20).join('\n')}`
}

const compactDartAnalyze = (raw: string): string => {
  const clean = stripAnsi(raw)
  const lines = clean.split('\n')
  const errors = lines.filter(l => /^\s*error\b|^\s*error\s+-/i.test(l))
  if (errors.length === 0) return clean
  return `[Dart Analyze Errors (${errors.length})]\n${errors.slice(0, 25).join('\n')}`
}

export const register: Register = on => {
  on('tool.call', { tool: 'Bash' }, async ($, e, next) => {
    const ran = await next(e)

    // Inspect command to see if it targets maestro, flutter test, or dart analyze
    const cmd = e.command || ''
    const isMaestro = /\bmaestro\s+test\b/i.test(cmd)
    const isFlutterTest = /\bflutter\s+test\b/i.test(cmd)
    const isDartAnalyze = /\b(dart|flutter)\s+analyze\b/i.test(cmd)

    if (!isMaestro && !isFlutterTest && !isDartAnalyze) {
      return ran
    }

    if (ran && typeof ran === 'object' && 'result' in ran && ran.result) {
      const res = ran.result as { stdout?: string; stderr?: string }
      if (res.stdout) {
        if (isMaestro && /failed|error/i.test(res.stdout)) {
          res.stdout = compactMaestro(res.stdout)
        } else if (isFlutterTest && /\[E\]|Some tests failed/i.test(res.stdout)) {
          res.stdout = compactFlutterTest(res.stdout)
        } else if (isDartAnalyze && /error\b/i.test(res.stdout)) {
          res.stdout = compactDartAnalyze(res.stdout)
        }
      }
      if (res.stderr) {
        if (isMaestro && /failed|error/i.test(res.stderr)) {
          res.stderr = compactMaestro(res.stderr)
        } else if (isFlutterTest && /\[E\]/i.test(res.stderr)) {
          res.stderr = compactFlutterTest(res.stderr)
        } else if (isDartAnalyze && /error\b/i.test(res.stderr)) {
          res.stderr = compactDartAnalyze(res.stderr)
        }
      }
    }

    return ran
  }).catch(($, e, next) => next(e))
}
