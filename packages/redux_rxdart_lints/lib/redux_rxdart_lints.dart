import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/rules/no_rxdart_in_ui.dart';
import 'src/rules/no_setstate_in_widget.dart';
import 'src/rules/repo_transport_only.dart';

PluginBase createPlugin() => _ReduxRxdartLinter();

class _ReduxRxdartLinter extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        NoRxdartInUi(),
        NoSetStateInWidget(),
        RepoTransportOnly(),
      ];
}
