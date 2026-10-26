---
name: write-tests
description: Writes and fixes tests for this Flutter Redux + RxDart + Dio app - BLoC stream tests with the generated Fake repo pattern, model parsing tests from real contract JSON, widget tests for content widgets (ScreenUtil + l10n test harness), reducer and persistence tests, plus turning acceptance criteria and bug reports into regression tests. Use when asked to add, write, fix or improve tests or coverage, when a test fails, or after any feature or bug fix that lacks one.
---

# Write tests

A test here proves a contract the architecture promises: states arrive in order, errors are typed and retryable, nothing emits after dispose, and wire data can't crash a screen. Test behavior through public streams and widgets, never private fields.

## 0. Load what this project learned
1. Read `.harness/skills/write-tests.md` if it exists. It wins over this file.
2. Check the Knowledge Graph (`search_nodes` / `read_graph`) or run `dart run scripts/agent/learn.dart list write-tests`.

## 1. What to test, by layer
| Layer | Test | Always? |
|---|---|---|
| BLoC | Stream states for success, `ApiException` + retry, unexpected error, cancellation, refresh, dispose, plus each recipe's edge cases | Yes |
| Model | `fromJson` with the real contract response, missing fields, wrong types | When it parses more than id/name |
| Content widget | Renders the data; conditional UI (empty, badges, disabled buttons) | When it branches |
| Reducer / persistence | New action, `LogoutAction`, round trip | For any Redux change |
| Repo | Usually skipped: it's a pass-through, and the lint guards it | Only for non-trivial request building |

Put tests at the mirrored path: `test/features/<name>/bloc/<name>_bloc_test.dart`, plus `model/` and `widgets/` siblings.

## 2. BLoC tests: the generated pattern
`mason make bloc` writes 7 passing tests. Extend them instead of starting over:

```dart
/// Repo double: each call runs the next queued response.
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

- Queue success (`() async => {...}`), failure (`() async => throw const NotFoundException()`) or a `Completer` future to control timing.
- Collect states with `bloc.page$.listen(states.add)`, then `await bloc.fetch(); await pumpEventQueue();` and match with `isA<SuccessResponse<T>>().having(...)`.
- `tearDown(() => bloc.dispose())`. To test dispose itself, dispose mid-request (a `Completer`) and assert the call completes without throwing.
- Never hit the network: always inject the fake repo. `ApiBaseHelper.instance` in a test is a bug.

Edge cases worth a test, from the recipes in `.agents/skills/manage-state/bloc-recipes.md`:
- **Submit**: a second `submit` while loading makes no second repo call (`repo.calls == 1`).
- **Search**: add `'a'`, `'ab'`, `'abc'` quickly, then `await Future<void>.delayed(const Duration(milliseconds: 350))`. Expect one repo call, for `'abc'`.
- **Pagination**: a failed `loadMore` keeps the items and sets `loadMoreError`; `fetch(refresh: true)` during `loadMore` wins.
- **Several loads**: one section failing leaves the other `SuccessResponse`.

## 3. Model tests
Paste the contract's real response as a `const` map. Assert every field, then a map with fields missing, `null`, and the wrong type (`'12'` for `12`): parsing returns defaults and never throws (rule 12).

## 4. Widget tests (content widgets)
Content widgets use ScreenUtil and l10n, so pump them inside both:

```dart
Widget harness(Widget child) => ScreenUtilInit(
  designSize: const Size(375, 812),
  builder: (_, _) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  ),
);

testWidgets('shows the order title', (tester) async {
  await tester.pumpWidget(harness(OrdersListWidget(page: page, controller: ScrollController(), onRetryMore: () {})));
  await tester.pumpAndSettle();
  expect(find.text('First order'), findsOneWidget);
});
```

Pages create real BLoCs (and therefore real repos), so test pages only through their content widget plus the BLoC tests. If a test touches `ApiConstants` (a repo test, say), load an env first: `dotenv.loadFromString(envString: 'BASE_URL=https://api.test')`.

## 5. Redux tests
- Reducer: `appReducer(const AppState(), const SetLocaleAction('hi'))`, then assert the field and the untouched ones.
- Persistence: `SharedPreferences.setMockInitialValues({})`, a `Store` with `persistenceMiddleware`, dispatch, `await persistenceIdle`, then read the prefs.
- The app smoke test (`test/widget_test.dart`) builds `MyApp` with an in-memory store. Keep it passing when you change `main.dart`.

## 6. End-to-End Device Testing (Maestro)
For full integration and device user journeys on connected emulators or devices:
- Declarative YAML flows live in `.maestro/flows/` (e.g. `smoke_launch.yaml`).
- Run via CLI: `maestro test .maestro/flows/smoke_launch.yaml`.
- Prefer declarative Maestro assertions (`assertVisible`, `tapOn`) over token-heavy screenshot scrapes.
- Subagent `@device-qa` (`.claude/agents/device-qa.md`) runs these journeys.

## 7. From criteria and bugs to tests
- Each acceptance criterion in `.harness/specs/<feature>.md` maps to at least one test named after it (`'AC2: empty list shows the empty state'`).
- Each bug fix starts with a test that fails for the reported reason (`.agents/skills/fix-bug/SKILL.md`).

## 8. Run and close out
- In-flight check: `dart run scripts/agent/on_edit.dart`.
- One file while iterating: `flutter test test/features/<name>/`.
- Before reporting done: `dart run scripts/agent/verify.dart`.
- A flaky test is a bug in the test or the BLoC: usually a missing `pumpEventQueue()`, a real timer, or a shared singleton. Fix it; never skip it. Record the cause into the Knowledge Graph (`add_observations`), in `.claude/rules/testing.md`, or with `learn.dart add write-tests ...`.
