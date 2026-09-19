# Planning checklist: features, flows and journeys

Contents: 1 Method, 2 Per-screen questions (design mode), 3 Per-flow template, 4 Journey table, 5 Surfaces and design decisions, 6 Cross-cutting topics, 7 Document structure, 8 Quality bar.

Use this when turning a requirements or roadmap document into plans: user flows, user journeys, and the things a senior dev must think through.

**Two modes.** Default to **neutral mode**: describe who does what, in what order, what the system must do, and what can go wrong. Do not choose navigation patterns (drawer, tabs), screen names, app topology, which surface (mobile app, web console) hosts a step, or architecture. List those as open decisions with options and why they matter, without a recommended default, unless the user asks for one. Switch to **design mode** (screens, feature folder names, navigation) only when the user has said those decisions are made or asks for them. A hypothetical from the user ("if I had a drawer with four modules...") is a question, not a decision.

## 1. Method

1. Extract roles first. List every persona and the device, connectivity and permission context it works in. Design role-based screens rather than exposing every feature to every user.
2. Describe each module by what users need to do and what the system does. Do not assign steps to a surface (mobile app, web console, backend) unless the user decided; raise it as an open decision.
3. Design mode only: name features in `snake_case` as they would appear under `lib/features/`, one per screen or flow.
4. Walk each journey step by step: actor, surface, screen, system response, failure paths.
5. Collect the backend contract and base-gap implications as you go, then list open decisions with a recommended default.

## 2. Per-screen questions

- Who can open it, and which fields are visible or editable per role (field-level)?
- What are its states: loading, empty, error with retry, offline, stale data, no permission, partial success?
- Which endpoints does it call, and is each idempotent? What does a duplicate tap or a retry do?
- What happens on a 401, on `status: false`, on a timeout, on slow networks?
- Does it need offline reads or offline writes? If writes, what is the queue and the conflict rule?
- Does it hold sensitive data (minors, grades, health or wellbeing, finance, ID documents)? What must never reach logs, screenshots or the clipboard?
- How is it reached: drawer or tab, deep link from a notification, QR or NFC, another screen?
- What does it emit for notifications, analytics and audit correlation?
- Localization: strings via `context.l10n`, plural and date/number formats, and RTL if the tenant needs it.
- Accessibility: screen reader labels, text scaling, contrast, touch target size.
- Form factor: phone only, or tablet and kiosk?
- Test level: BLoC unit tests with a mocked repo, widget test for the content widget, and which journey covers it end to end.

## 3. Per-flow template

```
Flow: <name>
Actors: <roles>
Trigger: <what starts it>
Preconditions: <identity, permission, data state>
Happy path: 1 ... 2 ...
Alternate and failure paths: <offline, denied, validation, conflict, timeout>
Data involved: <information created, read or changed>
Notifications and audit: <what fires>
Open questions: <decisions needed>
```

## 4. Journey table

Use one table per journey with these columns (neutral mode):

| # | Actor | What happens | Rules and edge cases |

In design mode, add Surface and Screen or feature columns.

Keep steps at the level a QA engineer could turn into an end-to-end test.

## 5. Surfaces and design decisions

Do not assume where a step happens. Whether something lives in a mobile app, a web or back-office interface, or only in the backend is a scope decision for the team. In neutral mode, say who acts and what the system does, and add the surface question to the open-decisions list (with options and why it matters). Record any surface split you do propose as a proposal, and only when asked.

## 6. Cross-cutting topics to cover in any plan

Navigation and role routing; session lifecycle (bootstrap, expiry, logout, multi-device); permissions; tenancy, branding and localization; offline and sync; notifications and deep links; documents and uploads (size, type, progress, resume); payments (pending and failed states, idempotency, receipts, reconciliation); security and privacy (token storage, screenshot and root protection for exams and finance, PII in logs, children's data consent and retention, restricted wellbeing data); accessibility; performance on low-end Android (startup, memory, app size budgets); observability (crash reporting, analytics, audit correlation IDs); error contract with the backend; testing and release (flavors, staged rollout, feature flags); data migration and versioning of APIs.

## 7. Document structure for a user-flow and journey document (neutral mode)

1. How to read this document: purpose, what it does not decide, conventions, source.
2. Roadmap or scope at a glance.
3. Users and roles (what each needs to do; one person may hold several roles).
4. Foundation flows: who, what happens, rules and edge cases.
5. Capabilities by phase, taken from the source.
6. End-to-end journeys (one table each).
7. Situations every flow should handle.
8. Cross-cutting considerations.
9. Integration and data agreements to settle with the backend.
10. Open decisions (options and why they matter, no recommended default).
11. Appendix: glossary and traceability to the source.

Mark anything not in the source (edge cases, examples) as suggestions for the team to confirm.

## 8. Quality bar

- In design mode, every feature name maps to something a developer can scaffold.
- Every flow has failure paths, not only the happy path.
- Assumptions are labelled as assumptions; the source document's wording is not silently changed.
- Open decisions list options and why they matter. Add a recommended default only when the user asks for one.
