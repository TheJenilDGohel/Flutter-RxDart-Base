import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:{{project_name}}/resources/res_colors.dart';
import 'package:{{project_name}}/resources/app_typography.dart';
import 'package:{{project_name}}/utils/extensions/context_ext.dart';

/// Error state widget with a [title], [message] and an [onRetry] callback.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    this.title,
    required this.message,
    this.onRetry,
  });

  final String? title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48.sp,
              color: ResColors.error,
            ),
            SizedBox(height: 16.h),
            if (title != null) ...[
              Text(
                title!,
                style: AppTypography.textTheme.titleLarge?.copyWith(
                  color: ResColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
            ],
            Text(
              message,
              style: AppTypography.textTheme.bodyLarge?.copyWith(
                color: ResColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ResColors.primary,
                  foregroundColor: ResColors.onPrimary,
                ),
                child: Text(context.l10n.retryButton),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
