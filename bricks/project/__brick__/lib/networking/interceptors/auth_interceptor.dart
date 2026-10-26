import 'package:dio/dio.dart';
import 'package:{{project_name}}/networking/api_constants.dart';
import 'package:{{project_name}}/redux/app_store.dart';

/// Interceptor #2 in the chain.
///
/// Reads [AppStore.authToken] and injects an
/// `Authorization: Bearer <token>` header — but only for requests to the
/// host in [ApiConstants.baseUrl]. Absolute URLs pointing at third-party
/// hosts (CDNs, analytics, presigned uploads) never receive the token.
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final token = AppStore.authToken;
    if (token != null && token.isNotEmpty && _isApiHost(options.uri)) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  static bool _isApiHost(Uri requestUri) {
    final apiUri = Uri.tryParse(ApiConstants.baseUrl);
    if (apiUri == null) return false;
    return requestUri.scheme == apiUri.scheme &&
        requestUri.host == apiUri.host &&
        requestUri.port == apiUri.port;
  }
}
