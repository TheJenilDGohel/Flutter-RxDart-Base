import 'package:{{project_name}}/networking/api_exceptions.dart';

/// Extension on [ApiException] for user-facing UI message formatting.
extension ApiExceptionUIExt on ApiException {
  /// Maps internal [ApiException]s to user-friendly messages.
  ///
  /// Only [BusinessLogicException] copy is displayed verbatim as it originates
  /// from explicit backend error messaging.
  String get userFacingMessage => switch (this) {
        NoInternetException() => 'Check your connection and try again.',
        UnauthorizedException() => 'Your session expired. Please sign in again.',
        BusinessLogicException(:final message) => message,
        _ => 'Something went wrong. Please try again.',
      };
}
