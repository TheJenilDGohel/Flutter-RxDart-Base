import 'package:{{project_name}}/networking/api_exceptions.dart';

typedef RetryCallback = void Function();

/// Sealed response wrapper for API calls.
///
/// TRUE sealed class hierarchy — not an enum with nullable data/error fields.
/// The compiler enforces exhaustive switch coverage:
///
/// ```dart
/// return switch (state) {
///   Initial() || Loading() => const AppLoadingState(),
///   Error(:final error) => AppErrorState(...),
///   Completed(:final data) => ContentWidget(data: data),
/// };
/// ```
sealed class ApiResponse<T> {
  const ApiResponse();

  const factory ApiResponse.initial() = Initial<T>;
  const factory ApiResponse.loading() = Loading<T>;
  const factory ApiResponse.completed(T data) = Completed<T>;
  const factory ApiResponse.error(ApiException error, {RetryCallback? retry}) =
      Error<T>;

  /// Returns the data if the response is [Completed], otherwise null.
  T? get data => switch (this) {
        Completed<T>(:final data) => data,
        _ => null,
      };
}

/// No request has been made yet.
final class Initial<T> extends ApiResponse<T> {
  const Initial();
}

/// Request is in flight.
final class Loading<T> extends ApiResponse<T> {
  const Loading();
}

/// Request succeeded with [data].
final class Completed<T> extends ApiResponse<T> {
  const Completed(this.data);
  final T data;
}

/// Request failed with a typed [error] and optional [retry] action.
final class Error<T> extends ApiResponse<T> {
  const Error(this.error, {this.retry});

  final ApiException error;
  final RetryCallback? retry;

  /// Backward-compatible alias for [error].
  ApiException get exception => error;
}
