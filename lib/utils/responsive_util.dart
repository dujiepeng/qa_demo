import 'package:flutter/material.dart';

/// 响应式布局工具类
class ResponsiveUtil {
  /// 判定是否为平板/大屏设备的阈值 (dp)
  /// 通常认为最短边大于等于 600dp 的设备为平板
  static const double tabletThreshold = 600.0;

  /// 判断当前设备是否为平板
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= tabletThreshold;
  }

  /// 获取屏幕宽度
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// 获取屏幕高度
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
}
