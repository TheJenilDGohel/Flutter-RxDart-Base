import 'package:material_ui/material_ui.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:adaptive_units/adaptive_units.dart';
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
      child: StoreConnector<AppState, String>(
        converter: (store) => store.state.locale,
        builder: (context, locale) {
          // Sizes are written against the phone design. adaptive_units scales
          // them below 600dp and runs 1:1 from 600dp up, where screens lay
          // out by WindowSize instead; resizes (rotation, fold, split screen)
          // rebuild the widgets whose scale changed.
          return ScreenUtilInit(
            designSize: AppBreakpoints.phoneDesign,
            minTextAdapt: true,
            builder: (_, _) => ToastificationWrapper(
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                routerConfig: AppRouter.router,
                locale: Locale(locale),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
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
    );
  }
}
