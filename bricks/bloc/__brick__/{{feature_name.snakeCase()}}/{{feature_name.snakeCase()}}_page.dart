import 'package:flutter/material.dart';
import 'package:{{project_name}}/utils/widgets/ui/ui_components.dart';
import 'package:{{project_name}}/{{#feature_path}}{{feature_path}}/{{/feature_path}}{{^feature_path}}features/{{/feature_path}}{{feature_name.snakeCase()}}/bloc/{{feature_name.snakeCase()}}_bloc.dart';
import 'package:{{project_name}}/{{#feature_path}}{{feature_path}}/{{/feature_path}}{{^feature_path}}features/{{/feature_path}}{{feature_name.snakeCase()}}/widgets/{{feature_name.snakeCase()}}_content_widget.dart';

/// Page widget for {{feature_name.titleCase()}}.
class {{feature_name.pascalCase()}}Page extends StatefulWidget {
  const {{feature_name.pascalCase()}}Page({super.key});

  @override
  State<{{feature_name.pascalCase()}}Page> createState() =>
      _{{feature_name.pascalCase()}}PageState();
}

class _{{feature_name.pascalCase()}}PageState extends State<{{feature_name.pascalCase()}}Page> {
  late final {{feature_name.pascalCase()}}Bloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = {{feature_name.pascalCase()}}Bloc();
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: '{{feature_name.titleCase()}}',
      body: const {{feature_name.pascalCase()}}ContentWidget(),
    );
  }
}
