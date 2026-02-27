import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// 通用的区块标题组件
class CommonSectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;

  const CommonSectionTitle({
    super.key,
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary(isDark),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
