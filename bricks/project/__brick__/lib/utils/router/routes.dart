/// Central route path registry: every path `AppRouter` resolves, so deep
/// links and in-app navigation use the same strings.
///
/// ```dart
/// context.push(Routes.showcase); // package:go_router/go_router.dart
/// ```
abstract final class Routes {
  /// Initial showcase demo route.
  static const String showcase = '/';

  // ── Add project routes below ─────────────────────────────────────────
  // static const String signIn = '/sign-in';
  // static const String home = '/home';
  // static const String profile = '/profile';
}
