import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{project_name}}/features/{{feature_name.snakeCase()}}/bloc/{{feature_name.snakeCase()}}_bloc.dart';
import 'package:{{project_name}}/features/{{feature_name.snakeCase()}}/model/{{feature_name.snakeCase()}}_model.dart';
import 'package:{{project_name}}/features/{{feature_name.snakeCase()}}/repo/{{feature_name.snakeCase()}}_repo.dart';
import 'package:{{project_name}}/networking/api_exceptions.dart';
import 'package:{{project_name}}/networking/api_response.dart';

/// Repo double: each call runs the next queued [responses] entry.
class Fake{{feature_name.pascalCase()}}Repo implements {{feature_name.pascalCase()}}Repo {
  final responses = <Future<Map<String, dynamic>> Function()>[];
  int calls = 0;

  @override
  Future<Map<String, dynamic>> fetch{{feature_name.pascalCase()}}({CancelToken? cancelToken}) {
    calls++;
    return responses.removeAt(0)();
  }
}

typedef _State = ApiResponse<{{feature_name.pascalCase()}}Model>;

void main() {
  late Fake{{feature_name.pascalCase()}}Repo repo;
  late {{feature_name.pascalCase()}}Bloc bloc;

  setUp(() {
    repo = Fake{{feature_name.pascalCase()}}Repo();
    bloc = {{feature_name.pascalCase()}}Bloc(repo: repo);
  });

  tearDown(() => bloc.dispose());

  test('starts in InitialResponse', () {
    expect(bloc.data$, emits(isA<InitialResponse<{{feature_name.pascalCase()}}Model>>()));
  });

  test('fetch emits loading then the parsed model', () async {
    repo.responses.add(() async => {'id': 1, 'name': 'Test'});
    final states = <_State>[];
    final sub = bloc.data$.listen(states.add);

    await bloc.fetch();
    await pumpEventQueue();

    expect(states, [
      isA<InitialResponse<{{feature_name.pascalCase()}}Model>>(),
      isA<LoadingResponse<{{feature_name.pascalCase()}}Model>>(),
      isA<SuccessResponse<{{feature_name.pascalCase()}}Model>>()
          .having((s) => s.data.id, 'id', '1')
          .having((s) => s.data.name, 'name', 'Test'),
    ]);
    await sub.cancel();
  });

  test('ApiException becomes ErrorResponse with a working retry', () async {
    repo.responses
      ..add(() async => throw const NotFoundException())
      ..add(() async => {'id': 2, 'name': 'Retried'});

    await bloc.fetch();
    final error = await bloc.data$.first;
    expect(error, isA<ErrorResponse<{{feature_name.pascalCase()}}Model>>());

    (error as ErrorResponse).retry!();
    await pumpEventQueue();
    expect(await bloc.data$.first, isA<SuccessResponse<{{feature_name.pascalCase()}}Model>>());
    expect(repo.calls, 2);
  });

  test('unexpected errors are wrapped, never shown raw', () async {
    repo.responses.add(() async => throw const FormatException('bad'));
    await bloc.fetch();
    final state = await bloc.data$.first;
    expect(
      state,
      isA<ErrorResponse<{{feature_name.pascalCase()}}Model>>().having(
        (s) => s.error,
        'error',
        isA<MalformedResponseException>(),
      ),
    );
  });

  test('cancellation is not reported as an error', () async {
    repo.responses.add(() async => throw const RequestCancelledException());
    await bloc.fetch();
    expect(await bloc.data$.first, isA<LoadingResponse<{{feature_name.pascalCase()}}Model>>());
  });

  test('refresh keeps current content visible', () async {
    repo.responses
      ..add(() async => {'id': 1, 'name': 'First'})
      ..add(() async => {'id': 1, 'name': 'Second'});
    await bloc.fetch();

    final states = <_State>[];
    final sub = bloc.data$.skip(1).listen(states.add);
    await bloc.fetch(refresh: true);
    await pumpEventQueue();

    expect(states.whereType<LoadingResponse<{{feature_name.pascalCase()}}Model>>(), isEmpty);
    expect(states.last.data?.name, 'Second');
    await sub.cancel();
  });

  test('no emission or crash after dispose', () async {
    final completer = Completer<Map<String, dynamic>>();
    repo.responses.add(() => completer.future);
    final pending = bloc.fetch();
    bloc.dispose();
    completer.complete({'id': 1, 'name': 'Late'});
    await expectLater(pending, completes);
    await expectLater(bloc.fetch, returnsNormally);
  });
}
