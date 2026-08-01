import 'package:dio/dio.dart';
import 'package:{{project_name}}/networking/api_exceptions.dart';

/// Interceptor #5 in the chain (after RetryInterceptor).
///
/// Converts raw [DioException] into the sealed [ApiException] hierarchy.
/// Also checks successful responses for business logic errors
/// (HTTP 200/201 but `{"status": false, "message": "..."}`).
class ErrorMappingInterceptor extends Interceptor {
  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    // Check for business logic errors in successful HTTP responses
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      if (data['status'] == false) {
        final message =
            data['message']?.toString() ?? 'An error occurred';
        return handler.reject(
          DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            error: BusinessLogicException(message),
          ),
        );
      }
    }
    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    final statusCode = err.response?.statusCode;

    final ApiException exception = switch (statusCode) {
      400 => BadRequestException(err.message ?? 'Bad request'),
      401 => UnauthorizedException(err.message ?? 'Unauthorized'),
      404 => NotFoundException(err.message ?? 'Not found'),
      408 => RequestTimeoutException(err.message ?? 'Request timeout'),
      409 => ConflictException(err.message ?? 'Conflict'),
      500 => InternalServerErrorException(
          err.message ?? 'Internal server error',
        ),
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
  ApiException _mapByType(DioException err) {
    // If the error is already an ApiException (e.g. from ConnectivityInterceptor),
    // pass it through directly.
    if (err.error is ApiException) return err.error as ApiException;

    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        RequestTimeoutException(err.message ?? 'Request timeout'),
      DioExceptionType.connectionError =>
        NoInternetException(err.message ?? 'No internet connection'),
      _ => InternalServerErrorException(
          err.message ?? 'Something went wrong',
        ),
    };
  }
}
