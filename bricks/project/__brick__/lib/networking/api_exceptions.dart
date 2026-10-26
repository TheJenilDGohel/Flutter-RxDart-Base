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
  const ApiException([this.message = '', this.statusCode]);

  /// Internal diagnostic message. NOT safe for direct UI display
  /// (except [BusinessLogicException] — see its doc).
  final String message;

  /// HTTP status code, when the failure came from an HTTP response.
  final int? statusCode;

  @override
  String toString() => '$runtimeType($statusCode): $message';
}

/// Device has no network connectivity.
final class NoInternetException extends ApiException {
  const NoInternetException([super.message = 'No internet connection']);
}

/// HTTP 400 — malformed request.
final class BadRequestException extends ApiException {
  const BadRequestException([super.message = 'Bad request', super.statusCode = 400]);
}

/// HTTP 401 — authentication required or token expired.
final class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Unauthorized', super.statusCode = 401]);
}

/// HTTP 403 — authenticated but not allowed.
final class ForbiddenException extends ApiException {
  const ForbiddenException([super.message = 'Forbidden', super.statusCode = 403]);
}

/// HTTP 404 — resource not found.
final class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Not found', super.statusCode = 404]);
}

/// HTTP 409 — resource conflict (e.g. duplicate).
final class ConflictException extends ApiException {
  const ConflictException([super.message = 'Conflict', super.statusCode = 409]);
}

/// HTTP 422 — validation failed. [message] carries the server's text.
final class ValidationException extends ApiException {
  const ValidationException([super.message = 'Validation failed', super.statusCode = 422]);
}

/// HTTP 429 — rate limited.
final class TooManyRequestsException extends ApiException {
  const TooManyRequestsException([super.message = 'Too many requests', super.statusCode = 429]);
}

/// HTTP 408 — request timed out, or Dio connection/send/receive timeout.
final class RequestTimeoutException extends ApiException {
  const RequestTimeoutException([super.message = 'Request timeout', super.statusCode]);
}

/// HTTP 5xx (or an unrecognised failure) — server-side problem.
final class InternalServerErrorException extends ApiException {
  const InternalServerErrorException([
    super.message = 'Internal server error',
    super.statusCode,
  ]);
}

/// HTTP 200/201 but the response body contains `{"status": false}`.
///
/// This is the ONLY exception whose [message] is safe to surface verbatim
/// in the UI — it originates from your own backend's intentional user-facing
/// messaging, not from infrastructure errors or stack traces.
final class BusinessLogicException extends ApiException {
  const BusinessLogicException([super.message = 'Business logic error']);
}

/// The response body could not be parsed into the expected shape.
final class MalformedResponseException extends ApiException {
  const MalformedResponseException([super.message = 'Malformed response']);
}

/// HTTP request was cancelled by the client.
///
/// BLoCs should normally ignore this (the screen is gone or a newer
/// request replaced it) rather than emitting an error state.
final class RequestCancelledException extends ApiException {
  const RequestCancelledException([super.message = 'Request cancelled']);
}
