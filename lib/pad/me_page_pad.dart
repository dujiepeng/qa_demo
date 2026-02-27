import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../common/widgets/me_page_content.dart';
import 'package:chat_uikit_theme/chat_uikit_theme.dart';

class MePagePad extends StatelessWidget {
  final bool isDark;
  const MePagePad({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 顶层工具栏 (仅标题)
        Material(
          color: isDark
              ? ChatUIKitTheme.instance.color.neutralColor1
              : ChatUIKitTheme.instance.color.neutralColor98,
          child: Container(
            height: 70,
            padding: const EdgeInsets.only(top: 20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.glassBorder(isDark),
                  width: 0.5,
                ),
              ),
            ),
            child: Text(
              '设置',
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const Expanded(child: MePageContent(showAppBar: false)),
      ],
    );
  }
}
