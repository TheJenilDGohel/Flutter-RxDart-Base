import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:{{project_name}}/l10n/generated/app_localizations.dart';
import 'package:toastification/toastification.dart';
import 'package:redux/redux.dart';
import 'package:{{project_name}}/redux/app_state.dart';
import 'package:{{project_name}}/redux/app_store.dart';
import 'package:{{project_name}}/resources/app_breakpoints.dart';
import 'package:{{project_name}}/resources/res_colors.dart';
import 'package:{{project_name}}/resources/app_typography.dart';
import 'package:{{project_name}}/utils/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env
  await dotenv.load(fileName: '.env');
  // Example of injecting variables manually (e.g., merging with Platform.environment):
  // dotenv.env.addAll({'EXTRA_VAR': 'value'});

  // Initialize Redux store and hydrate from SharedPreferences
  final Store<AppState> store = await AppStore.init();

  runApp(MyApp(store: store));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.store});

  final Store<AppState> store;

  @override
  Widget build(BuildContext context) {
    return StoreProvider<AppState>(
      store: store,
      // Rebuilds on window resize (rotation, fold/unfold, split screen), so
      // the design size below follows the window class.
      child: MediaQuery.fromView(
        view: View.of(context),
        child: StoreConnector<AppState, String>(
          converter: (store) => store.state.locale,
          builder: (context, locale) {
            return ScreenUtilInit(
              // Phone design on compact widths; 1:1 (no scaling) from 600dp,
              // where screens lay out with WindowSize instead.
              designSize: AppBreakpoints.designSizeFor(
                MediaQuery.sizeOf(context),
              ),
              minTextAdapt: true,
              builder: (_, _) => ToastificationWrapper(
                child: MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  routerConfig: AppRouter.router,
                  locale: Locale(locale),
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  theme: ThemeData(
                    colorScheme: ColorScheme.fromSeed(
                      seedColor: ResColors.primary,
                    ),
                    textTheme: AppTypography.textTheme,
                    useMaterial3: true,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
