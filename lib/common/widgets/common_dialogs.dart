import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import '../../theme/app_colors.dart';

class CommonDialogs {
  /// 显示用户信息弹窗
  static Future<void> showUserInfoDialog(
    BuildContext context,
    bool isDark,
  ) async {
    final currentUser = await EMClient.getInstance.getCurrentUserId();
    final deviceId = await EMClient.getInstance.getCurrentDeviceId();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        title: Text(
          '用户信息',
          style: TextStyle(
            color: AppColors.textPrimary(isDark),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前用户: $currentUser',
              style: TextStyle(color: AppColors.textPrimary(isDark)),
            ),
            const SizedBox(height: 8),
            Text(
              '设备ID: $deviceId',
              style: TextStyle(color: AppColors.textPrimary(isDark)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '确定',
              style: TextStyle(color: AppColors.primary(isDark)),
            ),
          ),
        ],
      ),
    );
  }
}
