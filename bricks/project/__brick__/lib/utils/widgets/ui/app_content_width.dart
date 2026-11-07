import 'package:flutter/material.dart';
import 'package:{{project_name}}/resources/app_breakpoints.dart';

/// Centers [child] in a column no wider than [maxWidth] (default
/// [AppBreakpoints.maxContentWidth]), so forms, lists and text stay readable
/// on tablets, unfolded foldables and desktop windows. A no-op on phones.
class AppContentWidth extends StatelessWidget {
  const AppContentWidth({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
