import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:{{project_name}}/l10n/generated/app_localizations.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:redux/redux.dart';
import 'package:{{project_name}}/networking/api_base_helper.dart';
import 'package:{{project_name}}/redux/app_state.dart';
import 'package:{{project_name}}/redux/app_store.dart';
import 'package:{{project_name}}/resources/res_colors.dart';
import 'package:{{project_name}}/resources/app_typography.dart';
import 'package:{{project_name}}/utils/router/app_router.dart';
import 'package:{{project_name}}/utils/router/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize networking singleton
  ApiBaseHelper.init();

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
          return ScreenUtilInit(
            designSize: const Size(375, 812),
            minTextAdapt: true,
            builder: (_, __) => OverlaySupport.global(
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                navigatorKey: AppRouter.navigatorKey,
                initialRoute: Routes.showcase,
                onGenerateRoute: AppRouter.onGenerateRoute,
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
