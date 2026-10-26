import 'package:flutter/material.dart';
import 'package:{{project_name}}/features/{{feature_name.snakeCase()}}/model/{{feature_name.snakeCase()}}_model.dart';

/// Renders loaded {{feature_name.titleCase()}} data. Pure and stateless:
/// it receives the parsed model, never the BLoC or a stream.
class {{feature_name.pascalCase()}}ContentWidget extends StatelessWidget {
  const {{feature_name.pascalCase()}}ContentWidget({super.key, required this.data});

  final {{feature_name.pascalCase()}}Model data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(data.name, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}
