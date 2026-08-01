import 'package:flutter/material.dart';
import 'bloc/{{feature_name.snakeCase()}}_bloc.dart';

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
    return Scaffold(
      body: const Center(
        child: Text('{{feature_name.titleCase()}} Screen'),
      ),
    );
  }
}
