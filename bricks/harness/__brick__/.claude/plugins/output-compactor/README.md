# output-compactor

A Claude Code mod that intercepts `tool.call` for `Bash` and automatically strips verbose terminal noise from `maestro test`, `flutter test`, and `dart analyze` failures.

## What it does
- **Maestro CLI**: Strips ASCII banners, device boot logs, and full view hierarchy dumps; extracts only the failing flow step, error message, and target element.
- **Flutter Test**: Extracts test failure names and `Expected`/`Actual` assertions, removing dozens of framework stack trace frames (`package:flutter/`, `package:test_api/`, `dart:async/`).
- **Dart Analyze**: Filters verbose info/hints, preserving actionable error lines.
- **Token Impact**: Saves 1,000–3,000 tokens per test failure.
