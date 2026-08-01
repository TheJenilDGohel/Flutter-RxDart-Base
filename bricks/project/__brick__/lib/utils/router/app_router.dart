import 'package:flutter/material.dart';
import 'package:{{project_name}}/screens/non_auth/showcase/showcase_home_page.dart';
import 'package:{{project_name}}/utils/router/routes.dart';

/// App router configuration with [onGenerateRoute] and global [navigatorKey].
abstract final class AppRouter {
  /// Global navigator key so navigation can occur anywhere in the app.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Generates routes dynamically based on [RouteSettings].
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.showcase:
        return _build(settings, (_) => const ShowcaseHomePage());

      default:
        return _build(settings, (_) => const ShowcaseHomePage());
    }
  }

  /// Helper to wrap routes in [MaterialPageRoute].
  static MaterialPageRoute<dynamic> _build(
    RouteSettings settings,
    WidgetBuilder builder,
  ) =>
      MaterialPageRoute(settings: settings, builder: builder);
}
