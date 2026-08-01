import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:{{project_name}}/resources/res_colors.dart';

/// Design token: Material 3 Typography Type Scale with ScreenUtil scaling.
///
/// By default, [primaryFontFamily] and [secondaryFontFamily] are set to `null`
/// so Flutter automatically uses native system platform fonts (Roboto on Android,
/// SF Pro on iOS).
///
/// To use custom fonts (e.g. Poppins, Inter), add the font asset declarations to
/// `pubspec.yaml` and update the family constants below.
abstract final class AppTypography {
  /// Font family for headlines, display, and titles (null = system default).
  static const String? primaryFontFamily = null;

  /// Font family for body, labels, and buttons (null = system default).
  static const String? secondaryFontFamily = null;

  /// Official Material 3 Type Scale initialized with ScreenUtil [.sp] sizes.
  static TextTheme get textTheme => TextTheme(
        // ── Display ──────────────────────────────────────────────────
        displayLarge: TextStyle(
          fontFamily: primaryFontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 57.sp,
          height: 1.12,
          color: ResColors.textPrimary,
        ),
        displayMedium: TextStyle(
          fontFamily: primaryFontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 45.sp,
          height: 1.16,
          color: ResColors.textPrimary,
        ),
        displaySmall: TextStyle(
          fontFamily: primaryFontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 36.sp,
          height: 1.22,
          color: ResColors.textPrimary,
        ),

        // ── Headline ─────────────────────────────────────────────────
        headlineLarge: TextStyle(
          fontFamily: primaryFontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 32.sp,
          height: 1.25,
          color: ResColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: primaryFontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 28.sp,
          height: 1.29,
          color: ResColors.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontFamily: primaryFontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 24.sp,
          height: 1.33,
          color: ResColors.textPrimary,
        ),

        // ── Title ────────────────────────────────────────────────────
        titleLarge: TextStyle(
          fontFamily: primaryFontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 22.sp,
          height: 1.27,
          color: ResColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: primaryFontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 16.sp,
          height: 1.38,
          color: ResColors.textPrimary,
        ),
        titleSmall: TextStyle(
          fontFamily: primaryFontFamily,
          fontWeight: FontWeight.w500,
          fontSize: 14.sp,
          height: 1.43,
          color: ResColors.textPrimary,
        ),

        // ── Body ─────────────────────────────────────────────────────
        bodyLarge: TextStyle(
          fontFamily: secondaryFontFamily,
          fontWeight: FontWeight.w400,
          fontSize: 16.sp,
          height: 1.50,
          color: ResColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: secondaryFontFamily,
          fontWeight: FontWeight.w400,
          fontSize: 14.sp,
          height: 1.43,
          color: ResColors.textPrimary,
        ),
        bodySmall: TextStyle(
          fontFamily: secondaryFontFamily,
          fontWeight: FontWeight.w400,
          fontSize: 12.sp,
          height: 1.33,
          color: ResColors.textSecondary,
        ),

        // ── Label ────────────────────────────────────────────────────
        labelLarge: TextStyle(
          fontFamily: secondaryFontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 14.sp,
          height: 1.43,
          color: ResColors.textPrimary,
        ),
        labelMedium: TextStyle(
          fontFamily: secondaryFontFamily,
          fontWeight: FontWeight.w500,
          fontSize: 12.sp,
          height: 1.33,
          color: ResColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontFamily: secondaryFontFamily,
          fontWeight: FontWeight.w500,
          fontSize: 11.sp,
          height: 1.45,
          color: ResColors.textSecondary,
        ),
      );

  // ── Convenient Style Helpers ─────────────────────────────────────────

  /// Standard Headline style (defaults to `headlineSmall` 24sp/w600).
  static TextStyle headline({Color? color, double? fontSize}) => TextStyle(
        fontFamily: primaryFontFamily,
        fontWeight: FontWeight.w600,
        fontSize: fontSize ?? 24.sp,
        height: 1.33,
        color: color ?? ResColors.textPrimary,
      );

  /// Standard Title style (defaults to `titleMedium` 16sp/w600).
  static TextStyle title({Color? color, double? fontSize}) => TextStyle(
        fontFamily: primaryFontFamily,
        fontWeight: FontWeight.w600,
        fontSize: fontSize ?? 16.sp,
        height: 1.38,
        color: color ?? ResColors.textPrimary,
      );

  /// Standard Body style (defaults to `bodyMedium` 14sp/w400).
  static TextStyle body({Color? color, double? fontSize}) => TextStyle(
        fontFamily: secondaryFontFamily,
        fontWeight: FontWeight.w400,
        fontSize: fontSize ?? 14.sp,
        height: 1.43,
        color: color ?? ResColors.textPrimary,
      );

  /// Standard Label style (defaults to `labelMedium` 12sp/w500).
  static TextStyle label({Color? color, double? fontSize}) => TextStyle(
        fontFamily: secondaryFontFamily,
        fontWeight: FontWeight.w500,
        fontSize: fontSize ?? 12.sp,
        height: 1.33,
        color: color ?? ResColors.textSecondary,
      );

  /// Standard Button text style (defaults to `labelLarge` 14sp/w600).
  static TextStyle button({Color? color, double? fontSize}) => TextStyle(
        fontFamily: secondaryFontFamily,
        fontWeight: FontWeight.w600,
        fontSize: fontSize ?? 14.sp,
        height: 1.43,
        color: color ?? ResColors.white,
      );
}
