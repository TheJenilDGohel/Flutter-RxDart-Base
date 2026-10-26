---
paths:
  - "test/**/*_test.dart"
---

# Testing Standards & Verification Rules

These rules apply when writing, updating, or running automated unit and widget tests.

## Golden Rules for Testing
1. **BLoC Behavioral Coverage**:
   - Every BLoC must have tests for:
     - Initial stream state.
     - Successful fetch and state emission.
     - Error mapping and retry callback emission.
     - `dispose()` closing subjects without leaking streams.
2. **Fake Repositories**:
   - Test BLoCs with fake or mock repositories returning raw `Map<String, dynamic>` fixtures.
   - Do not mock Dio directly in feature BLoC tests.
3. **RxDart Stream Assertions**:
   - Assert stream sequences using `expectLater` and `emitsInOrder`.
   - Ensure subscriptions and asynchronous event queues flush before assertions.
4. **Widget Tests**:
   - Provide localized mock wrappers for `MaterialApp` with theme and localizations.
   - Avoid infinite `pumpAndSettle()` timeouts when continuous stream timers or animations are running.
