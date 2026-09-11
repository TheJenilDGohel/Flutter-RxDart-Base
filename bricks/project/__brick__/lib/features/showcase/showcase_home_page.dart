// DEMO ONLY — delete lib/features/showcase/ and update main.dart's home route
// once you understand the architecture.
//
// This showcase demonstrates:
// 1. Redux global session state + localization persistence (EN/HI toggle)
// 2. Direct ScreenUtil scaling (.w, .h, .r, .sp) on standard Flutter widgets
// 3. Rich Form & Action Widgets (CommonButton with loading, AppTextFormField with eye toggle)
// 4. Interactive Overlays & Modals (AppDialog confirmation, status, and async confirm)
// 5. Prebuilt Toast/Message Bar helper (ShowMessage)
// 6. Prebuilt CommonUtils (keyboard hide, launcher recipes)
// 7. Context Extensions (context.l10n)

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
import 'package:{{project_name}}/utils/widgets/ui/ui_components.dart';

class ShowcaseHomePage extends StatefulWidget {
  const ShowcaseHomePage({super.key});

  @override
  State<ShowcaseHomePage> createState() => _ShowcaseHomePageState();
}

class _ShowcaseHomePageState extends State<ShowcaseHomePage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isButtonLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
            AppCard(
              backgroundColor: ResColors.primary.withOpacity(0.06),
              borderColor: ResColors.primary.withOpacity(0.2),
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
                        'ScreenUtil Scaling',
                        style: AppTypography.headline(color: ResColors.primary),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'All layout sizes use .w, .h, .r, and .sp extensions for responsive scaling across devices.',
                    style: AppTypography.body(color: ResColors.textSecondary),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // ── Redux Global State: Localization ──────────────────────
            Text(
              'Global State (Redux): Localization',
              style: AppTypography.subheading(color: ResColors.textPrimary),
            ),
            SizedBox(height: 8.h),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The current locale is held in Redux and automatically persisted to SharedPreferences:',
                    style: AppTypography.body(color: ResColors.textSecondary),
                  ),
                  SizedBox(height: 12.h),
                  StoreConnector<AppState, String>(
                    converter: (store) => store.state.locale,
                    builder: (context, locale) {
                      return Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                AppStore.dispatch(const SetLocaleAction('en'));
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: locale == 'en'
                                    ? ResColors.primary.withOpacity(0.1)
                                    : ResColors.transparent,
                                side: BorderSide(
                                  color: locale == 'en'
                                      ? ResColors.primary
                                      : ResColors.border,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              child: Text(
                                'English (EN)',
                                style: AppTypography.button(
                                  color: locale == 'en'
                                      ? ResColors.primary
                                      : ResColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                AppStore.dispatch(const SetLocaleAction('hi'));
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: locale == 'hi'
                                    ? ResColors.primary.withOpacity(0.1)
                                    : ResColors.transparent,
                                side: BorderSide(
                                  color: locale == 'hi'
                                      ? ResColors.primary
                                      : ResColors.border,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              child: Text(
                                'हिंदी (HI)',
                                style: AppTypography.button(
                                  color: locale == 'hi'
                                      ? ResColors.primary
                                      : ResColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // ── Form & Action Widgets ─────────────────────────────────
            Text(
              'Production Form & Button Toolkit',
              style: AppTypography.subheading(color: ResColors.textPrimary),
            ),
            SizedBox(height: 8.h),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextFormField(
                    controller: _emailController,
                    labelText: 'Email Address',
                    hintText: 'user@example.com',
                    prefixIcon: const Icon(Icons.email_outlined, color: ResColors.textSecondary),
                  ),
                  SizedBox(height: 16.h),
                  AppTextFormField(
                    controller: _passwordController,
                    labelText: 'Password',
                    hintText: 'Enter secret password',
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock_outline, color: ResColors.textSecondary),
                  ),
                  SizedBox(height: 20.h),
                  CommonButton(
                    text: 'Submit with Loading State',
                    loading: _isButtonLoading,
                    prefix: const Icon(Icons.send, size: 18, color: ResColors.white),
                    onPressed: () async {
                      CommonUtils.hideKeyboard();
                      setState(() => _isButtonLoading = true);
                      await Future.delayed(const Duration(seconds: 2));
                      if (mounted) {
                        setState(() => _isButtonLoading = false);
                        ShowMessage.success('Form submitted successfully!');
                      }
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // ── Dialogs & Overlays ────────────────────────────────────
            Text(
              'Standardized Dialogs (AppDialog)',
              style: AppTypography.subheading(color: ResColors.textPrimary),
            ),
            SizedBox(height: 8.h),
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            AppDialog.showConfirmation(
                              context: context,
                              title: 'Confirm Action',
                              message: 'Do you want to proceed with this operation?',
                              onConfirm: () => ShowMessage.info('Confirmed!'),
                            );
                          },
                          child: const Text('Confirm Dialog'),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            AppDialog.showStatus(
                              context: context,
                              title: 'Status Update',
                              message: 'Operation completed with positive results.',
                            );
                          },
                          child: const Text('Status Alert'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  OutlinedButton(
                    onPressed: () {
                      AppDialog.showAsyncConfirm(
                        context: context,
                        title: 'Async Mutation',
                        message: 'This dialog stays open with a spinner while an async task completes.',
                        onConfirmAsync: () async {
                          await Future.delayed(const Duration(seconds: 2));
                          ShowMessage.success('Async task finished!');
                          return true;
                        },
                      );
                    },
                    child: const Center(child: Text('Async Confirm Dialog (with Spinner)')),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // ── Prebuilt ShowMessage Toasts ───────────────────────────
            Text(
              'ShowMessage Toast Notifications',
              style: AppTypography.subheading(color: ResColors.textPrimary),
            ),
            SizedBox(height: 8.h),
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ShowMessage.success('Operation succeeded!');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ResColors.success,
                            foregroundColor: ResColors.white,
                          ),
                          child: const Text('Success'),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ShowMessage.error('Something went wrong.');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ResColors.error,
                            foregroundColor: ResColors.white,
                          ),
                          child: const Text('Error'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ShowMessage.warning('Proceed with caution.');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ResColors.warning,
                            foregroundColor: ResColors.white,
                          ),
                          child: const Text('Warning'),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ShowMessage.info('Here is a helpful note.');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ResColors.info,
                            foregroundColor: ResColors.white,
                          ),
                          child: const Text('Info'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
