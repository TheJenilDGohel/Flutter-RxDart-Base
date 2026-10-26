import 'dart:async';

import 'package:flutter/material.dart';
import 'package:recipe_app/features/cart/bloc/cart_bloc.dart';
import 'package:recipe_app/utils/extensions/context_ext.dart';
import 'package:recipe_app/utils/show_message.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => CartPageState();
}

class CartPageState extends State<CartPage> {
  final _bloc = CartBloc();

  // Recipe D, page side.
  // recipe-block: 8

  @override
  void dispose() {
    _eventsSub.cancel();
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      TextButton(onPressed: _bloc.add, child: Text(context.l10n.cartAdded));
}
