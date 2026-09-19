#!/usr/bin/env bash
set -e

echo "🔍 [1/2] Checking Dart formatting..."
dart format --set-exit-if-changed .
echo "✅ Formatting clean."

echo "🔬 [2/3] Running Flutter analyzer (--fatal-infos)..."
flutter analyze --fatal-infos
echo "✅ Analysis clean."

echo "📸 [3/3] Regenerating project snapshot..."
dart run scripts/agent/snapshot.dart
echo "✅ Snapshot updated."

echo "🎉 All quality gates passed cleanly!"
