import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:{{project_name}}/resources/res_colors.dart';
import 'package:{{project_name}}/resources/app_typography.dart';

/// Empty state widget for screens with no data to display.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    this.message = 'Nothing to show here.',
    this.icon = Icons.inbox_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64.sp, color: ResColors.divider),
          SizedBox(height: 16.h),
          Text(
            message,
            style: AppTypography.textTheme.bodyLarge?.copyWith(
              color: ResColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
