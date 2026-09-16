#!/usr/bin/env bash
set -e

echo "🔍 [1/2] Checking Dart formatting..."
dart format --set-exit-if-changed .
echo "✅ Formatting clean."

echo "🔬 [2/2] Running Flutter analyzer (--fatal-infos)..."
flutter analyze --fatal-infos
echo "✅ All quality gates passed cleanly!"
