$ErrorActionPreference = "Stop"

Write-Host "🔍 [1/2] Checking Dart formatting..." -ForegroundColor Cyan
dart format --set-exit-if-changed .
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Formatting check failed! Run 'dart format .' to fix." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Formatting clean." -ForegroundColor Green

Write-Host "🔬 [2/2] Running Flutter analyzer (--fatal-infos)..." -ForegroundColor Cyan
flutter analyze --fatal-infos
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Static analysis failed with errors or warnings!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ All quality gates passed cleanly!" -ForegroundColor Green
