import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// 通用的渐变背景容器
class CommonGradientBackground extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const CommonGradientBackground({
    super.key,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.backgroundStart(isDark),
            AppColors.backgroundEnd(isDark),
          ],
        ),
      ),
      child: child,
    );
  }
}
