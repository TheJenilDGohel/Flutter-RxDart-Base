import 'dart:math' as math;

import 'package:adaptive_units/adaptive_units.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _design = Size(375, 812);

MediaQueryData _window(
  double width,
  double height, {
  TextScaler textScaler = TextScaler.noScaling,
}) =>
    MediaQueryData(size: Size(width, height), textScaler: textScaler);

int _probeBuilds = 0;

/// Private and const: only ScreenUtilInit's rebuild can refresh it.
class _Probe extends StatelessWidget {
  const _Probe();

  @override
  Widget build(BuildContext context) {
    _probeBuilds++;
    return Text(
      100.w.toStringAsFixed(1),
      textDirection: TextDirection.ltr,
    );
  }
}

void main() {
  setUp(() {
    ScreenUtil.reset();
    _probeBuilds = 0;
  });

  group('ScreenUtil', () {
    test('every factor is 1 before init', () {
      final su = ScreenUtil();
      expect(su.scales, isFalse);
      expect([su.scaleWidth, su.scaleHeight, su.scaleText], [1, 1, 1]);
      expect(16.w, 16);
      expect(14.sp, 14);
    });

    test('a compact window scales width, height, radius and text', () {
      ScreenUtil.configure(data: _window(412, 915), designSize: _design);
      final su = ScreenUtil();
      const sw = 412 / 375;
      const sh = 915 / 812;
      expect(su.scales, isTrue);
      expect(su.scaleWidth, closeTo(sw, 1e-9));
      expect(su.scaleHeight, closeTo(sh, 1e-9));
      expect(100.w, closeTo(100 * sw, 1e-9));
      expect(100.h, closeTo(100 * sh, 1e-9));
      expect(10.r, closeTo(10 * math.min(sw, sh), 1e-9));
      expect(10.dm, closeTo(10 * math.max(sw, sh), 1e-9));
      expect(10.dg, closeTo(10 * sw * sh, 1e-9));
      expect(14.sp, closeTo(14 * sw, 1e-9));
    });

    test('from compactWidth up every factor is 1', () {
      for (final size in [const Size(600, 960), const Size(1280, 800)]) {
        ScreenUtil.configure(
          data: _window(size.width, size.height),
          designSize: _design,
        );
        expect(ScreenUtil().scales, isFalse, reason: '$size');
        expect(100.w, 100, reason: '$size');
        expect(100.h, 100, reason: '$size');
        expect(14.sp, 14, reason: '$size');
      }
    });

    test('compactWidth infinity scales on every width', () {
      ScreenUtil.configure(
        data: _window(1280, 800),
        designSize: _design,
        compactWidth: double.infinity,
      );
      expect(100.w, closeTo(100 * 1280 / 375, 1e-9));
    });

    test('minTextAdapt scales text by the smaller factor', () {
      // A short compact window: the height factor is the smaller one.
      ScreenUtil.configure(data: _window(500, 400), designSize: _design);
      expect(14.sp, closeTo(14 * 500 / 375, 1e-9));

      ScreenUtil.configure(data: _window(500, 400), minTextAdapt: true);
      expect(14.sp, closeTo(14 * 400 / 812, 1e-9));
    });

    test('splitScreenMode treats heights under 700 as 700', () {
      ScreenUtil.configure(
        data: _window(400, 500),
        designSize: _design,
        splitScreenMode: true,
      );
      expect(ScreenUtil().scaleHeight, closeTo(700 / 812, 1e-9));
    });

    test('.sp leaves the OS text scaler to Text', () {
      ScreenUtil.configure(
        data: _window(412, 915, textScaler: const TextScaler.linear(2)),
        designSize: _design,
      );
      expect(14.sp, closeTo(14 * 412 / 375, 1e-9));
      expect(ScreenUtil().textScaler, const TextScaler.linear(2));
    });

    test('configure reports whether a factor changed', () {
      expect(
        ScreenUtil.configure(data: _window(412, 915), designSize: _design),
        isTrue,
      );
      expect(ScreenUtil.configure(data: _window(412, 915)), isFalse);
      expect(ScreenUtil.configure(data: _window(390, 844)), isTrue);
      // Two non-compact windows: all factors stay 1.
      expect(ScreenUtil.configure(data: _window(900, 1200)), isTrue);
      expect(ScreenUtil.configure(data: _window(1200, 900)), isFalse);
    });

    test('spMin, spMax, sw, sh and spaces', () {
      ScreenUtil.configure(data: _window(300, 650), designSize: _design);
      expect(14.spMin, closeTo(14 * 300 / 375, 1e-9));
      expect(14.spMax, 14);
      expect(0.5.sw, 150);
      expect(0.5.sh, 325);
      expect(10.verticalSpace.height, closeTo(10 * 650 / 812, 1e-9));
      expect(10.horizontalSpace.width, closeTo(10 * 300 / 375, 1e-9));
    });
  });

  group('ScreenUtilInit', () {
    void setWindow(WidgetTester tester, Size size) {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = size;
    }

    testWidgets('rebuilds private const widgets when a factor changes', (
      tester,
    ) async {
      addTearDown(tester.view.reset);
      setWindow(tester, const Size(412, 915));
      await tester.pumpWidget(
        const ScreenUtilInit(designSize: _design, child: _Probe()),
      );
      expect(find.text((100 * 412 / 375).toStringAsFixed(1)), findsOneWidget);

      setWindow(tester, const Size(360, 800));
      await tester.pump();
      expect(find.text((100 * 360 / 375).toStringAsFixed(1)), findsOneWidget);
    });

    testWidgets('resizing non-compact windows rebuilds nothing extra', (
      tester,
    ) async {
      addTearDown(tester.view.reset);
      setWindow(tester, const Size(900, 1200));
      await tester.pumpWidget(
        const ScreenUtilInit(designSize: _design, child: _Probe()),
      );
      expect(_probeBuilds, 1);
      expect(find.text('100.0'), findsOneWidget);

      setWindow(tester, const Size(1100, 1300));
      await tester.pump();
      expect(_probeBuilds, 1, reason: 'factors stayed 1');

      setWindow(tester, const Size(412, 915));
      await tester.pump();
      expect(_probeBuilds, 2);
      expect(find.text((100 * 412 / 375).toStringAsFixed(1)), findsOneWidget);
    });

    testWidgets('reads a MediaQuery above it, and ignores keyboard insets', (
      tester,
    ) async {
      var appBuilds = 0;
      // One instance, as in an app: only the MediaQuery above it changes.
      final init = ScreenUtilInit(
        designSize: _design,
        minTextAdapt: true,
        builder: (context, child) {
          appBuilds++;
          return child!;
        },
        child: const _Probe(),
      );
      Widget app(EdgeInsets viewInsets) => MediaQuery(
            data: MediaQueryData(
              size: const Size(412, 915),
              viewInsets: viewInsets,
            ),
            child: init,
          );

      await tester.pumpWidget(app(EdgeInsets.zero));
      expect(appBuilds, 1);
      expect(ScreenUtil().scaleText, closeTo(412 / 375, 1e-9));

      await tester.pumpWidget(app(const EdgeInsets.only(bottom: 300)));
      expect(appBuilds, 1, reason: 'the keyboard does not resize the design');
    });

    testWidgets('builder receives child', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          builder: (context, child) => Directionality(
            textDirection: TextDirection.ltr,
            child: child!,
          ),
          child: const Text('child'),
        ),
      );
      expect(find.text('child'), findsOneWidget);
    });
  });
}
