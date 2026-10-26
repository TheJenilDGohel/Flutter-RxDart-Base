// Behavior tests for the BLoC recipes in the harness's manage-state skill
// and the test snippets in its write-tests skill. Run by tool/smoke.dart.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:recipe_app/features/dashboard/repo/dashboard_repo.dart';
import 'package:recipe_app/features/orders/bloc/orders_bloc.dart';
import 'package:recipe_app/features/orders/model/order_model.dart';
import 'package:recipe_app/features/orders/model/paged_orders.dart';
import 'package:recipe_app/features/orders/repo/orders_repo.dart';
import 'package:recipe_app/features/orders/widgets/orders_list_widget.dart';
import 'package:recipe_app/features/product_search/bloc/product_search_bloc.dart';
import 'package:recipe_app/features/product_search/repo/product_search_repo.dart';
import 'package:recipe_app/features/sign_in/bloc/sign_in_bloc.dart';
import 'package:recipe_app/features/sign_in/repo/sign_in_repo.dart';
import 'package:recipe_app/l10n/generated/app_localizations.dart';
import 'package:recipe_app/networking/api_constants.dart';
import 'package:recipe_app/networking/api_exceptions.dart';
import 'package:recipe_app/networking/api_response.dart';

typedef Respond = Future<Map<String, dynamic>> Function();

class FakeSignInRepo implements SignInRepo {
  final responses = <Respond>[];
  int calls = 0;
  @override
  Future<Map<String, dynamic>> signIn({
    required Map<String, dynamic> body,
    CancelToken? cancelToken,
  }) {
    calls++;
    return responses.removeAt(0)();
  }
}

class FakeSearchRepo implements ProductSearchRepo {
  final queries = <String>[];
  @override
  Future<Map<String, dynamic>> search({
    required String query,
    CancelToken? cancelToken,
  }) async {
    queries.add(query);
    return {
      'items': [
        {'id': 1, 'name': query},
      ],
    };
  }
}

class FakeOrdersRepo implements OrdersRepo {
  final responses = <Respond>[];
  final pages = <int>[];
  @override
  Future<Map<String, dynamic>> fetchOrders({
    required int page,
    CancelToken? cancelToken,
  }) {
    pages.add(page);
    return responses.removeAt(0)();
  }

