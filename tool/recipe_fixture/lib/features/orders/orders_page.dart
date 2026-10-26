import 'package:flutter/material.dart';
import 'package:recipe_app/features/orders/bloc/orders_bloc.dart';
import 'package:recipe_app/features/orders/model/paged_orders.dart';
import 'package:recipe_app/features/orders/widgets/orders_list_widget.dart';
import 'package:recipe_app/utils/widgets/ui/app_response_builder.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => OrdersPageState();
}

class OrdersPageState extends State<OrdersPage> {
  // Recipe C, page members.
  // recipe-block: 5a

  @override
  Widget build(BuildContext context) => Scaffold(body: recipe('5b'));
}
