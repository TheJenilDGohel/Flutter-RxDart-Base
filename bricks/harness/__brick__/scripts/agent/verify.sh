#!/usr/bin/env bash
set -e

echo "🔍 [1/4] Checking Dart formatting..."
dart format --set-exit-if-changed .
echo "✅ Formatting clean."

echo "🔬 [2/4] Running Flutter analyzer (--fatal-infos)..."
flutter analyze --fatal-infos
echo "✅ Analysis clean."

echo "🏗️ [3/4] Running custom architectural lints..."
dart run custom_lint
echo "✅ Custom lints clean."

echo "📸 [4/4] Regenerating project snapshot..."
dart run scripts/agent/snapshot.dart
echo "✅ Snapshot updated."

echo "🎉 All quality gates passed cleanly!"
