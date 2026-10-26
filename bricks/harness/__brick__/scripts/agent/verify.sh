#!/usr/bin/env bash
# Quality gate. See verify.dart for options (--fast, --no-snapshot).
set -e
cd "$(dirname "$0")/../.."
if [ -d ".fvm" ] || [ -f ".fvmrc" ]; then
  exec fvm dart run scripts/agent/verify.dart "$@"
else
  exec dart run scripts/agent/verify.dart "$@"
fi
