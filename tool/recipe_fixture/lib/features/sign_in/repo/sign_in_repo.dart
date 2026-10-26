import 'package:dio/dio.dart';
import 'package:recipe_app/networking/api_base_helper.dart';

class SignInRepo {
  SignInRepo({ApiBaseHelper? api}) : _api = api ?? ApiBaseHelper.instance;

  final ApiBaseHelper _api;

  Future<Map<String, dynamic>> signIn({
    required Map<String, dynamic> body,
    CancelToken? cancelToken,
  }) =>
      _api.post('/auth/sign-in', data: body, cancelToken: cancelToken);
}
