import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'common_gradient_background.dart';

/// 通用的测试页面布局组件
/// 封装了背景渐变、AppBar、以及 Pad/Mobile 的响应式布局
class CommonTestLayout extends StatelessWidget {
  final bool isDark;
  final Widget controlPanel;
  final Widget logPanel;
  final PreferredSizeWidget? appBar;
  final double mobileLogHeight;
  final bool showAppBar;

  const CommonTestLayout({
    super.key,
    required this.isDark,
    required this.controlPanel,
    required this.logPanel,
    this.appBar,
    this.mobileLogHeight = 400,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    // 使用统一的内边距，因为我们将不再使用 extendBodyBehindAppBar
    // 系统会根据是否显示 AppBar 自动处理 Body 的起始位置
    const contentPadding = EdgeInsets.only(
      top: 20,
      left: 15,
      right: 15,
      bottom: 30,
    );

    return CommonGradientBackground(
      isDark: isDark,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: SafeArea(
          // 如果没有 AppBar，则需要顶部安全区域保护
          top: appBar == null,
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        padding: contentPadding,
                        child: controlPanel,
                      ),
                    ),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: AppColors.glassBorder(
                        isDark,
                      ).withValues(alpha: 0.2),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(padding: contentPadding, child: logPanel),
                    ),
                  ],
                );
              }
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: contentPadding,
                    child: Column(
                      children: [
                        controlPanel,
                        const SizedBox(height: 20),
                        SizedBox(height: mobileLogHeight, child: logPanel),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
