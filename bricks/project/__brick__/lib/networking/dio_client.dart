import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:{{project_name}}/networking/interceptors/auth_interceptor.dart';
import 'package:{{project_name}}/networking/interceptors/platform_injector_interceptor.dart';
import 'package:{{project_name}}/networking/interceptors/error_mapping_interceptor.dart';
import 'package:{{project_name}}/networking/api_constants.dart';
import 'package:{{project_name}}/networking/api_exceptions.dart';

/// Configures [Dio] with the interceptor chain.
///
/// Interceptor order matters — do not reorder:
/// 1. [AuthInterceptor] — injects Bearer token from AppStore
/// 2. [PlatformInjectorInterceptor] — injects {"platform": "app"}
/// 3. [RetryInterceptor] — retries idempotent requests on transient failures
/// 4. [ErrorMappingInterceptor] — maps DioException → ApiException
///
/// Offline is detected when a request fails to connect (mapped to
/// [NoInternetException]), not by a pre-check: an interface check costs a
/// platform call per request and is wrong behind captive portals and VPNs.
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

    // Dio's default dart:io adapter: streams uploads (real onSendProgress),
    // supports certificate pinning (IOHttpClientAdapter.validateCertificate)
    // and needs no native plugin. For HTTP/3, the system VPN/proxy or
    // user-installed certificates, see recipe I in
    // .agents/skills/add-endpoint/repo-recipes.md (native adapter, opt-in).

    // ── Interceptor chain — ORDER MATTERS ──────────────────────────────
    dio.interceptors.addAll([
      // 1. Inject Authorization header from Redux store
      AuthInterceptor(),

      // 2. Inject {"platform": "app"} into JSON bodies
      PlatformInjectorInterceptor(),

      // 3. Retry transient failures with exponential backoff. POST/PATCH
      //    are never retried: replaying them can duplicate side effects.
      RetryInterceptor(
        dio: dio,
        retries: 2,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 3),
        ],
        retryEvaluator: _shouldRetry,
      ),

      // 4. Map raw DioException into the sealed ApiException hierarchy
      ErrorMappingInterceptor(),
    ]);

    return dio;
  }

  static const _idempotentMethods = {'GET', 'HEAD', 'OPTIONS', 'PUT', 'DELETE'};
  static final _defaultEvaluator =
      DefaultRetryEvaluator(defaultRetryableStatuses);

  static FutureOr<bool> _shouldRetry(DioException error, int attempt) {
    if (error.error is ApiException) return false;
    final method = error.requestOptions.method.toUpperCase();
    if (!_idempotentMethods.contains(method)) return false;
    return _defaultEvaluator.evaluate(error, attempt);
  }
}
