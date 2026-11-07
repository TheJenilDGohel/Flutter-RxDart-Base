import 'package:material_ui/material_ui.dart';
import 'package:adaptive_units/adaptive_units.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redux/redux.dart';
import 'package:{{project_name}}/main.dart';
import 'package:{{project_name}}/redux/app_state.dart';
import 'package:{{project_name}}/redux/reducers/app_reducer.dart';
import 'package:{{project_name}}/resources/app_breakpoints.dart';

Store<AppState> _store() =>
    Store<AppState>(appReducer, initialState: const AppState());

void main() {
  testWidgets('App smoke test - verifies MyApp builds and mounts without errors',
      (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(store: _store()));
    await tester.pump();

    // Verify MaterialApp mounts with StoreProvider
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('ScreenUtil scales on phones and runs 1:1 from 600dp',
      (WidgetTester tester) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);

    await tester.pumpWidget(MyApp(store: _store()));
    await tester.pump();
    expect(ScreenUtil().scaleWidth, closeTo(412 / 375, 0.001));

    // Unfold / rotate / resize into a tablet-width window.
    tester.view.physicalSize = const Size(900, 1200);
    await tester.pump();
    expect(ScreenUtil().scaleWidth, 1.0);
    expect(ScreenUtil().scaleText, 1.0);
  });

  test('WindowSize follows the Material 3 window size classes', () {
    expect(WindowSize.fromWidth(599), WindowSize.compact);
    expect(WindowSize.fromWidth(600), WindowSize.medium);
    expect(WindowSize.fromWidth(840), WindowSize.expanded);
    expect(WindowSize.fromWidth(1200), WindowSize.large);
    expect(WindowSize.fromWidth(1600), WindowSize.extraLarge);
  });
}
