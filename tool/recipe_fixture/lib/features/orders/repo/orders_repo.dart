import 'package:dio/dio.dart';
import 'package:recipe_app/networking/api_base_helper.dart';

class OrdersRepo {
  OrdersRepo({ApiBaseHelper? api}) : _api = api ?? ApiBaseHelper.instance;

  final ApiBaseHelper _api;

  Future<Map<String, dynamic>> fetchOrders({
    required int page,
    CancelToken? cancelToken,
  }) =>
      _api.get(
        '/orders',
        queryParameters: {'page': page},
        cancelToken: cancelToken,
      );

  Future<Map<String, dynamic>> fetchOrder(
    String id, {
    CancelToken? cancelToken,
  }) =>
      _api.get('/orders/$id', cancelToken: cancelToken);

  Future<Map<String, dynamic>> fetchInvoice(
    String id, {
    CancelToken? cancelToken,
  }) =>
      _api.get('/invoices/$id', cancelToken: cancelToken);
}
