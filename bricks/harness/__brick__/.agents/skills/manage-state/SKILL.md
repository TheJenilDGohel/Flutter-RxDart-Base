---
name: manage-state
description: Decides where state lives and implements it in this Flutter Redux + RxDart app - per-screen RxDart BLoC recipes (form submit, live search with debounce, pagination and infinite scroll, one-off toast/navigation events, several loads on one screen, toggles and tabs, timers) and the rare, deliberate Redux session changes (AppState field, action, reducer, persistence, logout). Use when building or changing BLoC logic, streams, subjects, forms, search, paging, or anything touching AppStore, AppState, actions, reducers or persistence.
---

# Manage state

`AGENTS.md` §1: session data that must survive a restart goes in Redux, everything else in the screen's BLoC. Most bugs here are state in the wrong home or a BLoC breaking its lifecycle contract.

## 0. Load what this project learned
Read `.harness/skills/manage-state.md` if it exists (it wins over this file) and run `dart scripts/agent/learn.dart list manage-state`.

## 1. Decide the home
| The state is... | Home |
|---|---|
| Token, signed-in user, locale | Redux: `.agents/skills/manage-state/redux-changes.md` |
| A new persisted app-wide preference (theme, onboarding seen) | **Ask the owner first**; if approved, one narrow field via `redux-changes.md` |
| Fetched data, form input, validation, search, page, tab, toggle, selection | The screen's BLoC |
| Device capability (push, GPS, scanner, files) | A service in `lib/services/`, used by BLoCs |
| A cache shared by several screens | Local storage / cache-aside: `.agents/skills/manage-state/storage-recipes.md` |

Worked examples: `.agents/skills/flutter-senior-dev/references/redux-vs-rxdart.md`.

## 2. The BLoC contract
Copy the shape `mason make bloc` generates; never invent one.
- `final class XBloc with CancelTokenOwner`, repo injected (`XBloc({XRepo? repo})`) so tests pass a fake.
- Private subjects, public `Stream`s ending in `$`; seeded `BehaviorSubject` for state, `PublishSubject` for events.
- Every `add` goes through the template's `_emit` guard (drops it once closed); opened subscriptions go into `subscriptions`.
- `dispose()`: `cancelRequests()`, `subscriptions.dispose()`, then close every subject.
- A sync getter for `StreamBuilder.initialData` reads the subject (see `ShowcaseBloc`).

## 3. Pick a recipe
`.agents/skills/manage-state/bloc-recipes.md` (compiled in a generated app): A submit and double taps · B live search · C pagination and pull to refresh · D one-off events (toast, dialog, navigation) · E several loads on one screen · F dependent calls · G local UI state (tabs, toggles, selection) · H timers and polling.

## 4. Session (Redux) changes
`redux-changes.md`: action → reducer → `AppState` field → persistence → UI read → tests. The UI dispatches after the BLoC reports success (rule 10); BLoCs and repos only read session data through `AppStore`.

## 5. Verify
Test the recipe's edge cases (double submit, late stale search result, load-more failure, nothing emitted after `dispose()`), then `verify.dart`. What tripped you up goes in `.claude/rules/bloc.md` or `learn.dart add manage-state ...`.
