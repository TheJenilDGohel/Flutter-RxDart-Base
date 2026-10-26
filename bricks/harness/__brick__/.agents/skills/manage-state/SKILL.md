---
name: manage-state
description: Decides where state lives and implements it in this Flutter Redux + RxDart app - per-screen RxDart BLoC recipes (form submit, live search with debounce, pagination and infinite scroll, one-off toast/navigation events, several loads on one screen, toggles and tabs, timers) and the rare, deliberate Redux session changes (AppState field, action, reducer, persistence, logout). Use when building or changing BLoC logic, streams, subjects, forms, search, paging, or anything touching AppStore, AppState, actions, reducers or persistence.
---

# Manage state

Two homes, one rule: **session data that must survive a restart goes in Redux; everything else goes in the screen's BLoC.** Most bugs in this area come from state in the wrong home or a BLoC that breaks its lifecycle contract.

## 0. Load what this project learned
1. Read `.harness/skills/manage-state.md` if it exists. It wins over this file.
2. Check the Knowledge Graph (`search_nodes` / `read_graph`) or run `dart run scripts/agent/learn.dart list manage-state`.

## 1. Decide the home
| The state is... | Home |
|---|---|
| Token, signed-in user, locale; must survive a cold start | Redux (`AppState`). Change it with `.agents/skills/manage-state/redux-changes.md`. |
| A new app-wide preference that must persist (theme, onboarding seen) | **Stop and ask the owner.** `AGENTS.md` §1 limits Redux to `authToken`, `userData` and `locale`. If they approve, add one narrow field with `.agents/skills/manage-state/redux-changes.md`. |
| Fetched data, form input, validation, search, page, tab, toggle, selection | The screen's BLoC |
| Device capability (push, GPS, scanner, file system) | A service in `lib/services/`, consumed by BLoCs |
| A cache shared by several screens | Local database / cache-aside (see `.agents/skills/manage-state/storage-recipes.md`), not Redux. |

Worked examples: `.agents/skills/flutter-senior-dev/references/redux-vs-rxdart.md`. Storage & offline recipes: `.agents/skills/manage-state/storage-recipes.md`.

## 2. The BLoC contract (what every BLoC here does)
Copy the shape `mason make bloc` generates. Never invent a new one.
- `final class XBloc with CancelTokenOwner`, repo injected through the constructor (`XBloc({XRepo? repo})`) so tests can pass a fake.
- Private subjects, public `Stream`s ending in `$`. `BehaviorSubject` (seeded) holds state; `PublishSubject` carries one-off events.
- Every `add` goes through a guard that drops it once the subject is closed (the template's `_emit`).
- Subscriptions the BLoC opens go into `subscriptions` (a `CompositeSubscription`).
- `dispose()` calls `cancelRequests()`, then `subscriptions.dispose()`, then closes every subject.
- Need a synchronous value for `StreamBuilder.initialData`? Add a getter that reads the subject (see `ShowcaseBloc`). Widgets never touch subjects (rule 4 🔒).
- The page (`StatefulWidget`) creates the BLoC, starts the first load, and disposes it. Content widgets get plain data.

## 3. Pick a recipe
`.agents/skills/manage-state/bloc-recipes.md` has complete code for each pattern, compiled and analyzed in a generated app:

| Need | Recipe |
|---|---|
| Submit a form, create/update/delete, prevent double taps | A. Submit |
| Search as the user types | B. Live search |
| Infinite scroll, load more, pull to refresh a list | C. Pagination |
| Toast, dialog or navigation after something happens | D. One-off events |
| Several independent sections loading on one screen | E. Several loads |
| Calls that depend on each other's results | F. Dependent calls |
| Tabs, toggles, selection, password visibility | G. Local UI state |
| Polling, countdowns, periodic refresh | H. Timers |

## 4. Session (Redux) changes
Only for the first row of the table in step 1, or the second once the owner approved it. Follow `.agents/skills/manage-state/redux-changes.md`: action → reducer → `AppState` field → persistence → reading it in the UI → tests. The UI dispatches after the BLoC reports success (rule 10). BLoCs and repos only *read* the store, through `AppStore`, and only for session data.

## 5. Verify and close out
1. Test the recipe's edge cases (`.agents/skills/write-tests/SKILL.md`): double submit, a stale search result arriving late, load-more failure, no emission after `dispose()`.
2. Run `dart run scripts/agent/on_edit.dart` on touched files for sub-second feedback.
3. Run `dart run scripts/agent/verify.dart` for the full quality gate.
4. Close out per `AGENTS.md` §6, recording what tripped you up into the Knowledge Graph (`add_observations`), in `.claude/rules/bloc.md`, or with `learn.dart add manage-state ...`.
