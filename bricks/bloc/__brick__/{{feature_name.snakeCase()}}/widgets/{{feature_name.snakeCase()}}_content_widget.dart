import 'package:flutter/material.dart';

/// Content widget for {{feature_name.titleCase()}}.
class {{feature_name.pascalCase()}}ContentWidget extends StatelessWidget {
  const {{feature_name.pascalCase()}}ContentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('{{feature_name.titleCase()}} Content'),
    );
  }
}
