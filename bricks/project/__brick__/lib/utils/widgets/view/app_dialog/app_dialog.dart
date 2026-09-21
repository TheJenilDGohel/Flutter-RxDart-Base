import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:{{project_name}}/resources/app_typography.dart';
import 'package:{{project_name}}/resources/res_colors.dart';
import 'package:{{project_name}}/utils/widgets/ui/common_button.dart';
import 'package:{{project_name}}/utils/widgets/view/app_dialog/bloc/app_dialog_bloc.dart';

enum _AppDialogKind { confirmation, status, confirmAsync }

/// Unified dialog shell for confirmation, status alerts, and async mutation dialogs.
///
/// Use named constructors or static helper methods:
/// - [AppDialog.showConfirmation]
/// - [AppDialog.showStatus]
/// - [AppDialog.showAsyncConfirm]
class AppDialog extends StatefulWidget {
  final _AppDialogKind _kind;
  final String title;
  final String message;
  final Widget? content;

  // Confirmation / Status fields
  final String? confirmLabel;
  final String? cancelLabel;
  final Color? confirmColor;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  // Status icon
  final IconData? statusIcon;
  final Color? statusIconColor;

  // Async confirmation
  final Future<bool> Function()? onConfirmAsync;

  const AppDialog.confirmation({
    super.key,
    required this.title,
    required this.message,
    this.content,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.confirmColor,
    this.onConfirm,
    this.onCancel,
  })  : _kind = _AppDialogKind.confirmation,
        statusIcon = null,
        statusIconColor = null,
        onConfirmAsync = null;

  const AppDialog.status({
    super.key,
    required this.title,
    required this.message,
    this.statusIcon = Icons.info_outline,
    this.statusIconColor = ResColors.primary,
    this.confirmLabel = 'OK',
    this.onConfirm,
    this.content,
  })  : _kind = _AppDialogKind.status,
        cancelLabel = null,
        confirmColor = null,
        onCancel = null,
        onConfirmAsync = null;

  const AppDialog.asyncConfirm({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirmAsync,
    this.content,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.confirmColor,
    this.onCancel,
  })  : _kind = _AppDialogKind.confirmAsync,
        statusIcon = null,
        statusIconColor = null,
        onConfirm = null;

  /// Convenience show method for confirmation dialog.
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    Widget? content,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    Color? confirmColor,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => AppDialog.confirmation(
        title: title,
        message: message,
        content: content,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        confirmColor: confirmColor,
        onConfirm: () {
          onConfirm?.call();
          Navigator.of(dialogContext).pop(true);
        },
        onCancel: () {
          onCancel?.call();
          Navigator.of(dialogContext).pop(false);
        },
      ),
    );
  }

  /// Convenience show method for status/alert dialog.
  static Future<void> showStatus({
    required BuildContext context,
    required String title,
    required String message,
    IconData? statusIcon,
    Color? statusIconColor,
    String buttonLabel = 'OK',
    VoidCallback? onDismiss,
    bool barrierDismissible = true,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => AppDialog.status(
        title: title,
        message: message,
        statusIcon: statusIcon ?? Icons.info_outline,
        statusIconColor: statusIconColor ?? ResColors.primary,
        confirmLabel: buttonLabel,
        onConfirm: () {
          onDismiss?.call();
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  /// Convenience show method for async mutation dialog with loading spinner.
  static Future<bool?> showAsyncConfirm({
    required BuildContext context,
    required String title,
    required String message,
    required Future<bool> Function() onConfirmAsync,
    Widget? content,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    Color? confirmColor,
    VoidCallback? onCancel,
    bool barrierDismissible = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => AppDialog.asyncConfirm(
        title: title,
        message: message,
        content: content,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        confirmColor: confirmColor,
        onConfirmAsync: onConfirmAsync,
        onCancel: () {
          onCancel?.call();
          Navigator.of(dialogContext).pop(false);
        },
      ),
    );
  }

  @override
  State<AppDialog> createState() => _AppDialogState();
}

class _AppDialogState extends State<AppDialog> {
  late final AppDialogBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = AppDialogBloc();
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  Future<void> _handleAsyncConfirm() async {
    if (widget.onConfirmAsync == null) return;

    final success = await _bloc.runAsync(widget.onConfirmAsync!);
    if (mounted && success) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ResColors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: ResColors.surface,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: ResColors.black.withOpacity(0.08),
              blurRadius: 24.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: widget._kind == _AppDialogKind.status
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            if (widget._kind == _AppDialogKind.status &&
                widget.statusIcon != null) ...[
              Container(
                width: 56.r,
                height: 56.r,
                decoration: BoxDecoration(
                  color: (widget.statusIconColor ?? ResColors.primary)
                      .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.statusIcon,
                  color: widget.statusIconColor ?? ResColors.primary,
                  size: 28.r,
                ),
              ),
              SizedBox(height: 16.h),
            ],
            Text(
              widget.title,
              textAlign: widget._kind == _AppDialogKind.status
                  ? TextAlign.center
                  : TextAlign.start,
              style: AppTypography.headline(color: ResColors.textPrimary)
                  .copyWith(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text(
              widget.message,
              textAlign: widget._kind == _AppDialogKind.status
                  ? TextAlign.center
                  : TextAlign.start,
              style: AppTypography.body(color: ResColors.textSecondary)
                  .copyWith(fontSize: 14.sp),
            ),
            if (widget.content != null) ...[
              SizedBox(height: 16.h),
              widget.content!,
            ],
            SizedBox(height: 24.h),
            if (widget._kind == _AppDialogKind.status)
              CommonButton(
                text: widget.confirmLabel ?? 'OK',
                onPressed: () {
                  if (widget.onConfirm != null) {
                    widget.onConfirm!();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              )
            else
              StreamBuilder<bool>(
                stream: _bloc.isLoading$,
                initialData: _bloc.currentIsLoading,
                builder: (context, snapshot) {
                  final isLoading = snapshot.data!;
                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  if (widget.onCancel != null) {
                                    widget.onCancel!();
                                  } else {
                                    Navigator.of(context).pop(false);
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ResColors.textSecondary,
                            side: const BorderSide(color: ResColors.border),
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            widget.cancelLabel ?? 'Cancel',
                            style: AppTypography.button()
                                .copyWith(color: ResColors.textSecondary),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: CommonButton(
                          text: widget.confirmLabel ?? 'Confirm',
                          loading: isLoading,
                          backgroundColor:
                              widget.confirmColor ?? ResColors.primary,
                          onPressed:
                              widget._kind == _AppDialogKind.confirmAsync
                                  ? _handleAsyncConfirm
                                  : () {
                                      if (widget.onConfirm != null) {
                                        widget.onConfirm!();
                                      } else {
                                        Navigator.of(context).pop(true);
                                      }
                                    },
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
