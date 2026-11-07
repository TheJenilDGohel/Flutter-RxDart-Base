import 'package:flutter/widgets.dart';
import 'package:{{project_name}}/networking/api_exceptions.dart';
import 'package:{{project_name}}/utils/extensions/context_ext.dart';

/// Extension on [ApiException] for user-facing UI message formatting.
extension ApiExceptionUIExt on ApiException {
  /// Maps internal [ApiException]s to user-friendly messages.
  ///
  /// Only backend-authored copy ([BusinessLogicException], and
  /// [ValidationException] when the server sent a message) is displayed
  /// verbatim. Everything else maps to localized strings.
  String userFacingMessage(BuildContext context) => switch (this) {
        NoInternetException() => context.l10n.errorNoInternet,
        UnauthorizedException() => context.l10n.errorUnauthorized,
        ForbiddenException() => context.l10n.errorForbidden,
        TooManyRequestsException() => context.l10n.errorRateLimited,
        RequestTimeoutException() => context.l10n.errorTimeout,
        BusinessLogicException(:final message) => message,
        ValidationException(:final message) when message.isNotEmpty =>
          message,
        _ => context.l10n.errorGeneric,
      };

  /// Convenient alias for [userFacingMessage].
  String userMessage(BuildContext context) => userFacingMessage(context);
}
