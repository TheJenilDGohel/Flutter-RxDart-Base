import 'package:dio/dio.dart';

/// Interceptor #3 in the chain.
///
/// Injects `{"platform": "app"}` into JSON request bodies so the backend
/// can distinguish mobile app traffic from web/other clients.
class PlatformInjectorInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    if (options.data is Map<String, dynamic>) {
      (options.data as Map<String, dynamic>)['platform'] = 'app';
    }
    handler.next(options);
  }
}
