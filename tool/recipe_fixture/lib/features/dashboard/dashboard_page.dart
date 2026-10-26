import 'package:flutter/material.dart';
import 'package:recipe_app/features/dashboard/bloc/dashboard_bloc.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  late final DashboardBloc _bloc = DashboardBloc()..fetch();

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  // Recipe G, StreamBuilder.
  @override
  Widget build(BuildContext context) => recipe('12');
}
