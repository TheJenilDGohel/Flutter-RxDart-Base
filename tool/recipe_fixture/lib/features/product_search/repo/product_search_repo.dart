import 'package:dio/dio.dart';
import 'package:recipe_app/networking/api_base_helper.dart';

class ProductSearchRepo {
  ProductSearchRepo({ApiBaseHelper? api})
      : _api = api ?? ApiBaseHelper.instance;

  final ApiBaseHelper _api;

  Future<Map<String, dynamic>> search({
    required String query,
    CancelToken? cancelToken,
  }) =>
      _api.get(
        '/products',
        queryParameters: {'q': query},
        cancelToken: cancelToken,
      );
}
