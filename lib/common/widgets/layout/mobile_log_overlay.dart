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
    // 监听设置变化
    final settings = context.watch<AppSettings>();
    final isDark = settings.isDarkMode;

    // 重要：使用 Overlay 显式包裹
    // 因为此组件在 MaterialApp 的 builder 中定义，位于根 Navigator 的外部。
    // 如果不显式提供 Overlay，子路由中的 Tooltip, PopupMenu 等浮层组件将无法找到 Overlay 导致崩溃。
    return Scaffold(
      backgroundColor: Colors.transparent, // 避免遮挡底层背景
      resizeToAvoidBottomInset: false, // 防止键盘弹出时挤压日志面板
      body: Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (context) => Column(
              children: [
                // 上半部分: 业务页面（包含主 Navigator），始终保持在树中
                Expanded(
                  child: widget.child,
                ),

                // 下半部分: 日志区域
                if (settings.isLoggedIn)
                  _buildLogWithSplitter(isDark)
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogWithSplitter(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: Column(
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
          // 日志内容
          SizedBox(
            height: _logPanelHeight,
            child: LogPanel(isDark: isDark),
          ),
        ],
      ),
    );
  }
}
