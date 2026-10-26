# Quality gate. See verify.dart for options (--fast, --no-snapshot).
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..\..")
if ((Test-Path ".fvm") -or (Test-Path ".fvmrc")) {
    fvm dart run scripts/agent/verify.dart @args
} else {
    dart run scripts/agent/verify.dart @args
}
exit $LASTEXITCODE
