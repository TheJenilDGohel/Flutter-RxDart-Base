import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:temp_test_app/resources/app_typography.dart';
import 'package:temp_test_app/resources/res_colors.dart';
import 'package:temp_test_app/utils/widgets/view/app_textformfield/bloc/app_textformfield_bloc.dart';

/// Pre-styled, production form field with:
/// - Label & hint text
/// - Prefix icon / widget
/// - Suffix icon / widget
/// - Built-in password visibility toggle when [obscureText] is true
/// - ScreenUtil responsive scaling
/// - Form validation integration
class AppTextFormField extends StatefulWidget {
  const AppTextFormField({
    super.key,
    this.labelText,
    this.hintText,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.focusNode,
    this.fillColor,
    this.borderRadius,
    this.contentPadding,
  });

  final String? labelText;
  final String? hintText;
  final TextEditingController? controller;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final FocusNode? focusNode;
  final Color? fillColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? contentPadding;

  @override
  State<AppTextFormField> createState() => _AppTextFormFieldState();
}

class _AppTextFormFieldState extends State<AppTextFormField> {
  late final AppTextFormFieldBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = AppTextFormFieldBloc(initialObscured: widget.obscureText);
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius ?? 12.r);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: AppTypography.label().copyWith(
              color: ResColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6.h),
        ],
        StreamBuilder<bool>(
          stream: _bloc.obscured$,
          initialData: _bloc.currentObscured,
          builder: (context, snapshot) {
            final obscured = snapshot.data!;

            Widget? effectiveSuffix = widget.suffixIcon;
            if (widget.obscureText) {
              effectiveSuffix = IconButton(
                icon: Icon(
                  obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20.r,
                  color: ResColors.textSecondary,
                ),
                onPressed: _bloc.toggleVisibility,
              );
            }

            return TextFormField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              obscureText: obscured,
              enabled: widget.enabled,
              readOnly: widget.readOnly,
              maxLines: widget.obscureText ? 1 : widget.maxLines,
              minLines: widget.minLines,
              maxLength: widget.maxLength,
              validator: widget.validator,
              onChanged: widget.onChanged,
              onFieldSubmitted: widget.onFieldSubmitted,
              style: AppTypography.body(color: ResColors.textPrimary),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: AppTypography.body(color: ResColors.textDisabled),
                filled: true,
                fillColor: widget.fillColor ?? ResColors.surface,
                prefixIcon: widget.prefixIcon,
                suffixIcon: effectiveSuffix,
                contentPadding: widget.contentPadding ??
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                border: OutlineInputBorder(
                  borderRadius: radius,
                  borderSide: const BorderSide(color: ResColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: radius,
                  borderSide: const BorderSide(color: ResColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: radius,
                  borderSide:
                      const BorderSide(color: ResColors.primary, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: radius,
                  borderSide: const BorderSide(color: ResColors.error),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: radius,
                  borderSide:
                      const BorderSide(color: ResColors.error, width: 1.5),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: radius,
                  borderSide:
                      BorderSide(color: ResColors.border.withOpacity(0.5)),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
