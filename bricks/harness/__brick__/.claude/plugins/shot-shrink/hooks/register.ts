import type { Register } from 'claude-code'

export const IMAGE = /\.(png|jpe?g)$/i

export const smallPath = (p: string): string => {
  const f = p.split(String.fromCharCode(92)).join('/')
  const i = f.lastIndexOf('/')
  return `${f.slice(0, i + 1)}.small/${f.slice(i + 1)}`
}

// Each script reads SHRINK_SRC / SHRINK_DST from env, prints "small" when it
// wrote the 800px copy and "same" when the image is already 1000px or less.
// The .small folder gets a `*` .gitignore so copies never reach a commit.
// No resizer available (or any error) -> non-zero exit -> the original is read.

// Windows: PowerShell + System.Drawing (Windows PowerShell 5.1 ships it).
export const WINDOWS = [
  'Add-Type -AssemblyName System.Drawing',
  '$img = [System.Drawing.Image]::FromFile($env:SHRINK_SRC)',
  'try {',
  '$m = [Math]::Max($img.Width, $img.Height)',
  "if ($m -le 1000) { Write-Output 'same'; exit 0 }",
  '$s = 800 / $m; $w = [int]($img.Width * $s); $h = [int]($img.Height * $s)',
  '$dir = Split-Path $env:SHRINK_DST',
  'New-Item -ItemType Directory -Force -Path $dir | Out-Null',
  "$ign = Join-Path $dir '.gitignore'; if (-not (Test-Path $ign)) { Set-Content -Path $ign -Value '*' }",
  '$bmp = New-Object System.Drawing.Bitmap $w, $h',
  '$g = [System.Drawing.Graphics]::FromImage($bmp)',
  "$g.InterpolationMode = 'HighQualityBicubic'",
  '$g.DrawImage($img, 0, 0, $w, $h); $g.Dispose()',
  "$fmt = [System.Drawing.Imaging.ImageFormat]::Png",
  "if ($env:SHRINK_DST -match 'jpe?g$') { $fmt = [System.Drawing.Imaging.ImageFormat]::Jpeg }",
  '$bmp.Save($env:SHRINK_DST, $fmt); $bmp.Dispose()',
  "Write-Output 'small'",
  '} finally { $img.Dispose() }',
].join('; ')

// macOS: sips ships with the OS. Linux: ImageMagick 7 (`magick`) or 6
// (`identify` / `convert`) when installed; without one the script fails.
export const POSIX = [
  'set -e',
  'if command -v sips >/dev/null 2>&1; then',
  '  w=$(sips -g pixelWidth "$SHRINK_SRC" | awk \'/pixelWidth/{print $2}\')',
  '  h=$(sips -g pixelHeight "$SHRINK_SRC" | awk \'/pixelHeight/{print $2}\')',
  '  resize() { sips -Z 800 "$SHRINK_SRC" --out "$SHRINK_DST"; }',
  'else',
  '  if command -v magick >/dev/null 2>&1; then id="magick identify"; im="magick"; else id="identify"; im="convert"; fi',
  '  set -- $($id -format "%w %h" "$SHRINK_SRC[0]"); w=$1; h=$2',
  '  resize() { $im "$SHRINK_SRC" -resize 800x800 "$SHRINK_DST"; }',
  'fi',
  'm=$w; [ "$h" -gt "$m" ] && m=$h',
  'if [ "$m" -le 1000 ]; then echo same; exit 0; fi',
  'd=$(dirname "$SHRINK_DST"); mkdir -p "$d"',
  '[ -f "$d/.gitignore" ] || printf "*\n" > "$d/.gitignore"',
  'resize >/dev/null',
  'echo small',
].join('\n')

// Mods cannot read the OS, so try each resizer in turn: PowerShell is absent
// on macOS and Linux, `sh` on stock Windows.
export const ATTEMPTS: string[][] = [
  ['powershell', '-NoProfile', '-NonInteractive', '-Command', WINDOWS],
  ['sh', '-c', POSIX],
]

export const register: Register = on => {
  on('tool.call', { tool: 'Read' }, async ($, e, next) => {
    const path = String((e as any).file_path ?? '')
    if (!IMAGE.test(path) || path.split(String.fromCharCode(92)).join('/').includes('/.small/')) return next(e)
    const dst = smallPath(path)
    try {
      const src = await $.fs.stat(path)
      const have = (await $.fs.exists(dst)) ? await $.fs.stat(dst) : null
      if (have && have.mtimeMs >= src.mtimeMs) return next({ ...e, file_path: dst } as any)
      for (const argv of ATTEMPTS) {
        try {
          const r = await $.process.run(argv, { env: { SHRINK_SRC: path, SHRINK_DST: dst }, timeoutMs: 20000 })
          if (r.exitCode !== 0) continue
          if (String(r.stdout).includes('small')) return next({ ...e, file_path: dst } as any)
          break // "same": already small enough
        } catch {
          // this resizer does not exist on this OS: try the next
        }
      }
    } catch {}
    return next(e)
  }).catch(($, e, next) => next(e))
}
