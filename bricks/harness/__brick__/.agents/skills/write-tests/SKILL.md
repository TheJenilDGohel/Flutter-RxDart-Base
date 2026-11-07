---
name: write-tests
description: Writes and fixes tests for this Flutter Redux + RxDart + Dio app - BLoC stream tests with the generated Fake repo pattern, model parsing tests from real contract JSON, widget tests for content widgets (ScreenUtil + l10n test harness), reducer and persistence tests, plus turning acceptance criteria and bug reports into regression tests. Use when asked to add, write, fix or improve tests or coverage, when a test fails, or after any feature or bug fix that lacks one.
---

# Write tests

A test proves a contract the architecture promises: states arrive in order, errors are typed and retryable, nothing emits after dispose, wire data can't crash a screen. Test through public streams and widgets, never private fields.

## 0. Load what this project learned
Read `.harness/skills/write-tests.md` if it exists (it wins over this file) and run `dart run scripts/agent/learn.dart list write-tests`.

## 1. What to test
| Layer | Test | When |
|---|---|---|
| BLoC | success, `ApiException` + retry, unexpected error, cancellation, refresh, dispose, recipe edge cases | Always |
| Model | real contract response, missing fields, wrong types | Parses more than id/name |
| Content widget | renders data; empty, badges, disabled buttons | It branches |
| Reducer / persistence | new action, `LogoutAction`, round trip | Any Redux change |
| Repo | skipped (pass-through, linted) | Non-trivial request building only |

Mirrored paths: `test/features/<name>/bloc/<name>_bloc_test.dart` plus `model/` and `widgets/` siblings.

## 2. BLoC tests
`mason make bloc` writes 7 passing tests; extend them. The fake repo queues responses:

```dart
class FakeOrdersRepo implements OrdersRepo {
  final responses = <Future<Map<String, dynamic>> Function()>[];
  int calls = 0;
  @override
  Future<Map<String, dynamic>> fetchOrders({required int page, CancelToken? cancelToken}) {
    calls++;
    return responses.removeAt(0)();
  }
}
```
- Queue success, a thrown `NotFoundException`, or a `Completer` future for timing. Collect with `bloc.page$.listen(states.add)`, `await bloc.fetch(); await pumpEventQueue();`, match with `isA<SuccessResponse<T>>().having(...)`.
- `tearDown(() => bloc.dispose())`; to test dispose, dispose mid-request and assert no throw. `ApiBaseHelper.instance` in a test is a bug.
- Edge cases (recipes in `.agents/skills/manage-state/bloc-recipes.md`): second `submit` while loading → `repo.calls == 1`; search `'a'`, `'ab'`, `'abc'` then wait 350 ms → one call for `'abc'`; failed `loadMore` keeps items and sets `loadMoreError`, `fetch(refresh: true)` during it wins; one failing section leaves the other `SuccessResponse`.

## 3. Model tests
The real response as a `const` map, every field asserted; then missing and `null` fields return defaults, a numeric string (`'12'` for `12`) parses, and a wrong type (`{}` for a list) falls back, all without throwing (rule 12).

## 4. Widget tests
Pump content widgets inside ScreenUtil and l10n:

```dart
Widget harness(Widget child) => ScreenUtilInit(
  designSize: const Size(375, 812),
  builder: (_, _) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  ),
);
```
Pages create real BLoCs, so test them through the content widget plus BLoC tests. A test touching `ApiConstants` loads an env first: `dotenv.loadFromString(envString: 'BASE_URL=https://api.test')`.

## 5. Redux tests
Reducer: `appReducer(const AppState(), const SetLocaleAction('hi'))`, assert the field and the untouched ones. Persistence: `SharedPreferences.setMockInitialValues({})`, a `Store` with `persistenceMiddleware`, dispatch, `await persistenceIdle`, read the prefs. Keep `test/widget_test.dart` (builds `MyApp` with an in-memory store) green.

## 6. Criteria, bugs, device flows
Each acceptance criterion in `.harness/specs/<feature>.md` gets a test named after it (`'AC2: empty list shows the empty state'`); each bug fix starts with a failing test (`.agents/skills/fix-bug/SKILL.md`). Device journeys are Maestro flows in `.maestro/flows/` (`AGENTS.md` §4).

## 7. Run
`affected_tests.dart` per change, `flutter test test/features/<name>/` while iterating, `verify.dart` before done. A flaky test is a bug (missing `pumpEventQueue()`, a real timer, a shared singleton): fix it, never skip it, and record the cause in `.claude/rules/testing.md` or `learn.dart add write-tests ...`.
