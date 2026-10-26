# BLoC recipes

Contents: A Submit, B Live search, C Pagination, D One-off events, E Several loads, F Dependent calls, G Local UI state, H Timers.

Every recipe keeps the BLoC contract from `.agents/skills/manage-state/SKILL.md` §2. Names are examples: `my_app` is your package name, and repos and models are whatever `mason make bloc` generated for your feature. New l10n keys go into both ARB files.

## A. Submit (forms, create, update, delete)

The State owns the controllers and the `Form` key (rule 7). The BLoC owns the request, the busy state and the result.

```dart
import 'package:my_app/features/sign_in/model/session_model.dart';
import 'package:my_app/features/sign_in/repo/sign_in_repo.dart';
import 'package:my_app/networking/api_exceptions.dart';
import 'package:my_app/networking/api_response.dart';
import 'package:my_app/networking/cancel_token_owner.dart';
import 'package:rxdart/rxdart.dart';

final class SignInBloc with CancelTokenOwner {
  SignInBloc({SignInRepo? repo}) : _repo = repo ?? SignInRepo();

  final SignInRepo _repo;
  final CompositeSubscription subscriptions = CompositeSubscription();

  final BehaviorSubject<ApiResponse<SessionModel>> _submit =
      BehaviorSubject.seeded(const ApiResponse.initial());
  final PublishSubject<SessionModel> _signedIn = PublishSubject();

  /// Drives the button spinner and the error text.
  Stream<ApiResponse<SessionModel>> get submit$ => _submit.stream;

  /// Fires once per successful sign-in (recipe D).
  Stream<SessionModel> get signedIn$ => _signedIn.stream;

  Future<void> submit({required String email, required String password}) async {
    if (_submit.valueOrNull is LoadingResponse) return; // double tap
    final token = createNewToken();
    _emit(const ApiResponse.loading());
    try {
      final json = await _repo.signIn(
        body: {'email': email, 'password': password},
        cancelToken: token,
      );
      final session = SessionModel.fromJson(json);
      _emit(ApiResponse.completed(session));
      if (!_signedIn.isClosed) _signedIn.add(session);
    } on RequestCancelledException {
      // The screen was closed.
    } on ApiException catch (e) {
      _emit(ApiResponse.error(e)); // writes are not auto-retried
    } on Object catch (e) {
      _emit(ApiResponse.error(MalformedResponseException('SignIn: $e')));
    }
  }

  void _emit(ApiResponse<SessionModel> state) {
    if (!_submit.isClosed) _submit.add(state);
  }

  void dispose() {
    cancelRequests();
    subscriptions.dispose();
    _submit.close();
    _signedIn.close();
  }
}
```

Page state (no `setState`; the session goes to Redux after success, rule 10):

```dart
class SignInPageState extends State<SignInPage> {
  final _bloc = SignInBloc();
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final StreamSubscription<SessionModel> _signedIn;

  @override
  void initState() {
    super.initState();
    _signedIn = _bloc.signedIn$.listen((session) {
      if (!mounted) return;
      StoreProvider.of<AppState>(
        context,
        listen: false,
      ).dispatch(SetAuthTokenAction(session.token));
      Navigator.pushReplacementNamed(context, Routes.showcase);
    });
  }

  @override
  void dispose() {
    _signedIn.cancel();
    _bloc.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) return;
    _bloc.submit(email: _email.text.trim(), password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.signInTitle)),
      body: Form(
        key: _form,
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  (v ?? '').contains('@') ? null : context.l10n.invalidEmail,
            ),
            TextFormField(controller: _password, obscureText: true),
            SizedBox(height: 16.h),
            StreamBuilder<ApiResponse<SessionModel>>(
              stream: _bloc.submit$,
              builder: (context, snapshot) {
                final state = snapshot.data;
                return Column(
                  children: [
                    if (state is ErrorResponse<SessionModel>)
                      Text(
                        state.error.userFacingMessage(context),
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: ResColors.error,
                        ),
                      ),
                    CommonButton(
                      text: context.l10n.signIn,
                      loading: state is LoadingResponse<SessionModel>,
                      onPressed: _submit,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

- Format checks (empty, email shape) go in `validator`, using l10n strings. Server validation (422) arrives as `ValidationException`, and `userFacingMessage` shows its message.
- Several submit actions on one screen (save and delete): one state subject per action, sharing one `_busy` check if they must not overlap.
- Delete or pay: confirm first with `AppDialog.showConfirmation(...)`, or let `AppDialog.showAsyncConfirm` run the call and show its spinner.

## B. Live search

```dart
final class ProductSearchBloc with CancelTokenOwner {
  ProductSearchBloc({ProductSearchRepo? repo})
    : _repo = repo ?? ProductSearchRepo() {
    subscriptions.add(
      _query.stream
          .map((q) => q.trim())
          .debounceTime(const Duration(milliseconds: 300))
          .distinct()
          .listen(_search),
    );
  }

