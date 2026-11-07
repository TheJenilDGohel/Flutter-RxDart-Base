# UI conventions reference

## Design tokens
- Colors: `ResColors` (`lib/resources/res_colors.dart`) — a fixed 20-token palette. Don't
  introduce a new `Color(0x...)` inline; add a token if something is genuinely missing.
  For opacity, use `ResColors.<color>.withValues(alpha: ...)` (Flutter 3.27+ standard) — avoid deprecated `.withOpacity()`.
- Type: `AppTypography` (`lib/resources/app_typography.dart`) — Material 3 type scale, already
  wired to ScreenUtil `.sp`. Access via `context.textTheme`, not by constructing `TextStyle`
  directly.
- Sizing: `flutter_screenutil` — `.w` (width), `.h` (height), `.r` (radius), `.sp` (font size).
  They scale the 375×812 design below 600dp and run 1:1 above it, where layouts branch on
  `WindowSize.of(context)` and wrap content in `AppContentWidth`. A raw pixel value is a review
  flag on phone layouts; plain dp is fine in shared widgets meant to outlive ScreenUtil
  (unreleased since 2024). Only use the units in **public** widgets: a private `_Foo` widget is not rebuilt on
  resize, and `no_screenutil_in_private_widget` fails the gate (rule 13).

## Shared state widgets (`lib/utils/widgets/ui/`)
`AppLoadingState`, `AppErrorState`, `AppEmptyState` — use these for the non-`SuccessResponse` branches
of an `ApiResponse` switch instead of ad hoc `CircularProgressIndicator()`/`Text('error')` calls,
so loading/error/empty look consistent across the app. `AppResponseBuilder` already wires all
three to an `ApiResponse` stream. Pages use a standard `Scaffold` by default (AGENTS.md rule 6);
`AppScaffold` (`lib/utils/widgets/ui/`) is there when you want the shared chrome.

## Localization
Strings come from `context.l10n`, backed by `lib/l10n/app_en.arb` / `app_hi.arb`. Add new strings
to both ARB files in the same change — don't ship an English-only string and leave Hindi to catch
up later.

## Navigation
Paths live in `lib/utils/router/routes.dart` and resolve through `AppRouter` (one `GoRouter`, so
deep links, App Links and web URLs open the same screens). Navigate with `context.push` /
`context.go`; carry ids in the path or query, not `extra`, so the screen also opens from a link.
Never `Navigator.push(MaterialPageRoute(...))` a screen other features might link to. Use
`dart run scripts/agent/wire_route.dart <name>` to add the constant and the `GoRoute`.
