# Base gaps and extension recipes

Contents: 1 Security and session, 2 API contract, 3 Offline, 4 Permissions and modules, 5 Forms and shared models, 6 Devices and form factors, 7 Streaming and AI, 8 Tenancy, 9 Changing the base safely.

These are the places where the base, as shipped, does not cover what larger LMS/ERP-style apps need. Raise them early, in the phase where they first bite, and keep each fix small and inside the golden rules.

## 1. Security and session

- **Token storage.** The token is persisted in plain SharedPreferences. For apps holding minors' or financial data, move the token to `flutter_secure_storage`: change `AppStore.init` and `persistence_middleware`, keep the rest of `AppState` where it is.
- **Refresh flow.** `AuthInterceptor` only injects the token, and `AppState` has no refresh token. Add `refreshToken` to state and actions, then on a 401 refresh once and retry, or dispatch `LogoutAction` and route to sign-in. Put the interceptor before the retry step and avoid refresh loops (single in-flight refresh, no refresh on the refresh call).
- **Other controls.** Certificate pinning, root/jailbreak detection and screenshot blocking for exam and finance screens are native concerns behind a service in `lib/services/`. Never log PII; `snug_logger` output and the Redux logging middleware are debug only.

## 2. API contract

- Responses must be JSON objects. Either the backend wraps lists (`{"items": [...]}`) or add a `getList` method to `ApiBaseHelper`.
- Business errors are `{"status": false, "message": ...}` with HTTP 200/201; that message is shown verbatim, so it must be safe, localized copy.
- `PlatformInjectorInterceptor` adds `{"platform": "app"}` to every JSON body. Confirm the backend expects it, or remove it.
- Agree pagination (cursor or page), sorting and filter conventions, an API version header, and an idempotency key for payments and other writes.

## 3. Offline

`ConnectivityInterceptor` rejects requests when offline, which is right for reads and wrong for queued writes. For offline-first features such as attendance: add a local store (sqflite or Drift) and a queue service in `lib/services/`, let the BLoC write to the queue and the service replay it when connectivity returns, define conflict rules per entity (last write wins vs server wins with a review), and show queued and failed items in the UI. Decide the store at the start of the phase that needs it, not earlier.

## 4. Permissions and modules

- Keep role, permissions and enabled-module flags inside `userData`; do not add fields to Redux for this. Add one `Can(permission)` helper in `utils/` (with a field-level variant) and use it for both visibility and disabled states. The backend still enforces.
- Drawer and tab entries come from one module list (`lib/modules.dart`) filtered by `Can()` and the tenant's enabled modules. Routes stay wired by `wire_route.dart`. If a module must be absent from a binary, give it its own delegated router and a separate entry point or flavor.

## 5. Forms and shared models

- Server-driven forms need dynamic fields without `setState`: a `DynamicFormBloc` exposes `values$` and validation state, the widget owns a map of controllers and disposes them, and the field renderers live in `utils/widgets/common/`.
- The first time two features need one model, create `lib/shared/models/`. Features never import other features.

## 6. Devices and form factors

`flutter_screenutil` is set up for phones. Kiosk and tablet screens (POS, invigilator) need their own design size or adaptive layout, and dense desktop tables are a poor fit; treat a web admin console as a separate decision. Background GPS and scanners need real-device testing (battery optimization, permissions) and live in `lib/services/`.

## 7. Streaming and AI

`ApiBaseHelper` has no streaming call. Add one using Dio `ResponseType.stream` that returns a `Stream<String>` chunk stream, and let the BLoC turn it into `ApiResponse` states. Keep "AI drafts, humans approve" visible in the UI: drafts are labelled, approval goes through the normal workflow, and PII is redacted on the client before anything is sent.

## 8. Tenancy

Branding, locale, grading and date formats vary per institution. Load tenant config at bootstrap and keep it out of widget code (tokens in `ResColors`, formats behind helpers). Start with per-flavor config; move to runtime tenant config only when one build must serve several tenants.

## 9. Changing the base safely

Follow the project's `CONTRIBUTING.md`: bump the affected brick version and CHANGELOG, update READMEs in the same change, mirror any mechanically enforceable golden rule in `redux_rxdart_lints`, run format and analyze from each touched package directory, dry-run any `wire_route.dart` or hook injection change against real templates, and commit only when asked.
