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

    // 重要：不要让主 Navigator (widget.child) 位于 OverlayEntry 中。
    // 这样可以确保 Hot Reload 时 Navigator 的状态（路由栈）不会丢失或被错误重建。
    // 我们将整个结构包裹在 Scaffold 中提供基础环境。
    return Scaffold(
      backgroundColor: Colors.transparent, // 保持背景透传
      resizeToAvoidBottomInset: false, // 避免键盘弹出时挤压逻辑
      body: Column(
        children: [
          // 上半部分: 业务页面（Navigator 渲染的内容）
          // 直接放在 Column 中，它是组件树的固定成员，Hot Reload 极其稳定。
          Expanded(
            child: widget.child,
          ),

          // 下半部分: 日志区域
          if (settings.isLoggedIn)
            _buildLogArea(isDark)
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildLogArea(bool isDark) {
    // 为日志面板专门提供一个 Overlay 环境，以支持其内部的 Tooltip 和 SnackBar。
    // 这样它既不会干扰主 Navigator，又能满足自身的浮层需求。
    return SizedBox(
      height: _logPanelHeight,
      child: Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (context) => Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  // 可拖动的分割线
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onVerticalDragUpdate: (details) {
                      setState(() {
                        _logPanelHeight -= details.delta.dy;
                        final maxHeight =
                            MediaQuery.of(context).size.height * 0.7;
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
                  // 日志面板
                  Expanded(
                    child: LogPanel(isDark: isDark),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
