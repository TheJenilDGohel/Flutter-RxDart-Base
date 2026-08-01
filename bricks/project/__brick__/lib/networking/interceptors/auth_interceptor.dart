import 'package:dio/dio.dart';
import 'package:{{project_name}}/redux/app_store.dart';

/// Interceptor #2 in the chain.
///
/// Reads [AppStore.authToken] and injects an
/// `Authorization: Bearer <token>` header on every outgoing request.
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final token = AppStore.authToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
