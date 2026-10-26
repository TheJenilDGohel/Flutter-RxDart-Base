# Decisions: output-compactor

## 1. Post-Execution Tool Interception vs Pre-Execution Wrapper
- **Decision**: Intercept `tool.call` for `Bash`, await `next(e)`, and transform `stdout`/`stderr` only when output contains failure indicators.
- **Alternative rejected**: Rewriting the shell command to pipe through grep/sed (e.g. `maestro test ... | grep -E`).
- **Reason**: Shell pipes break cross-platform compatibility across Windows cmd/PowerShell and Unix bash, and suppress raw exit codes. In-process transformation preserves exact exit codes while shielding Claude's context.

## 2. Token Budget & Failure-Only Compaction
- **Decision**: Leave passing test runs (`0 failures`) untouched; compact only failed runs.
- **Alternative rejected**: Compacting all test outputs including successes.
- **Reason**: Passing test outputs are already short and clean. Only failure traces dump thousands of characters.
