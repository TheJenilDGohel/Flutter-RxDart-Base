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

  /// Lazily-created singleton instance.
  static ApiBaseHelper get instance => _instance ??= ApiBaseHelper();

  final Dio _dio;

  /// Extracts [ApiException] from a [DioException].
  ApiException _extractException(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    return InternalServerErrorException(
      e.message ?? 'Something went wrong',
    );
  }

  /// Parses the raw response body safely. Never throws anything other
  /// than an [ApiException].
  Map<String, dynamic> _parseResponse(dynamic data) {
    if (data == null || data == '') return {};
    if (data is List) return {'items': data};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw MalformedResponseException(
      'Expected a JSON object or array, got ${data.runtimeType}',
    );
  }

  /// HTTP GET.
  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        url,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
      return _parseResponse(response.data);
    } on DioException catch (e) {
      throw _extractException(e);
    }
  }

  /// HTTP POST.
  Future<Map<String, dynamic>> post(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        url,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
      return _parseResponse(response.data);
    } on DioException catch (e) {
      throw _extractException(e);
    }
  }

  /// HTTP POST with multipart/form-data.
  Future<Map<String, dynamic>> postFormData(
    String url, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        url,
        data: FormData.fromMap(data ?? {}),
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
      return _parseResponse(response.data);
    } on DioException catch (e) {
      throw _extractException(e);
    }
  }

  /// HTTP PUT.
  Future<Map<String, dynamic>> put(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        url,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
      return _parseResponse(response.data);
    } on DioException catch (e) {
      throw _extractException(e);
    }
  }

  /// HTTP PUT with multipart/form-data.
  Future<Map<String, dynamic>> putFormData(
    String url, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        url,
        data: FormData.fromMap(data ?? {}),
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
      return _parseResponse(response.data);
    } on DioException catch (e) {
      throw _extractException(e);
    }
  }

  /// HTTP DELETE.
  Future<Map<String, dynamic>> delete(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete<dynamic>(
        url,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
      return _parseResponse(response.data);
    } on DioException catch (e) {
      throw _extractException(e);
    }
  }
}
