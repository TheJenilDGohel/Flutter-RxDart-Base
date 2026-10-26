# UI conventions reference

## Design tokens
- Colors: `ResColors` (`lib/resources/res_colors.dart`) — a fixed 20-token palette. Don't
  introduce a new `Color(0x...)` inline; add a token if something is genuinely missing.
  For opacity, use `ResColors.<color>.withValues(alpha: ...)` (Flutter 3.27+ standard) — avoid deprecated `.withOpacity()`.
- Type: `AppTypography` (`lib/resources/app_typography.dart`) — Material 3 type scale, already
  wired to ScreenUtil `.sp`. Access via `context.textTheme`, not by constructing `TextStyle`
  directly.
- Sizing: `flutter_screenutil` — `.w` (width), `.h` (height), `.r` (radius), `.sp` (font size).
  A hardcoded pixel value in a new widget is a review flag, not a style nit — it breaks on other
  screen sizes. Only use these in **public** widgets: a private `_Foo` widget is not rebuilt on
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
Routes are registered in `lib/utils/router/routes.dart` and resolved through `AppRouter` — don't
use raw `Navigator.push(MaterialPageRoute(...))` for a screen that other features might need to
link to; register it as a named route. Use `dart run scripts/agent/wire_route.dart <name>` to
automate this.
