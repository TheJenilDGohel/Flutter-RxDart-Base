import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:{{project_name}}/features/showcase/showcase_home_page.dart';
import 'package:{{project_name}}/utils/router/routes.dart';

/// App navigation: one [GoRouter], so deep links, Android App Links, iOS
/// Universal Links, web URLs and predictive back all resolve the same paths.
///
/// Add a screen with `dart scripts/agent/wire_route.dart <feature>`: it
/// adds the [Routes] constant and a [GoRoute] above the `wire_route:routes`
/// marker. Navigate with `context.push(Routes.x)` (on top of the stack) or
/// `context.go(Routes.x)` (replace the stack, e.g. after sign-in); pass ids as
/// path or query parameters so the screen also opens from a link.
abstract final class AppRouter {
  /// Root navigator key, for navigation that starts outside the widget tree
  /// (a notification tap): `AppRouter.navigatorKey.currentContext`.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// The router `MaterialApp.router` uses.
  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: Routes.showcase,
    routes: [
      GoRoute(
        path: Routes.showcase,
        builder: (_, _) => const ShowcaseHomePage(),
      ),
      // wire_route:routes — new GoRoute entries are added above this line.
    ],
    // An unknown link opens the start screen instead of an error page.
    errorBuilder: (_, _) => const ShowcaseHomePage(),
  );
}
