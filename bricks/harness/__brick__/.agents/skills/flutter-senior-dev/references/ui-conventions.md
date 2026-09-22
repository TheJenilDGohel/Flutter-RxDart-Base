# UI conventions reference

## Design tokens
- Colors: `ResColors` (`lib/resources/res_colors.dart`) — a fixed 20-token palette. Don't
  introduce a new `Color(0x...)` inline; add a token if something is genuinely missing.
- Type: `AppTypography` (`lib/resources/app_typography.dart`) — Material 3 type scale, already
  wired to ScreenUtil `.sp`. Access via `context.textTheme`, not by constructing `TextStyle`
  directly.
- Sizing: `flutter_screenutil` — `.w` (width), `.h` (height), `.r` (radius), `.sp` (font size).
  A hardcoded pixel value in a new widget is a review flag, not a style nit — it breaks on other
  screen sizes.

## Shared state widgets (`lib/utils/widgets/ui/`)
`AppLoadingState`, `AppErrorState`, `AppEmptyState` — use these for the non-`Completed` branches
of an `ApiResponse` switch instead of ad hoc `CircularProgressIndicator()`/`Text('error')` calls,
so loading/error/empty look consistent across the app. `AppScaffold` (`lib/utils/widgets/`) wraps
the standard screen chrome — use it instead of a bare `Scaffold` unless a screen has a real reason
not to (e.g. a full-bleed showcase/demo page).

## Localization
Strings come from `context.l10n`, backed by `lib/l10n/app_en.arb` / `app_hi.arb`. Add new strings
to both ARB files in the same change — don't ship an English-only string and leave Hindi to catch
up later.

## Navigation
Routes are registered in `lib/utils/router/routes.dart` and resolved through `AppRouter` — don't
use raw `Navigator.push(MaterialPageRoute(...))` for a screen that other features might need to
link to; register it as a named route. Use `dart run scripts/agent/wire_route.dart <name>` to
automate this.
