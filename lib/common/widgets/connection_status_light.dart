import 'package:flutter/material.dart';

import '../session_scope.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_settings.dart';
import '../utils/connection_status_overlay_controller.dart';

class ConnectionStatusLight extends StatelessWidget {
  const ConnectionStatusLight({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = maybeReadProvider<AppSettings>(context)?.isDarkMode ?? true;
    final isConnected =
        maybeReadProvider<ConnectionStatusOverlayController>(context)
            ?.isConnected;

    final Color fillColor = switch (isConnected) {
      true => Colors.green,
      false => Colors.red,
      null => AppColors.textSecondary(isDark),
    };

    final String tooltip = switch (isConnected) {
      true => '连接正常',
      false => '连接异常',
      null => '连接状态未知',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: fillColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.6 : 0.9),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: fillColor.withValues(alpha: 0.32),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
