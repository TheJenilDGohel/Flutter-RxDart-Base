---
name: build-ui
description: Builds or changes Flutter UI in this Redux + RxDart app the house way - page/content-widget split, AppResponseBuilder states, ResColors and AppTypography tokens, ScreenUtil sizing in public widgets only, context.l10n strings in both ARB files, shared widgets under lib/utils/widgets/ui (Rule of 2), CommonButton, AppDialog, ShowMessage toasts and accessibility. Use for any widget, layout, styling, theming, string, dialog, toast, empty/error/loading state or "make it look like this design" request.
---

# Build UI

Widgets render state, they don't own it (rules 3, 4, 13 in `AGENTS.md` §2 are linted). Everything visual comes from tokens, so a design change touches one file. Work from the BLoC's public stream contract and model fields only, never raw JSON or test logs.

## 0. Load what this project learned
Read `.harness/skills/build-ui.md` if it exists (it wins over this file), run `dart scripts/agent/learn.dart list build-ui`, and check `lib/utils/widgets/ui/` first: the widget may exist.

## 1. Structure
- **Page** (`<name>_page.dart`, `StatefulWidget`): creates and disposes the BLoC and controllers, subscribes to one-off events, binds streams (rules 6, 7, 9).
- **Content widget** (`widgets/`): `StatelessWidget` taking parsed models and callbacks, never the BLoC or a `Stream`.
- **Binding**: `AppResponseBuilder<T>(stream: _bloc.data$, builder: ...)` does initial, loading and error + retry. Raw `StreamBuilder` only for non-`ApiResponse` streams, with `initialData` from the BLoC's sync getter.

## 2. Tokens
- **Colors**: `ResColors` (`lib/resources/res_colors.dart`); a missing color becomes a token, never inline `Color(0x...)`.
- **Text**: `context.textTheme.<style>` (`AppTypography`, already scaled) + `copyWith`; no `TextStyle` from scratch.
- **Imports**: `package:material_ui/material_ui.dart` for Material widgets (apps from project 2.1.0; older apps use `package:flutter/material.dart`, match the file around you) and `package:adaptive_units/adaptive_units.dart` for sizes.
- **Sizes**: `.w` widths and horizontal padding, `.h` heights and vertical gaps, `.r` radii, `.sp` fonts; design size 375×812 on phones. With `flutter_screenutil` (older apps), keep units in public widgets (rule 13).
- **Large screens**: from 600dp `adaptive_units` runs 1:1, so a phone layout is not blown up but is not adapted either. Branch on `WindowSize.of(context)` (Material 3 size classes, `lib/resources/app_breakpoints.dart`): one column on `compact`, list + detail or a grid from `medium`. Wrap forms, lists and text in `AppContentWidth`.

## 3. States
Loading and error + retry come from `AppResponseBuilder` (`AppLoadingState`, `AppErrorState`). Empty: `AppEmptyState(message: context.l10n.<key>)`, always with a message (the default is English). Inline action error: `Text(error.userFacingMessage(context))`.

## 4. Strings
Key in `lib/l10n/app_en.arb` (with `@key` description) and `lib/l10n/app_hi.arb`; a missing Hindi key is a bug. ICU plurals: `"{count, plural, =0{No items} =1{1 item} other{{count} items}}"` with a typed placeholder. `flutter gen-l10n` refreshes right away. No string literals in feature widgets.

## 5. Reuse (rule 5)
Second use → move to `lib/utils/widgets/ui/`, parameterize, export from `lib/utils/widgets/ui/ui_components.dart`, update both call sites. A shared widget with behavior (like `AppTextFormField`, `AppDialog`) goes in `lib/utils/widgets/view/<component>/` with its own small BLoC.

## 6. Feedback and actions
- `CommonButton(text: ..., onPressed: ..., loading: state is LoadingResponse<T>)` spins and disables itself.
- Toasts `ShowMessage.success/error/info/warning(...)` from a BLoC event (recipe D of `.agents/skills/manage-state/bloc-recipes.md`), never from `build`.
- `AppDialog.showConfirmation` (`bool?`), `showStatus`, `showAsyncConfirm` (own spinner); pass l10n labels.
- Navigation via `Routes` + `context.push` / `context.go` (`Navigator.pushNamed` in apps still on `onGenerateRoute`); check `mounted` after an `await`.

## 7. Accessibility and resilience
Icon-only buttons get a `tooltip` or `Semantics(label: ...)`; tap targets ≥ 48×48. Survive 1.3× text scale, ~30% longer Hindi and a resize to tablet width (Android 16 ignores orientation and resize locks there): `Flexible`/`Expanded`, `maxLines` + ellipsis, no fixed-height text boxes. `ListView.builder` for lists; pull to refresh needs a scrollable child even when empty.

## 8. Verify
With a running debug app and the `dart` MCP: `hot_reload`, `get_runtime_errors` (overflows), `widget_inspector`; otherwise say it was verified by analyzer and tests only. Widget test for conditional content (`.agents/skills/write-tests/SKILL.md`), then `verify.dart`. Design decisions the next change must follow go in `.claude/rules/ui.md` or `.harness/skills/build-ui.md`.
