import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'screen_util.dart';

/// Design-space sizes: `16.w`, `48.h`, `12.r`, `14.sp`.
extension SizeExtension on num {
  /// Width, scaled by [ScreenUtil.scaleWidth].
  double get w => ScreenUtil().setWidth(this);

  /// Height, scaled by [ScreenUtil.scaleHeight].
  double get h => ScreenUtil().setHeight(this);

  /// Radius or square side, scaled by the smaller factor.
  double get r => ScreenUtil().radius(this);

  /// Scaled by the larger factor.
  double get dm => ScreenUtil().diameter(this);

  /// Scaled by both factors.
  double get dg => ScreenUtil().diagonal(this);

  /// Font size, scaled by [ScreenUtil.scaleText]. `Text` still applies the
  /// OS text-size setting on top.
  double get sp => ScreenUtil().setSp(this);

  /// The smaller of this and [sp]: text that may shrink on small phones but
  /// never grows past its design size.
  double get spMin => math.min(toDouble(), sp);

  /// The larger of this and [sp].
  double get spMax => math.max(toDouble(), sp);

  /// This fraction of the window width (`0.5.sw` is half).
  double get sw => ScreenUtil().screenWidth * this;

  /// This fraction of the window height.
  double get sh => ScreenUtil().screenHeight * this;

  /// A vertical gap of [h].
  SizedBox get verticalSpace => SizedBox(height: h);

  /// A horizontal gap of [w].
  SizedBox get horizontalSpace => SizedBox(width: w);
}
