import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

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
    final padding = EdgeInsets.only(
      top: showAppBar ? (kToolbarHeight + 60) : 20,
      left: 15,
      right: 15,
      bottom: 30,
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: appBar,
      body: Container(
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
                      padding: padding,
                      child: controlPanel,
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.glassBorder(isDark).withValues(alpha: 0.2),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(padding: padding, child: logPanel),
                  ),
                ],
              );
            }
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: padding,
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
    );
  }
}
