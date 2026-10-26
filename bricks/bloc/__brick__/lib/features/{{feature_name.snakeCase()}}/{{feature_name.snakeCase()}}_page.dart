import 'package:flutter/material.dart';
import 'package:{{project_name}}/features/{{feature_name.snakeCase()}}/bloc/{{feature_name.snakeCase()}}_bloc.dart';
import 'package:{{project_name}}/features/{{feature_name.snakeCase()}}/widgets/{{feature_name.snakeCase()}}_content_widget.dart';
import 'package:{{project_name}}/utils/widgets/ui/app_response_builder.dart';

/// Page for {{feature_name.titleCase()}}: owns the BLoC's lifecycle and
/// binds its stream to the UI. No setState (Golden Rule #3).
class {{feature_name.pascalCase()}}Page extends StatefulWidget {
  const {{feature_name.pascalCase()}}Page({super.key});

  @override
  State<{{feature_name.pascalCase()}}Page> createState() => {{feature_name.pascalCase()}}PageState();
}

class {{feature_name.pascalCase()}}PageState extends State<{{feature_name.pascalCase()}}Page> {
  late final {{feature_name.pascalCase()}}Bloc _bloc = {{feature_name.pascalCase()}}Bloc()..fetch();

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{{feature_name.titleCase()}}')),
      body: RefreshIndicator(
        onRefresh: () => _bloc.fetch(refresh: true),
        child: AppResponseBuilder(
          stream: _bloc.data$,
          builder: (context, data) => {{feature_name.pascalCase()}}ContentWidget(data: data),
        ),
      ),
    );
  }
}
