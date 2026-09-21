import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:temp_test_app/resources/app_typography.dart';
import 'package:temp_test_app/resources/res_colors.dart';

/// Production-ready standardized button supporting:
/// - Built-in [loading] indicator (disables taps and shows spinner)
/// - [enabled] state
/// - [prefix] and [suffix] icon widgets
/// - ScreenUtil responsive scaling
class CommonButton extends StatelessWidget {
  const CommonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.prefix,
    this.suffix,
    this.width,
    this.height,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.borderRadius,
    this.padding,
    this.textStyle,
    this.loading = false,
    this.enabled = true,
  });

  final String text;
  final VoidCallback? onPressed;
  final Widget? prefix;
  final Widget? suffix;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final bool loading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isInteractive = enabled && !loading && onPressed != null;
    final effectiveBg = !enabled
        ? ResColors.disabled
        : (backgroundColor ?? ResColors.primary);
    final effectiveText = textColor ?? ResColors.white;
    final radius = BorderRadius.circular(borderRadius ?? 12.r);

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 50.h,
      child: ElevatedButton(
        onPressed: isInteractive ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBg,
          foregroundColor: effectiveText,
          disabledBackgroundColor: ResColors.disabled,
          disabledForegroundColor: ResColors.textDisabled,
          padding: padding ?? EdgeInsets.symmetric(horizontal: 16.w),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: borderColor != null
                ? BorderSide(color: borderColor!)
                : BorderSide.none,
          ),
          elevation: 0,
        ),
        child: loading
            ? SizedBox(
                width: 22.r,
                height: 22.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveText),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (prefix != null) ...[
                    prefix!,
                    SizedBox(width: 8.w),
                  ],
                  Text(
                    text,
                    style: textStyle ??
                        AppTypography.button().copyWith(color: effectiveText),
                  ),
                  if (suffix != null) ...[
                    SizedBox(width: 8.w),
                    suffix!,
                  ],
                ],
              ),
      ),
    );
  }
}
