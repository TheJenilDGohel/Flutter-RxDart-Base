import type { Register } from 'claude-code'

export const MAX_CHARS = 30000

export const bannedPath = (p: string): boolean => {
  const f = p.split(String.fromCharCode(92)).join('/')
  return /\.(g|freezed)\.dart$/.test(f) || /(^|\/)(build|\.dart_tool)\//.test(f)
}

export const register: Register = on => {
  on('tool.call', { tool: 'Read' }, async ($, e, next) => {
    const path = String((e as any).file_path ?? '')
    if (bannedPath(path)) {
      return { deny: 'read-guard: generated or build file (*.g.dart, *.freezed.dart, build/, .dart_tool/); read the source instead.' }
    }
    const partial = (e as any).offset !== undefined || (e as any).limit !== undefined
    if (!partial && path) {
      try {
        const st = await $.fs.stat(path)
        if (st.kind === 'file' && st.size > MAX_CHARS && !/\.(png|jpe?g|pdf|gif|webp)$/i.test(path)) {
          return { deny: `read-guard: ${Math.round(st.size / 1000)}k file; use Grep or offset/limit.` }
        }
      } catch {}
    }
    return next(e)
  }).catch(($, e, next) => next(e))
}
