import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import 'async_button.dart';

/// 通用的输入行组件，支持主输入框、可选的重复次数输入框和异步操作按钮
class CommonInputRow extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? buttonText;
  final Future<void> Function()? onPressed;
  final bool isDark;
  final TextEditingController? countController;

  const CommonInputRow({
    super.key,
    required this.controller,
    required this.hintText,
    this.buttonText,
    this.onPressed,
    required this.isDark,
    this.countController,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: TextStyle(color: AppColors.textPrimary(isDark)),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: AppColors.textSecondary(isDark)),
              filled: true,
              fillColor: AppColors.inputBackground(isDark),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.glassBorder(isDark)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.glassBorder(isDark)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary(isDark)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
            ),
          ),
        ),
        if (countController != null) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: TextField(
              controller: countController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textPrimary(isDark)),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '次数',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary(isDark),
                  fontSize: 12,
                ),
                filled: true,
                fillColor: AppColors.inputBackground(isDark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.glassBorder(isDark)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
        if (buttonText != null && onPressed != null) ...[
          const SizedBox(width: 12),
          AsyncButton(
            onPressed: onPressed!,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary(isDark),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(buttonText!),
          ),
        ],
      ],
    );
  }
}
