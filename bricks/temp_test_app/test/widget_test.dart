import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redux/redux.dart';
import 'package:temp_test_app/main.dart';
import 'package:temp_test_app/redux/app_state.dart';
import 'package:temp_test_app/redux/reducers/app_reducer.dart';

void main() {
  testWidgets('App smoke test - verifies MyApp builds and mounts without errors',
      (WidgetTester tester) async {
    final store = Store<AppState>(
      appReducer,
      initialState: const AppState(),
    );

    await tester.pumpWidget(MyApp(store: store));
    await tester.pump();

    // Verify MaterialApp mounts with StoreProvider
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
