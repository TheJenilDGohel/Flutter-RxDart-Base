/// Sealed exception hierarchy for the networking layer.
///
/// Every Dio error is mapped to one of these subtypes by
/// [ErrorMappingInterceptor]. BLoCs catch [ApiException] and use
/// [userFacingMessage] to produce safe UI copy.
///
/// TRUE sealed class hierarchy — not an enum with nullable fields.
/// The compiler enforces exhaustive switch coverage when new subtypes
/// are added.
sealed class ApiException implements Exception {
  const ApiException([this.message = '']);

  /// Internal diagnostic message. NOT safe for direct UI display
  /// (except [BusinessLogicException] — see its doc).
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Device has no network connectivity.
final class NoInternetException extends ApiException {
  const NoInternetException([super.message = 'No internet connection']);
}

/// HTTP 400 — malformed request.
final class BadRequestException extends ApiException {
  const BadRequestException([super.message = 'Bad request']);
}

/// HTTP 401 — authentication required or token expired.
final class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Unauthorized']);
}

/// HTTP 404 — resource not found.
final class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Not found']);
}

/// HTTP 409 — resource conflict (e.g. duplicate).
final class ConflictException extends ApiException {
  const ConflictException([super.message = 'Conflict']);
}

/// HTTP 408 — request timed out, or Dio connection/send/receive timeout.
final class RequestTimeoutException extends ApiException {
  const RequestTimeoutException([super.message = 'Request timeout']);
}

/// HTTP 500 — server-side failure.
final class InternalServerErrorException extends ApiException {
  const InternalServerErrorException(
      [super.message = 'Internal server error']);
}

/// HTTP 200/201 but the response body contains `{"status": false}`.
///
/// This is the ONLY exception whose [message] is safe to surface verbatim
/// in the UI — it originates from your own backend's intentional user-facing
/// messaging, not from infrastructure errors or stack traces.
final class BusinessLogicException extends ApiException {
  const BusinessLogicException([super.message = 'Business logic error']);
}
