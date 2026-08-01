// DEMO ONLY — delete lib/screens/non_auth/showcase/ and update main.dart's home route
// once you understand the architecture.
//
// This showcase demonstrates:
// 1. Redux global session state + localization persistence (EN/HI toggle)
// 2. Direct ScreenUtil scaling (.w, .h, .r, .sp) on standard Flutter widgets
// 3. Prebuilt Toast/Message Bar helper (ShowMessage)
// 4. Prebuilt CommonUtils (dialogs, url launchers, keyboard hide)
// 5. Context Extensions (context.l10n)

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:{{project_name}}/redux/app_state.dart';
import 'package:{{project_name}}/redux/actions.dart';
import 'package:{{project_name}}/redux/app_store.dart';
import 'package:{{project_name}}/resources/res_colors.dart';
import 'package:{{project_name}}/resources/app_typography.dart';
import 'package:{{project_name}}/utils/show_message.dart';
import 'package:{{project_name}}/utils/common_utils.dart';
import 'package:{{project_name}}/utils/extensions/context_ext.dart';
import 'package:{{project_name}}/utils/widgets/app_scaffold.dart';

class ShowcaseHomePage extends StatelessWidget {
  const ShowcaseHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBarTitle: l10n.appTitle,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── ScreenUtil Responsive Header ──────────────────────────
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: ResColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: ResColors.primary.withOpacity(0.2),
                  width: 1.w,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.aspect_ratio_rounded,
                        size: 24.r,
                        color: ResColors.primary,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'ScreenUtil Responsive Base',
                        style: AppTypography.title(
                          color: ResColors.primary,
                          fontSize: 16.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Screen width: ${1.sw.toStringAsFixed(0)}px | Design base: 375x812\n'
                    'Scaling rules: .w (width), .h (height), .r (radius/icon), .sp (fonts).',
                    style: AppTypography.body(
                      color: ResColors.textSecondary,
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // ── Section 1: Redux State & Localization ──────────────────
            Text(
              '1. Redux Global State & Localization',
              style: AppTypography.headline(fontSize: 16.sp),
            ),
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: ResColors.surface,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: ResColors.border, width: 1.w),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.greeting,
                    style: AppTypography.headline(
                      color: ResColors.primary,
                      fontSize: 18.sp,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      StoreConnector<AppState, String>(
                        converter: (store) => store.state.locale,
                        builder: (context, locale) {
                          return Chip(
                            avatar: Icon(Icons.translate, size: 16.r),
                            label: Text(
                              'Locale: $locale',
                              style: AppTypography.label(
                                color: ResColors.onSurface,
                                fontSize: 12.sp,
                              ),
                            ),
                            backgroundColor: ResColors.background,
                            side: BorderSide(color: ResColors.border),
                          );
                        },
                      ),
                      const Spacer(),
                      StoreConnector<AppState, String>(
                        converter: (store) => store.state.locale,
                        builder: (context, locale) {
                          return ElevatedButton.icon(
                            onPressed: () {
                              final nextLocale = locale == 'en' ? 'hi' : 'en';
                              AppStore.dispatch(SetLocaleAction(nextLocale));
                              ShowMessage.info(
                                'Locale switched to: ${nextLocale.toUpperCase()}',
                              );
                            },
                            icon: Icon(Icons.language, size: 18.r),
                            label: Text(
                              l10n.toggleLocale,
                              style: AppTypography.button(fontSize: 13.sp),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ResColors.primary,
                              foregroundColor: ResColors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 10.h,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // ── Section 2: Message Bar / Toasts ────────────────────────
            Text(
              '2. Message Bar / Toasts (ShowMessage)',
              style: AppTypography.headline(fontSize: 16.sp),
            ),
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: ResColors.surface,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: ResColors.border, width: 1.w),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.showSuccess(
                            'Operation completed successfully!',
                          ),
                          icon: Icon(Icons.check_circle_outline, size: 18.r),
                          label: Text('Success', style: AppTypography.button(fontSize: 13.sp)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ResColors.success,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.showError(
                            'An error occurred. Please try again.',
                          ),
                          icon: Icon(Icons.error_outline, size: 18.r),
                          label: Text('Error', style: AppTypography.button(fontSize: 13.sp)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ResColors.error,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.showWarning(
                            'Session warning: Save your work.',
                          ),
                          icon: Icon(Icons.warning_amber_outlined, size: 18.r),
                          label: Text('Warning', style: AppTypography.button(fontSize: 13.sp)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ResColors.warning,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.showInfo(
                            'New system update is available.',
                          ),
                          icon: Icon(Icons.info_outline, size: 18.r),
                          label: Text('Info', style: AppTypography.button(fontSize: 13.sp)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ResColors.info,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // ── Section 3: Common Utils & Dialogs ──────────────────────
            Text(
              '3. Common Utils & Dialog Shell',
              style: AppTypography.headline(fontSize: 16.sp),
            ),
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: ResColors.surface,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: ResColors.border, width: 1.w),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        CommonUtils.showCommonDialog(
                          context,
                          title: 'Confirmation Dialog',
                          subtitle: 'This is a generic reusable dialog shell.',
                          actions: [
                            DialogAction(
                              label: 'Cancel',
                              type: DialogActionType.decline,
                            ),
                            DialogAction(
                              label: 'Confirm',
                              onPressed: (dialogCtx) {
                                Navigator.pop(dialogCtx);
                                ShowMessage.success('Action confirmed!');
                              },
                            ),
                          ],
                        );
                      },
                      icon: Icon(Icons.open_in_new, size: 18.r),
                      label: Text('Open Dialog', style: AppTypography.button(fontSize: 13.sp)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ResColors.secondary,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => CommonUtils.launchWebsite(
                        context,
                        'https://flutter.dev',
                      ),
                      icon: Icon(Icons.public, size: 18.r, color: ResColors.onSurface),
                      label: Text(
                        'Website',
                        style: AppTypography.button(
                          color: ResColors.onSurface,
                          fontSize: 13.sp,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: BorderSide(color: ResColors.border, width: 1.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}
