import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:{{project_name}}/resources/res_colors.dart';
import 'package:{{project_name}}/resources/app_typography.dart';

/// App status types for toasts, alerts, and banners.
enum AppStatus { success, info, warning, error }

/// Convenience helper to show custom toasts / message bars from the bottom of the screen.
///
/// ```dart
/// ShowMessage.success('Saved successfully');
/// ShowMessage.error('Something went wrong');
/// ShowMessage.info('New update available');
/// ShowMessage.warning('Your session is about to expire');
/// ```
abstract final class ShowMessage {
  static void _show(String message, AppStatus status, {Duration? duration}) {
    showOverlayNotification(
      (context) => _CustomToast(message: message, status: status),
      duration: duration ?? const Duration(seconds: 3),
      position: NotificationPosition.bottom,
    );
  }

  /// Shows a green success toast.
  static void success(String message, {Duration? duration}) =>
      _show(message, AppStatus.success, duration: duration);

  /// Shows a blue info toast.
  static void info(String message, {Duration? duration}) =>
      _show(message, AppStatus.info, duration: duration);

  /// Shows a yellow warning toast.
  static void warning(String message, {Duration? duration}) =>
      _show(message, AppStatus.warning, duration: duration);

  /// Shows a red error toast.
  static void error(String message, {Duration? duration}) =>
      _show(message, AppStatus.error, duration: duration);

  /// Generic show with explicit [status].
  static void show(String message, AppStatus status, {Duration? duration}) =>
      _show(message, status, duration: duration);
}

/// Extension on [BuildContext] for convenient toast access inside widgets.
extension ToastContextExt on BuildContext {
  void showToast(String message, AppStatus status) =>
      ShowMessage.show(message, status);

  void showSuccess(String message) => ShowMessage.success(message);

  void showInfo(String message) => ShowMessage.info(message);

  void showWarning(String message) => ShowMessage.warning(message);

  void showError(String message) => ShowMessage.error(message);
}

class _CustomToast extends StatelessWidget {
  const _CustomToast({
    required this.message,
    required this.status,
  });

  final String message;
  final AppStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = _statusColors[status]!;
    final icon = _statusIcons[status]!;

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 25.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: colors.border, width: 1.w),
        boxShadow: [
          BoxShadow(
            color: ResColors.shadow,
            blurRadius: 16.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: colors.icon, size: 22.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              message,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body().copyWith(
                color: colors.text,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                height: 1.4,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _ToastColors {
  const _ToastColors({
    required this.background,
    required this.border,
    required this.icon,
    required this.text,
  });

  final Color background;
  final Color border;
  final Color icon;
  final Color text;
}

final Map<AppStatus, _ToastColors> _statusColors = {
  AppStatus.success: const _ToastColors(
    background: ResColors.success,
    border: ResColors.success,
    icon: ResColors.white,
    text: ResColors.white,
  ),
  AppStatus.info: const _ToastColors(
    background: ResColors.info,
    border: ResColors.info,
    icon: ResColors.white,
    text: ResColors.white,
  ),
  AppStatus.warning: const _ToastColors(
    background: ResColors.warning,
    border: ResColors.warning,
    icon: ResColors.white,
    text: ResColors.white,
  ),
  AppStatus.error: const _ToastColors(
    background: ResColors.error,
    border: ResColors.error,
    icon: ResColors.white,
    text: ResColors.white,
  ),
};

final Map<AppStatus, IconData> _statusIcons = {
  AppStatus.success: Icons.check_circle_outline,
  AppStatus.info: Icons.info_outline,
  AppStatus.warning: Icons.warning_amber_outlined,
  AppStatus.error: Icons.error_outline,
};
