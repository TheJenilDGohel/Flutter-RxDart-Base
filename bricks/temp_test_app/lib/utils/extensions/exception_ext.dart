import 'package:flutter/widgets.dart';
import 'package:temp_test_app/networking/api_exceptions.dart';
import 'package:temp_test_app/utils/extensions/context_ext.dart';

/// Extension on [ApiException] for user-facing UI message formatting.
extension ApiExceptionUIExt on ApiException {
  /// Maps internal [ApiException]s to user-friendly messages.
  ///
  /// Only [BusinessLogicException] copy is displayed verbatim as it originates
  /// from explicit backend error messaging.
  String userFacingMessage(BuildContext context) => switch (this) {
        NoInternetException() => context.l10n.errorNoInternet,
        UnauthorizedException() => context.l10n.errorUnauthorized,
        BusinessLogicException(:final message) => message,
        _ => context.l10n.errorGeneric,
      };

  /// Convenient alias for [userFacingMessage].
  String userMessage(BuildContext context) => userFacingMessage(context);
}
