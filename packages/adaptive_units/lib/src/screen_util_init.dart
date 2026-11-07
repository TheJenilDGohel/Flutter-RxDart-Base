import 'package:flutter/widgets.dart';

import 'screen_util.dart';

/// Builds [child] or [builder] with [ScreenUtil] set for the current window.
typedef ScreenUtilInitBuilder = Widget Function(
    BuildContext context, Widget? child);

/// Keeps [ScreenUtil] in step with the window and rebuilds the subtree when
/// a scale factor changes.
///
/// Place it above `MaterialApp` (or `WidgetsApp`):
/// ```dart
/// ScreenUtilInit(
///   designSize: const Size(375, 812),
///   minTextAdapt: true,
///   builder: (context, child) => MaterialApp(home: child),
///   child: const HomePage(),
/// )
/// ```
///
/// Unlike `flutter_screenutil`, a resize rebuilds private widgets (`_Card`)
/// too, and only when a factor actually changes: from [compactWidth] up the
/// factors stay 1, so resizing a tablet or desktop window rebuilds nothing
/// extra.
class ScreenUtilInit extends StatefulWidget {
  /// Creates the scope. Give [builder], [child] or both.
  const ScreenUtilInit({
    super.key,
    this.builder,
    this.child,
    this.designSize = ScreenUtil.defaultSize,
    this.splitScreenMode = false,
    this.minTextAdapt = false,
    this.compactWidth = ScreenUtil.defaultCompactWidth,
  }) : assert(builder != null || child != null, 'Give builder or child.');

  /// Builds the app; receives [child].
  final ScreenUtilInitBuilder? builder;

  /// Passed to [builder], or shown when there is no [builder].
  final Widget? child;

  /// The size the design was drawn at, in logical pixels.
  final Size designSize;

  /// Treat window heights under 700 as 700 (split screen, landscape phones).
  final bool splitScreenMode;

  /// Scale text by the smaller of the width and height factors.
  final bool minTextAdapt;

  /// Window width from which every factor is 1. `double.infinity` scales on
  /// every width, as `flutter_screenutil` does.
  final double compactWidth;

  @override
  State<ScreenUtilInit> createState() => _ScreenUtilInitState();
}

class _ScreenUtilInitState extends State<ScreenUtilInit> {
  bool _configured = false;

  @override
  Widget build(BuildContext context) {
    // Without a MediaQuery above, read the window the app is drawn in.
    if (MediaQuery.maybeSizeOf(context) == null) {
      return MediaQuery.fromView(
        view: View.of(context),
        child: Builder(builder: _scoped),
      );
    }
    return _scoped(context);
  }

  Widget _scoped(BuildContext context) {
    // Depend on the aspects ScreenUtil reads, not the whole MediaQuery, so
    // the keyboard opening does not rebuild the app.
    final size = MediaQuery.sizeOf(context);
    final data = MediaQueryData(
      size: size,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      padding: MediaQuery.paddingOf(context),
      textScaler: MediaQuery.textScalerOf(context),
    );
    final changed = ScreenUtil.configure(
      data: data,
      designSize: widget.designSize,
      splitScreenMode: widget.splitScreenMode,
      minTextAdapt: widget.minTextAdapt,
      compactWidth: widget.compactWidth,
    );
    if (changed && _configured) _rebuildDescendants();
    _configured = true;
    return widget.builder?.call(context, widget.child) ?? widget.child!;
  }

  /// `.w`/`.h`/`.r`/`.sp` read a value, not an inherited widget, so widgets
  /// that used them do not rebuild on their own. Mark every element below
  /// as dirty; this runs only when a factor changed.
  void _rebuildDescendants() {
    void mark(Element element) {
      element.markNeedsBuild();
      element.visitChildren(mark);
    }

    (context as Element).visitChildren(mark);
  }
}
