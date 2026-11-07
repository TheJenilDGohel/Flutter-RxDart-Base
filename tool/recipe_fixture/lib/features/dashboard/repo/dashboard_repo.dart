import 'package:dio/dio.dart';
import 'package:recipe_app/networking/api_base_helper.dart';

class DashboardRepo {
  DashboardRepo({ApiBaseHelper? api}) : _api = api ?? ApiBaseHelper.instance;

  final ApiBaseHelper _api;

  Future<Map<String, dynamic>> fetchStats({CancelToken? cancelToken}) =>
      _api.get('/stats', cancelToken: cancelToken);

  Future<Map<String, dynamic>> fetchProfile({CancelToken? cancelToken}) =>
      _api.get('/me', cancelToken: cancelToken);
}
