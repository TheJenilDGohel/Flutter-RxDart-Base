# Redux vs RxDart — worked examples

Core rule (from `CLAUDE.md` / `AGENTS.md`): survives navigation or a cold restart → Redux.
Everything else → the feature's own BLoC.

| Data | Where | Why |
|---|---|---|
| Auth JWT | Redux (`AppState.authToken`) | needed by `AuthInterceptor` on every request, across every screen, after a restart |
| User profile (name, avatar) | Redux | shown in app bar / drawer across many unrelated screens |
| Locale (`en`/`hi`) | Redux | affects the whole app, must persist |
| A list of search results | Feature BLoC | belongs to one screen, refetched every time it's opened |
| "is this form field valid" | Feature BLoC | pure UI state, meaningless outside this screen |
| Selected tab index | Feature BLoC | resets on screen re-entry, that's fine |
| "has the user seen the onboarding" | Redux, but as a dedicated flag — don't fold it into unrelated state | must survive restart, but keep `AppState` additions narrow and explicit |

## Adding a new Redux action
Only when the data genuinely needs the YES side of the rule. Extend the sealed `AppAction`
hierarchy in `lib/redux/actions.dart`, handle it exhaustively in `lib/redux/reducers/app_reducer.dart`,
and if it should survive a restart, confirm `persistenceMiddleware` covers the new field —
`AppState` fields aren't persisted automatically just by existing.

## Anti-pattern to catch in review
A feature repo or bloc reaching into `AppStore` for anything beyond reading `authToken` (e.g. to
stash a screen's fetch result "for convenience") — that's screen state leaking into global state.
Push back on it even if it "works," per the golden rules in `AGENTS.md`.
