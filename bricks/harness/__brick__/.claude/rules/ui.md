---
paths:
  - "lib/**/views/**/*.dart"
  - "lib/**/widgets/**/*.dart"
---

# UI & Presentation Layer Rules

These rules apply when viewing, editing, or generating UI widgets and views.

## Golden Rules for UI
1. **Zero `setState` in Feature Widgets**: Drive UI purely from streams via `AppResponseBuilder` or `StreamBuilder`.
2. **ScreenUtil Only in Public Widgets**: `.w`, `.h`, `.r`, and `.sp` inside private (`_Foo`) widgets do not rebuild on resize. Make layout widgets public.
3. **Design Tokens**:
   - Palette from `ResColors`.
   - Alpha channel transparency via `color.withValues(alpha: 0.5)`, never deprecated `withOpacity`.
4. **Error Presentation**:
   - Never display raw exceptions or `e.toString()`.
   - Use `error.userFacingMessage(context)` or rely on `AppResponseBuilder`.
5. **Controllers & Forms**:
   - `StatefulWidget` owns and disposes `TextEditingController` instances.
   - Values pass to BLoC methods on user input; BLoC streams drive button states and error banners.
6. **Rule of 2**:
   - Any widget reused in two or more places belongs in `lib/utils/widgets/ui/`.
7. **Scaffold Conventions**:
   - Standard `Scaffold` by default.
   - `AppScaffold` when shared chrome is required.
