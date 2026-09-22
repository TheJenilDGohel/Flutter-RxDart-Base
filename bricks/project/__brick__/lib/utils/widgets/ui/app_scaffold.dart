import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:{{project_name}}/resources/res_colors.dart';

/// Standard scaffold wrapper with consistent SafeArea, padding, and
/// system UI overlay handling.
///
/// Use this as the outermost widget for every page:
/// ```dart
/// return AppScaffold(
///   appBarTitle: 'My Page',
///   body: MyContent(),
/// );
/// ```
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.appBarTitle,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.actions,
    this.leading,
  });

  final Widget body;
  final String? appBarTitle;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: backgroundColor ?? ResColors.background,
        appBar: appBarTitle != null
            ? AppBar(
                title: Text(appBarTitle!),
                centerTitle: true,
                elevation: 0,
                backgroundColor: ResColors.surface,
                foregroundColor: ResColors.onBackground,
                leading: leading,
                actions: actions,
              )
            : null,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: body,
          ),
        ),
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}
