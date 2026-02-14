import 'package:flutter/material.dart';
import '../common/utils/responsive_util.dart';

/// 响应式布局容器组件
/// 根据设备类型（手机/平板）自动切换显示不同的布局
class ResponsiveLayout extends StatelessWidget {
  /// 手机端布局
  final Widget mobile;

  /// 平板端布局
  final Widget tablet;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.tablet,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveUtil.isTablet(context) ? tablet : mobile;
  }
}