  @override
  Future<Map<String, dynamic>> fetchOrder(
    String id, {
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> fetchInvoice(
    String id, {
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();
}

class FakeDashboardRepo implements DashboardRepo {
  final stats = <Respond>[];
  @override
  Future<Map<String, dynamic>> fetchStats({CancelToken? cancelToken}) =>
      stats.removeAt(0)();
  @override
  Future<Map<String, dynamic>> fetchProfile({CancelToken? cancelToken}) async =>
      {'name': 'Asha'};
}

Map<String, dynamic> page(List<String> titles, {bool hasMore = true}) => {
      'items': [
        for (final t in titles) {'title': t},
      ],
      'has_more': hasMore,
    };

void main() {
  test('A. a second submit while loading makes no second call', () async {
    final repo = FakeSignInRepo();
    final bloc = SignInBloc(repo: repo);
    final done = Completer<Map<String, dynamic>>();
    repo.responses.add(() => done.future);
    final events = <Object>[];
    final sub = bloc.signedIn$.listen(events.add);

    final first = bloc.submit(email: 'a@b.c', password: 'x');
    await bloc.submit(email: 'a@b.c', password: 'x');
    done.complete({'token': 't1'});
    await first;
    await pumpEventQueue();

    expect(repo.calls, 1);
    expect(await bloc.submit$.first, isA<SuccessResponse<Object?>>());
    expect(events, hasLength(1));
    await sub.cancel();
    bloc.dispose();
  });

  test('A. errors are not auto-retried', () async {
    final repo = FakeSignInRepo()
      ..responses.add(() async => throw const ValidationException('Bad'));
    final bloc = SignInBloc(repo: repo);
    await bloc.submit(email: 'a@b.c', password: 'x');
    final state = await bloc.submit$.first;
    expect(state, isA<ErrorResponse<Object?>>());
    expect((state as ErrorResponse).retry, isNull);
    bloc.dispose();
  });

  test('B. fast typing makes one request, for the last query', () async {
    final repo = FakeSearchRepo();
    final bloc = ProductSearchBloc(repo: repo)
      ..search('a')
      ..search('ab')
      ..search('abc ');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await pumpEventQueue();
    expect(repo.queries, ['abc']);
    final state = await bloc.results$.first;
    expect(state.data?.single.name, 'abc');

    bloc.search('');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(await bloc.results$.first, isA<InitialResponse<Object?>>());
    bloc.dispose();
  });

  test('C. a failed loadMore keeps the list and can be retried', () async {
    final repo = FakeOrdersRepo()
      ..responses.addAll([
        () async => page(['a', 'b']),
        () async => throw const InternalServerErrorException(),
        () async => page(['c'], hasMore: false),
      ]);
    final bloc = OrdersBloc(repo: repo);
    await bloc.fetch();
    await bloc.loadMore();
    var current = (await bloc.page$.first).data!;
    expect(current.items.map((o) => o.title), ['a', 'b']);
    expect(current.loadMoreError, isA<InternalServerErrorException>());
    expect(current.loadingMore, isFalse);

    await bloc.loadMore();
    current = (await bloc.page$.first).data!;
    expect(current.items.map((o) => o.title), ['a', 'b', 'c']);
    expect(current.hasMore, isFalse);
    expect(repo.pages, [1, 2, 2]);

    await bloc.loadMore(); // no more pages: no request
    expect(repo.pages, [1, 2, 2]);
    bloc.dispose();
  });

  test('C. a refresh during loadMore wins', () async {
    final slowPage2 = Completer<Map<String, dynamic>>();
    final repo = FakeOrdersRepo()
      ..responses.addAll([
        () async => page(['a']),
        () => slowPage2.future,
        () async => page(['fresh']),
      ]);
    final bloc = OrdersBloc(repo: repo);
    await bloc.fetch();
    final more = bloc.loadMore();
    await bloc.fetch(refresh: true);
    slowPage2.complete(page(['stale']));
    await more;
    await pumpEventQueue();
    final current = (await bloc.page$.first).data!;
    expect(current.items.map((o) => o.title), ['fresh']);
    bloc.dispose();
  });

  test(
    'E. one failing section leaves the other loaded; retry fixes it',
    () async {
      final repo = FakeDashboardRepo()
        ..stats.addAll([
          () async => throw const NotFoundException(),
          () async => {'count': 3},
        ]);
      final bloc = DashboardBloc(repo: repo);
      await bloc.fetch();
      expect(await bloc.profile$.first, isA<SuccessResponse<Object?>>());
      final stats = await bloc.stats$.first;
      expect(stats, isA<ErrorResponse<Object?>>());
      (stats as ErrorResponse).retry!();
      await pumpEventQueue();
      expect((await bloc.stats$.first).data?.count, 3);
      bloc.dispose();
    },
  );

  test('G. tab state with a sync getter', () async {
    final bloc = DashboardBloc(repo: FakeDashboardRepo())..selectTab(2);
    expect(bloc.currentTab, 2);
    bloc.dispose();
  });

  // ── write-tests skill snippets, as written ────────────────────────────
  Widget harness(Widget child) => ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
      );

  testWidgets('shows the order title', (tester) async {
    const paged = PagedOrders(
      items: [OrderModel(title: 'First order')],
      hasMore: false,
    );
    await tester.pumpWidget(
      harness(
        OrdersListWidget(
          page: paged,
          controller: ScrollController(),
          onRetryMore: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('First order'), findsOneWidget);
  });

  test('dotenv.loadFromString makes ApiConstants usable in tests', () {
    dotenv.loadFromString(envString: 'BASE_URL=https://api.test');
    expect(ApiConstants.baseUrl, 'https://api.test');
  });
}
