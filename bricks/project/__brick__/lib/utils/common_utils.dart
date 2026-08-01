import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snug_logger/snug_logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:{{project_name}}/resources/res_colors.dart';
import 'package:{{project_name}}/resources/app_typography.dart';
import 'package:{{project_name}}/utils/show_message.dart';

/// Style intent for a dialog action button.
enum DialogActionType { primary, decline }

/// Configuration for a single dialog action button.
class DialogAction {
  const DialogAction({
    required this.label,
    this.onPressed,
    this.type = DialogActionType.primary,
  });

  final String label;

  /// Receives the dialog's own [BuildContext] so callers can pop it.
  /// If null, tapping just pops the dialog with no result.
  final void Function(BuildContext dialogContext)? onPressed;

  final DialogActionType type;
}

class CommonUtils {
  CommonUtils._();

  /// Dismisses the software keyboard globally.
  static void hideKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  /// Opens the device phone dialer.
  static Future<bool> launchPhone(BuildContext context, String? phone) async {
    if (phone == null || phone.trim().isEmpty) return false;

    final sanitized = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (sanitized.isEmpty) return false;

    final uri = Uri(scheme: 'tel', path: sanitized);
    return _launchUrl(uri, fallbackMessage: 'Could not open phone dialer.');
  }

  /// Opens the default email client.
  static Future<bool> launchEmail(BuildContext context, String? email) async {
    if (email == null || email.trim().isEmpty) return false;

    final address = email.replaceFirst(RegExp(r'^mailto:'), '').trim();
    if (address.isEmpty) return false;

    final uri = Uri(
      scheme: 'mailto',
      path: address,
      query: _encodeMailtoQuery({'subject': 'Support Request'}),
    );

    return _launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      fallbackMessage: 'Could not open email client.',
    );
  }

  /// Opens a website URL in an external browser.
  static Future<bool> launchWebsite(BuildContext context, String? website) async {
    if (website == null || website.trim().isEmpty) return false;

    var url = website.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    return _launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      fallbackMessage: 'Could not open website.',
    );
  }

  static String? _encodeMailtoQuery(Map<String, String> params) {
    final parts = <String>[];
    params.forEach((key, value) {
      parts.add('${Uri.encodeComponent(key)}=${Uri.encodeComponent(value)}');
    });
    return parts.isEmpty ? null : parts.join('&');
  }

  static Future<bool> _launchUrl(
    Uri uri, {
    LaunchMode mode = LaunchMode.platformDefault,
    String? fallbackMessage,
  }) async {
    try {
      final launched = await launchUrl(uri, mode: mode);
      if (launched) return true;
    } catch (e) {
      snugLog('launchUrl failed for $uri: $e', logType: LogType.error);
    }

    if (fallbackMessage != null && fallbackMessage.isNotEmpty) {
      ShowMessage.error(fallbackMessage);
    }
    return false;
  }

  /// Generic reusable dialog shell with ScreenUtil responsive scaling.
  static Future<T?> showCommonDialog<T>(
    BuildContext context, {
    required String title,
    String? subtitle,
    Widget? description,
    List<DialogAction> actions = const [],
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: ResColors.black.withOpacity(0.5),
      builder: (dialogContext) => Dialog(
        backgroundColor: ResColors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: ResColors.white,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.headline(color: ResColors.textPrimary),
              ),
              if (subtitle != null) ...[
                SizedBox(height: 10.h),
                Text(
                  subtitle,
                  style: AppTypography.body(color: ResColors.textSecondary),
                ),
              ],
              if (description != null) ...[
                SizedBox(height: 12.h),
                description,
              ],
              if (actions.isNotEmpty) ...[
                SizedBox(height: 20.h),
                Row(
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (actions[i].onPressed != null) {
                              actions[i].onPressed!(dialogContext);
                            } else {
                              Navigator.pop(dialogContext);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                actions[i].type == DialogActionType.decline
                                    ? ResColors.error
                                    : ResColors.primary,
                            foregroundColor: ResColors.white,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            actions[i].label,
                            style: AppTypography.button(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
