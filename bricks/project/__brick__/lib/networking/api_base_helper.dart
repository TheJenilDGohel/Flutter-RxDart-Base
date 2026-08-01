import 'package:dio/dio.dart';
import 'package:{{project_name}}/networking/api_exceptions.dart';
import 'package:{{project_name}}/networking/dio_client.dart';

/// Facade class exposing get/post/put/delete.
///
/// Has a static [instance] singleton BUT is also constructible directly
/// (not a hard static-only singleton) so it can be injected into repos
/// for tests:
///
/// ```dart
/// // Production (default)
/// final repo = MyRepo(); // uses ApiBaseHelper.instance
///
/// // Test
/// final repo = MyRepo(api: MockApiBaseHelper());
/// ```
class ApiBaseHelper {
  ApiBaseHelper({Dio? dio}) : _dio = dio ?? DioClient.instance;

  static ApiBaseHelper? _instance;

  /// Singleton instance. Initialized lazily or via [init].
  static ApiBaseHelper get instance => _instance ??= ApiBaseHelper();

  /// Explicitly initializes the singleton. Call once in main().
  static void init() {
    _instance = ApiBaseHelper();
  }

  final Dio _dio;

  /// Extracts [ApiException] from a [DioException].
  ApiException _extractException(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    return InternalServerErrorException(
      e.message ?? 'Something went wrong',
    );
  }

  /// HTTP GET.
  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _extractException(e);
    }
  }

  /// HTTP POST.
  Future<Map<String, dynamic>> post(
    String url, {
    dynamic data,
  }) async {
    try {
      final response = await _dio.post(url, data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _extractException(e);
    }
  }

  /// HTTP PUT.
  Future<Map<String, dynamic>> put(
    String url, {
    dynamic data,
  }) async {
    try {
      final response = await _dio.put(url, data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _extractException(e);
    }
  }

  /// HTTP DELETE.
  Future<Map<String, dynamic>> delete(
    String url, {
    dynamic data,
  }) async {
    try {
      final response = await _dio.delete(url, data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _extractException(e);
    }
  }
}
