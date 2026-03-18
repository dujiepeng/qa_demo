import 'package:chat_uikit_theme/chat_uikit_theme.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../common/widgets/log_panel/log_panel.dart';
import 'page_mobile.dart';

class HomePageMobile extends StatefulWidget {
  const HomePageMobile({super.key});

  @override
  State<HomePageMobile> createState() => _HomePageMobileState();
}

class _HomePageMobileState extends State<HomePageMobile> {
  // 日志高度
  double _logPanelHeight = 200.0;
  // 最小日志高度
  static const double _minLogHeight = 100.0;

  @override
  Widget build(BuildContext context) {
    final isDark = ChatUIKitTheme.instance.color.isDark;

    return Scaffold(
      backgroundColor: AppColors.backgroundStart(isDark),
      body: Column(
        children: [
          // 上半部分: 测试导航页面
          const Expanded(
            child: PageMobile(),
          ),

          // 可拖动的分割线
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragUpdate: (details) {
              setState(() {
                _logPanelHeight -= details.delta.dy;
                final maxHeight = MediaQuery.of(context).size.height * 0.7;
                if (_logPanelHeight < _minLogHeight) {
                  _logPanelHeight = _minLogHeight;
                } else if (_logPanelHeight > maxHeight) {
                  _logPanelHeight = maxHeight;
                }
              });
            },
            child: Container(
              height: 20,
              width: double.infinity,
              color: isDark ? Colors.black26 : Colors.grey[300],
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.glassBorder(isDark),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),

          // 下半部分: 日志区域
          SizedBox(
            height: _logPanelHeight,
            child: LogPanel(isDark: isDark),
          ),
        ],
      ),
    );
  }
}
