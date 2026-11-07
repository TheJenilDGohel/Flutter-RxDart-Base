import 'package:flutter/widgets.dart';

/// Material 3 window size classes, by window width in logical pixels (dp).
///
/// Lay out by class, not by device: a foldable or tablet in split screen can
/// be `compact`, and Android 16 lets every app resize on large screens.
/// ```dart
/// final columns = WindowSize.of(context).isCompact ? 1 : 2;
/// ```
enum WindowSize {
  /// Phones in portrait (< 600dp).
  compact,

  /// Small tablets, foldables unfolded, phones in landscape (600-839dp).
  medium,

  /// Tablets in landscape, desktop windows (840-1199dp).
  expanded,

  /// Large tablets and desktop (1200-1599dp).
  large,

  /// Ultra-wide desktop (>= 1600dp).
  extraLarge;

  /// The class of the current window. Rebuilds when the window resizes.
  static WindowSize of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  /// The class for a window [width] in dp.
  static WindowSize fromWidth(double width) => switch (width) {
    < 600 => compact,
    < 840 => medium,
    < 1200 => expanded,
    < 1600 => large,
    _ => extraLarge,
  };

  /// True for phone-portrait widths (the 375x812 design).
  bool get isCompact => this == compact;
}

/// Layout limits shared by the app shell and screens.
abstract final class AppBreakpoints {
  /// The phone design every `.w` / `.h` / `.sp` value is written against.
  /// `adaptive_units` scales it below 600dp (compact) and runs 1:1 above.
  static const Size phoneDesign = Size(375, 812);

  /// Widest readable column for forms, lists and text on large screens.
  static const double maxContentWidth = 840;
}
