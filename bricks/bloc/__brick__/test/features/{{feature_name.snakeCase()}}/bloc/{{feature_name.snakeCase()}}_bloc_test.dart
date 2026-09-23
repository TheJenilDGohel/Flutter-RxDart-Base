import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:{{project_name}}/features/{{feature_name.snakeCase()}}/bloc/{{feature_name.snakeCase()}}_bloc.dart';
import 'package:{{project_name}}/features/{{feature_name.snakeCase()}}/model/{{feature_name.snakeCase()}}_model.dart';
import 'package:{{project_name}}/features/{{feature_name.snakeCase()}}/repo/{{feature_name.snakeCase()}}_repo.dart';
import 'package:{{project_name}}/networking/api_response.dart';

class Fake{{feature_name.pascalCase()}}Repo implements {{feature_name.pascalCase()}}Repo {
  @override
  Future<Map<String, dynamic>> fetch{{feature_name.pascalCase()}}Data({CancelToken? cancelToken}) async {
    return {'id': 1, 'name': 'Test'};
  }
}

void main() {
  group('{{feature_name.pascalCase()}}Bloc Tests', () {
    late Fake{{feature_name.pascalCase()}}Repo fakeRepo;
    late {{feature_name.pascalCase()}}Bloc bloc;

    setUp(() {
      fakeRepo = Fake{{feature_name.pascalCase()}}Repo();
      bloc = {{feature_name.pascalCase()}}Bloc(repo: fakeRepo);
    });

    tearDown(() {
      bloc.dispose();
    });

    test('initial state is correct', () {
      expect(bloc.data$, emits(isA<InitialResponse<{{feature_name.pascalCase()}}Model>>()));
    });
  });
}