  final ProductSearchRepo _repo;
  final CompositeSubscription subscriptions = CompositeSubscription();
  final PublishSubject<String> _query = PublishSubject();
  final BehaviorSubject<ApiResponse<List<ProductModel>>> _results =
      BehaviorSubject.seeded(const ApiResponse.initial());

  Stream<ApiResponse<List<ProductModel>>> get results$ => _results.stream;

  /// Wire to `TextField.onChanged`.
  void search(String query) {
    if (!_query.isClosed) _query.add(query);
  }

  Future<void> _search(String query) async {
    final token = createNewToken(); // cancels the previous, now stale search
    if (query.isEmpty) {
      _emit(const ApiResponse.initial());
      return;
    }
    _emit(const ApiResponse.loading());
    try {
      final json = await _repo.search(query: query, cancelToken: token);
      if (token.isCancelled) return; // answered after a newer query started
      final items = (json['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ProductModel.fromJson)
          .toList();
      _emit(ApiResponse.completed(items));
    } on RequestCancelledException {
      // Superseded by a newer query.
    } on ApiException catch (e) {
      _emit(ApiResponse.error(e, retry: () => _search(query)));
    } on Object catch (e) {
      _emit(
        ApiResponse.error(
          MalformedResponseException('Search: $e'),
          retry: () => _search(query),
        ),
      );
    }
  }

  void _emit(ApiResponse<List<ProductModel>> state) {
    if (!_results.isClosed) _results.add(state);
  }

  void dispose() {
    cancelRequests();
    subscriptions.dispose();
    _query.close();
    _results.close();
  }
}
```

- `createNewToken()` comes before the empty-query check, so clearing the field also cancels the request in flight.
- The `isCancelled` check after `await` drops a response that arrived after a newer query began.
- An empty result is a `SuccessResponse` with an empty list. Render `AppEmptyState` for it in the content widget.

## C. Pagination (infinite scroll + pull to refresh)

One immutable value holds the list and its paging state. Errors on later pages keep the list on screen.

```dart
/// What the list screen shows. The BLoC replaces it on every change.
class PagedOrders {
  const PagedOrders({
    this.items = const [],
    this.nextPage = 1,
    this.hasMore = true,
    this.loadingMore = false,
    this.loadMoreError,
  });

  final List<OrderModel> items;
  final int nextPage;
  final bool hasMore;
  final bool loadingMore;
  final ApiException? loadMoreError;

  /// Appends one page. The paging fields follow your contract.
  PagedOrders append(Map<String, dynamic> json) {
    final more = (json['items'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(OrderModel.fromJson)
        .toList();
    return PagedOrders(
      items: [...items, ...more],
      nextPage: nextPage + 1,
      hasMore: json['has_more'] == true,
    );
  }

  PagedOrders copyWith({
    bool? loadingMore,
    ApiException? Function()? loadMoreError,
  }) => PagedOrders(
    items: items,
    nextPage: nextPage,
    hasMore: hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreError: loadMoreError != null ? loadMoreError() : this.loadMoreError,
  );
}
```

```dart
  final BehaviorSubject<ApiResponse<PagedOrders>> _page =
      BehaviorSubject.seeded(const ApiResponse.initial());

  Stream<ApiResponse<PagedOrders>> get page$ => _page.stream;

  /// First page, and pull to refresh.
  Future<void> fetch({bool refresh = false}) async {
    final token = createNewToken(); // also cancels a pending loadMore
    if (!(refresh && _page.valueOrNull is SuccessResponse)) {
      _emit(const ApiResponse.loading());
    }
    try {
      final json = await _repo.fetchOrders(page: 1, cancelToken: token);
      if (token.isCancelled) return;
      _emit(ApiResponse.completed(const PagedOrders().append(json)));
    } on RequestCancelledException {
      // Superseded or closed.
    } on ApiException catch (e) {
      _emit(ApiResponse.error(e, retry: fetch));
    } on Object catch (e) {
      _emit(
        ApiResponse.error(MalformedResponseException('Orders: $e'), retry: fetch),
      );
    }
  }

  /// Next page. Safe to call on every scroll notification.
  Future<void> loadMore() async {
    final current = _page.valueOrNull?.data;
    if (current == null || !current.hasMore || current.loadingMore) return;
    final token = cancelToken; // shared, so a refresh cancels this request
    final loading = current.copyWith(
      loadingMore: true,
      loadMoreError: () => null,
    );
    _emit(ApiResponse.completed(loading));
    try {
      final json = await _repo.fetchOrders(
        page: current.nextPage,
        cancelToken: token,
      );
      if (token.isCancelled || !_isShowing(loading)) return;
      _emit(ApiResponse.completed(current.append(json)));
    } on RequestCancelledException {
      // A refresh replaced the list.
    } on Object catch (e) {
      if (!_isShowing(loading)) return;
      final error = e is ApiException
          ? e
          : MalformedResponseException('Orders: $e');
      _emit(
        ApiResponse.completed(
          current.copyWith(loadingMore: false, loadMoreError: () => error),
        ),
      );
    }
  }

  /// False when a refresh replaced the list while a page was loading.
  bool _isShowing(PagedOrders page) => identical(_page.valueOrNull?.data, page);
```

Page and list (the State owns the `ScrollController`):

```dart
  late final OrdersBloc _bloc = OrdersBloc()..fetch();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final position = _scroll.position;
      if (position.pixels > position.maxScrollExtent - 300) _bloc.loadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _bloc.dispose();
    super.dispose();
  }

  // body:
  RefreshIndicator(
    onRefresh: () => _bloc.fetch(refresh: true),
    child: AppResponseBuilder<PagedOrders>(
      stream: _bloc.page$,
      builder: (context, page) => OrdersListWidget(
        page: page,
        controller: _scroll,
        onRetryMore: _bloc.loadMore,
      ),
    ),
  )
```

```dart
class OrdersListWidget extends StatelessWidget {
  const OrdersListWidget({
    super.key,
    required this.page,
    required this.controller,
    required this.onRetryMore,
  });

  final PagedOrders page;
  final ScrollController controller;
  final VoidCallback onRetryMore;

  @override
  Widget build(BuildContext context) {
    if (page.items.isEmpty) {
      return AppEmptyState(message: context.l10n.ordersEmpty);
    }
    return ListView.builder(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: page.items.length + (page.hasMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i < page.items.length) {
          return ListTile(title: Text(page.items[i].title));
        }
        if (page.loadMoreError != null) {
          return TextButton(
            onPressed: onRetryMore,
            child: Text(context.l10n.retryButton),
          );
        }
        return Padding(
          padding: EdgeInsets.all(16.w),
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
```

- `loadMore` reuses the current token instead of creating one, so it never cancels the first page, and a refresh does cancel it.
- `_isShowing` drops a page that comes back after a refresh has replaced the list.
- Cursor pagination: store `nextCursor` instead of `nextPage`, and set `hasMore` from whether the cursor is null.

## D. One-off events (toast, dialog, navigation)

A `PublishSubject` in the BLoC, subscribed in `initState()` and cancelled in `dispose()` (rule 9). Emit *what happened*, and let the page pick the l10n text:

```dart
enum CartEvent { added, removed }

  final PublishSubject<CartEvent> _events = PublishSubject();
  Stream<CartEvent> get events$ => _events.stream;
  void _notify(CartEvent event) {
    if (!_events.isClosed) _events.add(event);
  }
```

```dart
  late final StreamSubscription<CartEvent> _eventsSub;

  @override
  void initState() {
    super.initState();
    _eventsSub = _bloc.events$.listen((event) {
      if (!mounted) return;
      switch (event) {
        case CartEvent.added:
          ShowMessage.success(context.l10n.cartAdded);
        case CartEvent.removed:
          ShowMessage.info(context.l10n.cartRemoved);
      }
    });
  }
  // dispose(): _eventsSub.cancel(); before _bloc.dispose();
```

Never use a `BehaviorSubject` for events: it replays the last one to every new listener, so a rebuilt screen shows the toast again.

## E. Several loads on one screen

`CancelTokenOwner` holds **one** token. If two independent loaders each call `createNewToken()`, each cancels the other. Create the token once per screen load and pass it down, with one subject per section so each section fails and retries on its own:

```dart
  Future<void> fetch({bool refresh = false}) async {
    final token = createNewToken(); // one token for the whole screen load
    await Future.wait([
      _loadProfile(token, refresh: refresh),
      _loadStats(token, refresh: refresh),
    ]);
  }

  Future<void> _loadStats(CancelToken token, {bool refresh = false}) async {
    if (!(refresh && _stats.valueOrNull is SuccessResponse)) {
      _emitStats(const ApiResponse.loading());
    }
    try {
      final json = await _repo.fetchStats(cancelToken: token);
      _emitStats(ApiResponse.completed(StatsModel.fromJson(json)));
    } on RequestCancelledException {
      // Superseded or closed.
    } on ApiException catch (e) {
      // Retry just this section with the current token.
      _emitStats(ApiResponse.error(e, retry: () => _loadStats(cancelToken)));
    }
  }
```

Each section gets its own `AppResponseBuilder`. `CancelToken` comes from `package:dio/dio.dart`.

## F. Dependent calls

One token and one `try` when the screen needs both results:

```dart
    final token = createNewToken();
    _emit(const ApiResponse.loading());
    try {
      final order = OrderModel.fromJson(
        await _repo.fetchOrder(id, cancelToken: token),
      );
      final invoice = InvoiceModel.fromJson(
        await _repo.fetchInvoice(order.invoiceId, cancelToken: token),
      );
      _emit(ApiResponse.completed(OrderDetails(order, invoice)));
    } on RequestCancelledException {
      // Closed.
    } on ApiException catch (e) {
      _emit(ApiResponse.error(e, retry: fetch));
    }
```

If the screen can show the first result without the second, use two subjects as in recipe E.

## G. Local UI state (tabs, toggles, selection)

```dart
  final BehaviorSubject<int> _tab = BehaviorSubject.seeded(0);
  Stream<int> get tab$ => _tab.stream;
  int get currentTab => _tab.value; // for StreamBuilder.initialData
  void selectTab(int index) {
    if (!_tab.isClosed) _tab.add(index);
  }
```

```dart
StreamBuilder<int>(
  stream: _bloc.tab$,
  initialData: _bloc.currentTab,
  builder: (context, snapshot) => ...,
)
```

Flutter controllers (`TabController`, `AnimationController`, `PageController`) are owned and disposed by the State, like `TextEditingController`. They are not business state. Purely visual state inside a design-system primitive in `lib/utils/widgets/ui/` may use `setState` (rule 3); feature widgets may not.

## H. Timers and polling

```dart
  void startPolling() {
    subscriptions.add(
      Stream<void>.periodic(
        const Duration(seconds: 30),
      ).listen((_) => fetch(refresh: true)),
    );
  }
```

`subscriptions.dispose()` in `dispose()` stops it. Stop polling while the app is in the background: an `AppLifecycleListener` in the page State calls BLoC methods that cancel the subscription and start it again.
