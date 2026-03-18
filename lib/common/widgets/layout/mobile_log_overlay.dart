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

    return Material(
      child: Column(
        children: [
          // 上半部分: 实际的业务页面内容
          Expanded(
            child: widget.child,
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
