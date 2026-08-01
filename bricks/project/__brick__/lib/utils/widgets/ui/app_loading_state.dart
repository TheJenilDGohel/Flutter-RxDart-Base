import 'package:flutter/material.dart';
import 'package:{{project_name}}/resources/res_colors.dart';

/// Centered loading indicator using the design-token primary color.
class AppLoadingState extends StatelessWidget {
  const AppLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: ResColors.primary,
      ),
    );
  }
}
