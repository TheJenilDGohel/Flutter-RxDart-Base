---
name: build-ui
description: Builds or changes Flutter UI in this Redux + RxDart app the house way - page/content-widget split, AppResponseBuilder states, ResColors and AppTypography tokens, ScreenUtil sizing in public widgets only, context.l10n strings in both ARB files, shared widgets under lib/utils/widgets/ui (Rule of 2), CommonButton, AppDialog, ShowMessage toasts and accessibility. Use for any widget, layout, styling, theming, string, dialog, toast, empty/error/loading state or "make it look like this design" request.
---

# Build UI

Widgets render state; they don't own it. Pages wire a BLoC to the screen, content widgets draw plain data, and everything visual comes from tokens, so a design change touches one file instead of fifty.

> [!TIP]
> **Token-Saving Input Boundary:** When implementing UI, inspect only the public `Stream<ApiResponse<T>>` / `data$` contract, parsed model fields, and required UI states. Never pull raw JSON schemas or BLoC test output logs into your UI context.

## 0. Load what this project learned
1. Read `.harness/skills/build-ui.md` if it exists (design decisions, custom tokens, components added here). It wins over this file.
2. Check the Knowledge Graph (`search_nodes` / `read_graph`) or run `dart run scripts/agent/learn.dart list build-ui`.
3. Check `lib/utils/widgets/ui/` before building anything: the widget may already exist.

## 1. Structure
- **Page** (`<name>_page.dart`, a `StatefulWidget`): creates and disposes the BLoC and any Flutter controllers, subscribes to one-off events, binds streams. Standard `Scaffold` by default; `AppScaffold` when the shared chrome is wanted (rule 6).
- **Content widget** (`widgets/`): a `StatelessWidget` that takes parsed models and callbacks. Never the BLoC, never a `Stream`. That keeps it trivially testable.
- **State binding**: `AppResponseBuilder<T>(stream: _bloc.data$, builder: ...)` handles initial, loading and error (with retry) for you. Use a raw `StreamBuilder` only for non-`ApiResponse` streams (a toggle, a tab), with `initialData` from the BLoC's sync getter.
- No `setState` in features (rule 3 🔒) and no `rxdart` import in widgets (rule 4 🔒).

## 2. Visual tokens
- **Colors**: `ResColors` only (`lib/resources/res_colors.dart`). Need a color that isn't there? Add a token, never an inline `Color(0x...)`. Opacity: `.withValues(alpha: 0.5)`, never the deprecated `withOpacity`.
- **Text**: `context.textTheme.<style>` (`AppTypography`, already ScreenUtil-scaled), adjusted with `copyWith`. Don't build `TextStyle`s from scratch.
- **Sizes**: `flutter_screenutil`: `.w` widths and horizontal padding, `.h` heights and vertical gaps, `.r` radii, `.sp` font sizes. Design size 375×812. These work only in **public** widgets: a private `_Foo` isn't rebuilt on resize, and `no_screenutil_in_private_widget` fails the gate (rule 13 🔒). Make the widget public, or compute the size in a public parent and pass it down.

## 3. States every screen needs
| State | Widget |
|---|---|
| Loading | `AppLoadingState` (automatic in `AppResponseBuilder`) |
| Error + retry | `AppErrorState` (automatic, using `userFacingMessage(context)`) |
| Empty | `AppEmptyState(message: context.l10n.<key>)`. Its default message is English, so always pass one. |
| Inline action error | `Text(error.userFacingMessage(context))`, never `e.toString()` (rule 2) |

## 4. Strings (l10n)
1. Add the key to `lib/l10n/app_en.arb` with an `@key` description, and the same key to `lib/l10n/app_hi.arb`. A missing Hindi key is a bug, not a follow-up.
2. Placeholders and plurals use ICU syntax: `"itemsCount": "{count, plural, =0{No items} =1{1 item} other{{count} items}}"`, with `"@itemsCount": {"placeholders": {"count": {"type": "int"}}}`.
3. `generate: true` regenerates `AppLocalizations` on `flutter pub get` / `flutter run`. To refresh it right away, run `flutter gen-l10n`.
4. Use it: `Text(context.l10n.key)`. Never a string literal in a feature widget.

## 5. Reuse (rule 5, the Rule of 2)
- Second use of a widget → move it to `lib/utils/widgets/ui/`, parameterize the differences, export it from `lib/utils/widgets/ui/ui_components.dart`, and update both call sites.
- A reusable widget with its own behavior (like `AppTextFormField` or `AppDialog`) goes in `lib/utils/widgets/view/<component>/` with a small BLoC next to it.
- Only design-system primitives in `lib/utils/widgets/ui/` may hold purely visual state with `setState`.

## 6. Feedback and actions
- Buttons: `CommonButton(text: ..., onPressed: ..., loading: state is LoadingResponse<T>)`. It already shows a spinner and disables itself.
- Toasts: `ShowMessage.success/error/info/warning(...)`, triggered from a BLoC event (`.agents/skills/manage-state/bloc-recipes.md` recipe D), never from `build`.
- Dialogs: `AppDialog.showConfirmation(...)` (returns `bool?`), `AppDialog.showStatus(...)`, `AppDialog.showAsyncConfirm(...)` (runs the async call with its own spinner). Pass l10n strings for the labels; the defaults are English.
- Navigation: named routes through `Routes` (`Navigator.pushNamed`). After an `await`, check `mounted` before using `context`.

## 7. Accessibility and resilience
- Icon-only buttons get a `tooltip` or `Semantics(label: ...)`. Tap targets are at least 48×48.
- Text must survive 1.3× system scaling and Hindi strings about 30% longer than English: use `Flexible`/`Expanded`, `maxLines` + `TextOverflow.ellipsis`, and no fixed-height text boxes.
- Lists use `ListView.builder` (lazy). Pull to refresh needs a scrollable child even when the list is empty.

## 8. See it running
When a debug app is running and the `dart` MCP server is connected: `hot_reload` after edits, `get_runtime_errors` for overflows and exceptions, `widget_inspector` to check the tree. No running app → say the UI was verified by analyzer and tests only.

## 9. Verify and close out
Run `dart run scripts/agent/on_edit.dart` on touched files for sub-second feedback, then `dart run scripts/agent/verify.dart`. Add a widget test for content widgets with conditional UI (`.agents/skills/write-tests/SKILL.md`). For device flows, run `maestro test .maestro/flows/smoke_launch.yaml`. Close out per `AGENTS.md` §6. Record design decisions the next UI change must follow in `.claude/rules/ui.md` or `.harness/skills/build-ui.md`.
