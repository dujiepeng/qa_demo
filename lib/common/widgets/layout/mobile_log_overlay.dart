import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_settings.dart';
import '../log_panel/log_panel.dart';

class MobileLogOverlay extends StatefulWidget {
  final Widget child;
  const MobileLogOverlay({super.key, required this.child});

  @override
  State<MobileLogOverlay> createState() => _MobileLogOverlayState();
}

class _MobileLogOverlayState extends State<MobileLogOverlay> {
  // 日志高度
  double _logPanelHeight = 200.0;
  // 最小日志高度
  static const double _minLogHeight = 100.0;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final isDark = settings.isDarkMode;

    // 如果未登录，直接返回子内容（导航栈）
    // 此时背景等一切逻辑由子路由内部组件决定
    if (!settings.isLoggedIn) {
      return widget.child;
    }

    // 登录后，在导航栈下方增加日志区域
    // 使用 Column + Expanded 确保业务逻辑在上方占据剩余空间
    return Material(
      color: Colors.transparent, // 关键：背景设为透明，否则会遮挡子页面的背景
      child: Column(
        children: [
          // 上半部分: 业务页面（Navigator 渲染的内容）
          Expanded(
            child: widget.child,
          ),

          // 下半部分: 包含分割线的日志区域
          _buildLogWithSplitter(isDark),
        ],
      ),
    );
  }

  Widget _buildLogWithSplitter(bool isDark) {
    return Column(
      children: [
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

        // 日志显示区域
        SizedBox(
          height: _logPanelHeight,
          child: LogPanel(isDark: isDark),
        ),
      ],
    );
  }
}
