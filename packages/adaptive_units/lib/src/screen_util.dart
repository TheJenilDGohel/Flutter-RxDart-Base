import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Scales sizes written against a phone design to the current window.
///
/// Same API as `flutter_screenutil` (`ScreenUtil()`, `.w`, `.h`, `.r`, `.sp`),
/// with the adaptive policy built in: below [compactWidth] (600dp, Material 3
/// compact) sizes scale with the window; from [compactWidth] up every factor
/// is 1, so a tablet or desktop window gets more room instead of a blown-up
/// phone layout.
///
/// [ScreenUtilInit] keeps it current; [ScreenUtil.init] sets it by hand
/// (tests, or apps without the widget). Before either runs, every factor is 1.
final class ScreenUtil {
  /// The one instance; the `.w` / `.h` / `.r` / `.sp` getters read it.
  factory ScreenUtil() => _instance;

  ScreenUtil._();

  static final ScreenUtil _instance = ScreenUtil._();

  /// Design size used when none is given.
  static const Size defaultSize = Size(360, 690);

  /// Material 3 compact limit: sizes scale below this window width.
  static const double defaultCompactWidth = 600;

  MediaQueryData? _data;
  Size _designSize = defaultSize;
  bool _minTextAdapt = false;
  bool _splitScreenMode = false;
  double _compactWidth = defaultCompactWidth;

  /// Sets the window [data] and options by hand. Prefer [ScreenUtilInit],
  /// which also rebuilds the tree when the scale changes.
  static void init(
    BuildContext context, {
    Size designSize = defaultSize,
    bool splitScreenMode = false,
    bool minTextAdapt = false,
    double compactWidth = defaultCompactWidth,
  }) {
    configure(
      data: MediaQuery.of(context),
      designSize: designSize,
      splitScreenMode: splitScreenMode,
      minTextAdapt: minTextAdapt,
      compactWidth: compactWidth,
    );
  }

  /// Applies [data] and the options. Returns true when a scale factor
  /// changed, which is when widgets built with `.w`/`.h`/`.r`/`.sp` need a
  /// rebuild.
  static bool configure({
    required MediaQueryData data,
    Size? designSize,
    bool? splitScreenMode,
    bool? minTextAdapt,
    double? compactWidth,
  }) {
    final before = _instance._factors;
    _instance
      .._data = data
      .._designSize = designSize ?? _instance._designSize
      .._splitScreenMode = splitScreenMode ?? _instance._splitScreenMode
      .._minTextAdapt = minTextAdapt ?? _instance._minTextAdapt
      .._compactWidth = compactWidth ?? _instance._compactWidth;
    return _instance._factors != before;
  }

  /// Forgets the window and options, back to the defaults (factors of 1).
  /// For tests.
  @visibleForTesting
  static void reset() {
    _instance
      .._data = null
      .._designSize = defaultSize
      .._splitScreenMode = false
      .._minTextAdapt = false
      .._compactWidth = defaultCompactWidth;
  }

  (double, double, double) get _factors => (scaleWidth, scaleHeight, scaleText);

  /// The design size sizes are written against.
  Size get designSize => _designSize;

  /// Window width below which sizes scale (`double.infinity`: always).
  double get compactWidth => _compactWidth;

  /// True when the window is narrower than [compactWidth], so sizes scale.
  bool get scales => _data != null && screenWidth < _compactWidth;

  /// Window width in logical pixels.
  double get screenWidth => _data?.size.width ?? _designSize.width;

  /// Window height in logical pixels.
  double get screenHeight => _data?.size.height ?? _designSize.height;

  /// Physical pixels per logical pixel.
  double get pixelRatio => _data?.devicePixelRatio ?? 1;

  /// Top system inset (status bar), in logical pixels.
  double get statusBarHeight => _data?.padding.top ?? 0;

  /// Bottom system inset (navigation bar), in logical pixels.
  double get bottomBarHeight => _data?.padding.bottom ?? 0;

  /// The OS text-size setting. `Text` applies it on top of `.sp`.
  TextScaler get textScaler => _data?.textScaler ?? TextScaler.noScaling;

  /// Portrait or landscape, from the window size.
  Orientation get orientation =>
      screenWidth > screenHeight ? Orientation.landscape : Orientation.portrait;

  /// Width factor: window width / design width below [compactWidth], else 1.
  double get scaleWidth => scales ? screenWidth / _designSize.width : 1;

  /// Height factor: window height / design height below [compactWidth],
  /// else 1. With `splitScreenMode`, heights under 700 count as 700.
  double get scaleHeight {
    if (!scales) return 1;
    final height =
        _splitScreenMode ? math.max(screenHeight, 700) : screenHeight;
    return height / _designSize.height;
  }

  /// Text factor: the smaller of [scaleWidth] and [scaleHeight] with
  /// `minTextAdapt`, else [scaleWidth].
  double get scaleText =>
      _minTextAdapt ? math.min(scaleWidth, scaleHeight) : scaleWidth;

  /// [width] scaled by [scaleWidth].
  double setWidth(num width) => width * scaleWidth;

  /// [height] scaled by [scaleHeight].
  double setHeight(num height) => height * scaleHeight;

  /// [r] scaled by the smaller factor (radii, square sizes, icons).
  double radius(num r) => r * math.min(scaleWidth, scaleHeight);

  /// [d] scaled by the larger factor.
  double diameter(num d) => d * math.max(scaleWidth, scaleHeight);

  /// [d] scaled by both factors.
  double diagonal(num d) => d * scaleHeight * scaleWidth;

  /// Font size [fontSize] scaled by [scaleText]. The OS text scaler is not
  /// applied here: `Text` applies it, so it is never applied twice.
  double setSp(num fontSize) => fontSize * scaleText;
}
