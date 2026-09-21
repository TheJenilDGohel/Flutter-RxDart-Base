import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name}}/features/{{feature_name.snakeCase()}}/bloc/{{feature_name.snakeCase()}}_bloc.dart';

void main() {
  group('{{feature_name.pascalCase()}}Bloc Tests', () {
    late {{feature_name.pascalCase()}}Bloc bloc;

    setUp(() {
      bloc = {{feature_name.pascalCase()}}Bloc();
    });

    tearDown(() {
      bloc.dispose();
    });

    test('initial state is correct', () {
      expect(bloc.data$.value.isInitial, isTrue);
    });
  });
}
