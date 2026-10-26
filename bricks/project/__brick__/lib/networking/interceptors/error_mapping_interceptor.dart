import 'package:dio/dio.dart';
import 'package:{{project_name}}/networking/api_exceptions.dart';
import 'package:{{project_name}}/redux/actions.dart';
import 'package:{{project_name}}/redux/app_store.dart';

/// Interceptor #5 in the chain (after RetryInterceptor).
///
/// Converts raw [DioException] into the sealed [ApiException] hierarchy.
/// Also checks successful responses for business logic errors
/// (HTTP 200/201 but `{"status": false, "message": "..."}`).
///
/// A 401 while a token is held dispatches [LogoutAction], so an expired
/// session is cleared exactly once instead of being resent forever.
class ErrorMappingInterceptor extends Interceptor {
  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final data = response.data;
    if (data is Map && _isFalse(data['status'])) {
      final message = data['message']?.toString() ?? 'An error occurred';
      return handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: BusinessLogicException(message),
        ),
      );
    }
    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    // Already mapped (e.g. by ConnectivityInterceptor, or a retried request
    // that passed through this interceptor once).
    if (err.error is ApiException) return handler.next(err);

    final statusCode = err.response?.statusCode;
    final serverMessage = _serverMessage(err.response?.data);
    final message = serverMessage ?? err.message ?? '';

    if (statusCode == 401 && (AppStore.authToken?.isNotEmpty ?? false)) {
      AppStore.dispatch(const LogoutAction());
    }

    final ApiException exception = switch (statusCode) {
      400 => BadRequestException(message),
      401 => UnauthorizedException(message),
      403 => ForbiddenException(message),
      404 => NotFoundException(message),
      408 => RequestTimeoutException(message, 408),
      409 => ConflictException(message),
      422 => ValidationException(serverMessage ?? ''),
      429 => TooManyRequestsException(message),
      final int code when code >= 500 =>
        InternalServerErrorException(message, code),
      _ => _mapByType(err),
    };

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: exception,
      ),
    );
  }

  /// Falls back to mapping by [DioExceptionType] when there's no HTTP status.
  ApiException _mapByType(DioException err) => switch (err.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          RequestTimeoutException(err.message ?? 'Request timeout'),
        DioExceptionType.connectionError =>
          NoInternetException(err.message ?? 'No internet connection'),
        DioExceptionType.cancel =>
          RequestCancelledException(err.message ?? 'Request cancelled'),
        _ => InternalServerErrorException(
            err.message ?? 'Something went wrong',
            err.response?.statusCode,
          ),
      };

  static bool _isFalse(Object? value) =>
      value == false || value == 'false';

  /// Reads a human-readable message from common error body shapes:
  /// `{"message": ".."}`, `{"error": ".."}`, `{"error": {"message": ".."}}`.
  static String? _serverMessage(Object? data) {
    if (data is! Map) return null;
    final direct = data['message'] ?? data['error'];
    if (direct is String && direct.isNotEmpty) return direct;
    if (direct is Map && direct['message'] is String) {
      return direct['message'] as String;
    }
    return null;
  }
}
