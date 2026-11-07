import 'package:recipe_app/features/orders/model/order_model.dart';
import 'package:recipe_app/features/orders/repo/orders_repo.dart';
import 'package:recipe_app/networking/api_exceptions.dart';
import 'package:recipe_app/networking/api_response.dart';
import 'package:recipe_app/networking/cancel_token_owner.dart';
import 'package:rxdart/rxdart.dart';

class InvoiceModel {
  const InvoiceModel(this.number);

  factory InvoiceModel.fromJson(Map<String, dynamic> json) =>
      InvoiceModel(json['number']?.toString() ?? '');

  final String number;
}

class OrderDetails {
  const OrderDetails(this.order, this.invoice);

  final OrderModel order;
  final InvoiceModel invoice;
}

final class OrderDetailBloc with CancelTokenOwner {
  OrderDetailBloc(this.id, {OrdersRepo? repo}) : _repo = repo ?? OrdersRepo();

  final String id;
  final OrdersRepo _repo;
  final BehaviorSubject<ApiResponse<OrderDetails>> _data =
      BehaviorSubject.seeded(const ApiResponse.initial());

  Stream<ApiResponse<OrderDetails>> get data$ => _data.stream;

  Future<void> fetch() async {
    // Recipe F.
    // recipe-block: 10
  }

  void _emit(ApiResponse<OrderDetails> state) {
    if (!_data.isClosed) _data.add(state);
  }

  void dispose() {
    cancelRequests();
    _data.close();
  }
}
