import 'package:{{project_name}}/networking/api_exceptions.dart';

typedef RetryCallback = void Function();

/// Sealed response wrapper for API calls.
///
/// TRUE sealed class hierarchy — not an enum with nullable data/error fields.
/// The compiler enforces exhaustive switch coverage:
///
/// ```dart
/// return switch (state) {
///   InitialResponse() || LoadingResponse() => const AppLoadingState(),
///   ErrorResponse(:final error) => AppErrorState(...),
///   SuccessResponse(:final data) => ContentWidget(data: data),
/// };
/// ```
sealed class ApiResponse<T> {
  const ApiResponse();

  const factory ApiResponse.initial() = InitialResponse<T>;
  const factory ApiResponse.loading() = LoadingResponse<T>;
  const factory ApiResponse.completed(T data) = SuccessResponse<T>;
  const factory ApiResponse.error(ApiException error, {RetryCallback? retry}) =
      ErrorResponse<T>;

  /// Returns the data if the response is [SuccessResponse], otherwise null.
  T? get data => switch (this) {
        SuccessResponse<T>(:final data) => data,
        _ => null,
      };
}

/// No request has been made yet.
final class InitialResponse<T> extends ApiResponse<T> {
  const InitialResponse();
}

/// Request is in flight.
final class LoadingResponse<T> extends ApiResponse<T> {
  const LoadingResponse();
}

/// Request succeeded with [data].
final class SuccessResponse<T> extends ApiResponse<T> {
  const SuccessResponse(this.data);
  @override
  final T data;
}

/// Request failed with a typed [error] and optional [retry] action.
final class ErrorResponse<T> extends ApiResponse<T> {
  const ErrorResponse(this.error, {this.retry});

  final ApiException error;
  final RetryCallback? retry;

  /// Backward-compatible alias for [error].
  ApiException get exception => error;
}
