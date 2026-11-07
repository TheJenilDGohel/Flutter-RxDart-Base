# Changelog

## 0.1.0

- First release: `ScreenUtil`, `ScreenUtilInit` and the `.w` / `.h` / `.r` / `.sp` / `.dm` /
  `.dg` / `.sw` / `.sh` / `.spMin` / `.spMax` / `.verticalSpace` / `.horizontalSpace`
  getters, API-compatible with `flutter_screenutil`'s common surface.
- Scales below 600dp and stays 1:1 above (`compactWidth`, `double.infinity` to always scale).
- `minTextAdapt` applies to `.sp`; `splitScreenMode` floors heights at 700.
- Rebuilds private widgets on a resize, only when a scale factor changes; ignores keyboard
  insets.
- Depends on `package:flutter/widgets.dart` only.
