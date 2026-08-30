import 'package:flutter/material.dart';
import 'package:{{project_name}}/l10n/generated/app_localizations.dart';

/// Context extension helpers for quick access to theme and localizations.
extension ContextExtensions on BuildContext {
  /// Convenient access to [AppLocalizations].
  ///
  /// ```dart
  /// Text(context.l10n.appTitle)
  /// ```
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  /// Quick access to current [TextTheme].
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Quick access to current [ColorScheme].
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Quick access to screen size.
  Size get screenSize => MediaQuery.sizeOf(this);
}
