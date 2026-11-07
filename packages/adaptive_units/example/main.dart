import 'package:adaptive_units/adaptive_units.dart';
import 'package:flutter/widgets.dart';

/// A phone design (375x812) that scales on phones and runs 1:1 on tablets.
void main() => runApp(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (context, child) => WidgetsApp(
          color: const Color(0xFF2962FF),
          builder: (context, _) => child!,
        ),
        child: const Card(),
      ),
    );

/// A card sized in design units.
class Card extends StatelessWidget {
  /// Creates the card.
  const Card({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 300.w,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            'Scale ${ScreenUtil().scaleWidth.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 18.sp),
          ),
        ),
      );
}
