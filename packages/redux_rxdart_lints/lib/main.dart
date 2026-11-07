import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/rules/no_exception_tostring.dart';
import 'src/rules/no_fetch_without_token.dart';
import 'src/rules/no_rxdart_in_ui.dart';
import 'src/rules/no_screenutil_in_private_widget.dart';
import 'src/rules/no_setstate_in_widget.dart';
import 'src/rules/no_unclosed_subject.dart';
import 'src/rules/no_with_opacity.dart';
import 'src/rules/repo_transport_only.dart';

/// Entry point the Dart analysis server loads (`lib/main.dart`, top-level
/// `plugin`). Rules are registered as warnings, so they are on as soon as the
/// plugin is listed in `analysis_options.yaml`; no `diagnostics:` block needed.
final plugin = ReduxRxdartPlugin();

class ReduxRxdartPlugin extends Plugin {
  @override
  String get name => 'redux_rxdart_lints';

  @override
  void register(PluginRegistry registry) {
    registry
      ..registerWarningRule(NoRxdartInUi())
      ..registerWarningRule(NoScreenutilInPrivateWidget())
      ..registerWarningRule(NoSetStateInWidget())
      ..registerWarningRule(RepoTransportOnly())
      ..registerWarningRule(NoExceptionToString())
      ..registerWarningRule(NoWithOpacity())
      ..registerWarningRule(NoUnclosedSubject())
      ..registerWarningRule(NoFetchWithoutToken());
  }
}
