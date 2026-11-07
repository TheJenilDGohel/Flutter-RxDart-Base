import 'package:recipe_app/features/orders/model/paged_orders.dart';
import 'package:recipe_app/features/orders/repo/orders_repo.dart';
import 'package:recipe_app/networking/api_exceptions.dart';
import 'package:recipe_app/networking/api_response.dart';
import 'package:recipe_app/networking/cancel_token_owner.dart';
import 'package:rxdart/rxdart.dart';

final class OrdersBloc with CancelTokenOwner {
  OrdersBloc({OrdersRepo? repo}) : _repo = repo ?? OrdersRepo();

  final OrdersRepo _repo;
  final CompositeSubscription subscriptions = CompositeSubscription();

  // Recipe C, BLoC.
  // recipe-block: 4

  void _emit(ApiResponse<PagedOrders> state) {
    if (!_page.isClosed) _page.add(state);
  }

  void dispose() {
    cancelRequests();
    subscriptions.dispose();
    _page.close();
  }
}
