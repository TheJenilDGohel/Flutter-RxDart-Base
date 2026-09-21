import 'package:flutter/material.dart';
import 'package:{{project_name}}/features/{{feature_name.snakeCase()}}/bloc/{{feature_name.snakeCase()}}_bloc.dart';

/// Content widget for {{feature_name.titleCase()}}.
class {{feature_name.pascalCase()}}ContentWidget extends StatelessWidget {
  const {{feature_name.pascalCase()}}ContentWidget({
    super.key,
    required this.bloc,
  });

  final {{feature_name.pascalCase()}}Bloc bloc;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('{{feature_name.titleCase()}} Content'),
    );
  }
}
