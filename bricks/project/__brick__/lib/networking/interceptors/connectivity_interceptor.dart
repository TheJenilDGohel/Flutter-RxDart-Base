import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:{{project_name}}/networking/api_exceptions.dart';

/// Interceptor #1 in the chain.
///
/// Checks device connectivity BEFORE firing the request. Throws
/// [NoInternetException] (via DioException.error) if the device is offline,
/// preventing unnecessary network calls.
class ConnectivityInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final result = await Connectivity().checkConnectivity();
    if (result.contains(ConnectivityResult.none)) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: const NoInternetException(),
        ),
      );
    }
    handler.next(options);
  }
}
