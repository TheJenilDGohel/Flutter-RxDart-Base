# adaptive_units

Write sizes against a phone design (`16.w`, `48.h`, `12.r`, `14.sp`). They scale on
compact windows (phones, under 600dp) and stay 1:1 from 600dp up, so tablets, foldables
and desktop windows get more room instead of a blown-up phone layout.

A drop-in for [`flutter_screenutil`](https://pub.dev/packages/flutter_screenutil): the
same `ScreenUtil`, `ScreenUtilInit` and `.w` / `.h` / `.r` / `.sp`, so an app moves by
swapping one import.

## Why not flutter_screenutil

| | `flutter_screenutil` 5.9.3 | `adaptive_units` |
|---|---|---|
| Imports | `package:flutter/material.dart` (breaks once Material leaves the framework) | `package:flutter/widgets.dart` only |
| Tablets and desktop | Scales every width unless you work around it | 1:1 from 600dp (Material 3 compact), configurable |
| `minTextAdapt` | Ignored by the default font resolver | `.sp` uses the smaller factor, as documented |
| Resize | Skips widgets named `_Private`, walks the tree on every size change | Rebuilds private widgets too, only when a factor changes |
| Keyboard | Rebuilds on `MediaQuery` changes | Depends on size, pixel ratio, padding and text scaler only |
| Logging | Prints to the console | Silent |

Flutter's own guidance is to lay out by available window size (`MediaQuery.sizeOf`,
`LayoutBuilder`, Material breakpoints) and to cap content width on large screens. Use
this package for the phone design's spacing and type, and branch layouts by window
size as usual.

## Usage

```dart
import 'package:adaptive_units/adaptive_units.dart';

void main() => runApp(
  ScreenUtilInit(
    designSize: const Size(375, 812), // the phone design
    minTextAdapt: true,
    builder: (context, child) => MaterialApp(home: child),
    child: const HomePage(),
  ),
);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(16.w),
    child: Text('Hello', style: TextStyle(fontSize: 18.sp)),
  );
}
```

| Getter | Scales by |
|---|---|
| `.w` | window width / design width |
| `.h` | window height / design height (`splitScreenMode`: heights under 700 count as 700) |
| `.r` | the smaller factor (radii, square sizes, icons) |
| `.sp` | width factor, or the smaller factor with `minTextAdapt`. `Text` still applies the OS text-size setting on top. |
| `.dm`, `.dg` | the larger factor, both factors |
| `.sw`, `.sh` | a fraction of the window (`0.5.sw`) |
| `.spMin`, `.spMax` | `.sp`, never above / below the design size |
| `.verticalSpace`, `.horizontalSpace` | a `SizedBox` of `.h` / `.w` |

`ScreenUtilInit(compactWidth: ...)` moves the 600dp limit; `double.infinity` scales on
every width, as `flutter_screenutil` does. `ScreenUtil()` exposes `scaleWidth`,
`scaleHeight`, `scaleText`, `scales`, `screenWidth`, `screenHeight`, `statusBarHeight`,
`bottomBarHeight`, `pixelRatio` and `textScaler`. `ScreenUtil.init(context)` sets it by
hand; before any setup every factor is 1.

## Moving from flutter_screenutil

1. Replace `flutter_screenutil` with `adaptive_units` in `pubspec.yaml`.
2. Replace `package:flutter_screenutil/flutter_screenutil.dart` with
   `package:adaptive_units/adaptive_units.dart`.
3. If you computed a design size per window to stop tablet scaling, pass the phone design
   instead: the 600dp limit is built in.
4. Not provided: `REdgeInsets`, `RPadding`, `RSizedBox` and the other `R` widgets,
   `fontSizeResolver`, `rebuildFactor`, `ensureScreenSize`. Use `EdgeInsets.all(8.w)` and
   plain widgets.

## Status

Built for the [Flutter-RxDart-Base](https://github.com/jenilseawind-glitch/Flutter-RxDart-Base)
project brick, which depends on it by git ref. Supports Flutter 3.16 and later; tested on
3.38 and 3.47.
