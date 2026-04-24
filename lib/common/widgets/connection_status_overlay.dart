import 'package:flutter/material.dart';

import '../session_scope.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_settings.dart';
import '../utils/connection_status_overlay_controller.dart';

class ConnectionStatusOverlay extends StatelessWidget {
  const ConnectionStatusOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = maybeReadProvider<ConnectionStatusOverlayController>(
      context,
    );
    if (controller == null || !controller.isVisible) {
      return const SizedBox.shrink();
    }

    final isDark = maybeReadProvider<AppSettings>(context)?.isDarkMode ?? true;
    return IgnorePointer(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xF2191B20) : const Color(0xF7FFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder(isDark)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            controller.message!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary(isDark),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
