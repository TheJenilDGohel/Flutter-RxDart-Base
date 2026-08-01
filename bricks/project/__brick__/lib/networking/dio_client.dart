import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:{{project_name}}/networking/interceptors/connectivity_interceptor.dart';
import 'package:{{project_name}}/networking/interceptors/auth_interceptor.dart';
import 'package:{{project_name}}/networking/interceptors/platform_injector_interceptor.dart';
import 'package:{{project_name}}/networking/interceptors/error_mapping_interceptor.dart';
import 'package:{{project_name}}/networking/api_constants.dart';

/// Configures [Dio] with the interceptor chain.
///
/// Interceptor order matters — do not reorder:
/// 1. [ConnectivityInterceptor] — blocks requests when offline
/// 2. [AuthInterceptor] — injects Bearer token from AppStore
/// 3. [PlatformInjectorInterceptor] — injects {"platform": "app"}
/// 4. [RetryInterceptor] — retries on 502/503/timeout
/// 5. [ErrorMappingInterceptor] — maps DioException → ApiException
class DioClient {
  DioClient._();

  static Dio? _dio;

  /// Singleton Dio instance with the full interceptor chain configured.
  static Dio get instance {
    _dio ??= _createDio();
    return _dio!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    );

    // HTTP/2 adapter for improved performance
    dio.httpClientAdapter = Http2Adapter(
      ConnectionManager(idleTimeout: const Duration(seconds: 15)),
    );

    // ── Interceptor chain — ORDER MATTERS ──────────────────────────────
    dio.interceptors.addAll([
      // 1. Check connectivity before firing the request
      ConnectivityInterceptor(),

      // 2. Inject Authorization header from Redux store
      AuthInterceptor(),

      // 3. Inject {"platform": "app"} into JSON bodies
      PlatformInjectorInterceptor(),

      // 4. Retry on transient failures with exponential backoff
      RetryInterceptor(
        dio: dio,
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 4),
        ],
        retryableExtraStatuses: {502, 503},
      ),

      // 5. Map raw DioException into the sealed ApiException hierarchy
      ErrorMappingInterceptor(),
    ]);

    return dio;
  }
}
