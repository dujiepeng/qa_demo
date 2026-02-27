import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import '../../theme/app_colors.dart';

/// 日志条目模型，包含内容、时间戳和可选背景色
class LogEntry {
  final String content;
  final String timestamp;
  final Color? color;
  final EMMessage? message;

  LogEntry({
    required this.content,
    required this.timestamp,
    this.color,
    this.message,
  });
}

/// 日志菜单项模型
class LogMenuItem {
  final String title;
  final VoidCallback onTap;
  LogMenuItem({required this.title, required this.onTap});
}

/// 日志控制器，用于管理日志数据的增加、清空和监听
class LogController extends ChangeNotifier {
  final List<LogEntry> _logs = [];

  List<LogEntry> get logs => List.unmodifiable(_logs);

  /// 添加一条日志
  void addLog(String str, {Color? color, EMMessage? message}) {
    final now = DateTime.now();

    final timeStr =
        '(${now.millisecondsSinceEpoch}) ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';

    _logs.insert(
      0,
      LogEntry(
        content: str,
        timestamp: timeStr,
        color: color,
        message: message,
      ),
    );
    notifyListeners();
  }

  /// 清空所有日志
  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }
}

/// 独立的日志视图组件
class LogView extends StatelessWidget {
  final LogController controller;
  final bool isDark;
  final List<LogMenuItem> Function(LogEntry entry)? menuBuilder;

  const LogView({
    super.key,
    required this.controller,
    required this.isDark,
    this.menuBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.inputBackground(isDark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.glassBorder(isDark)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '日志',
                      style: TextStyle(
                        color: AppColors.textPrimary(isDark),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        size: 20,
                        color: AppColors.textSecondary(isDark),
                      ),
                      tooltip: '清空日志',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => controller.clearLogs(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.glassBorder(isDark)),
              controller.logs.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          '暂无日志',
                          style: TextStyle(
                            color: AppColors.textSecondary(isDark),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                  : Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: controller.logs.length,
                        itemBuilder: (context, index) {
                          final entry = controller.logs[index];
                          return GestureDetector(
                            onLongPressStart: (details) async {
                              if (menuBuilder == null) return;
                              final items = menuBuilder!(entry);
                              if (items.isEmpty) return;

                              final position = details.globalPosition;
                              final LogMenuItem? selectedItem =
                                  await showMenu<LogMenuItem>(
                                    context: context,
                                    position: RelativeRect.fromLTRB(
                                      position.dx,
                                      position.dy,
                                      position.dx,
                                      position.dy,
                                    ),
                                    items: items
                                        .map(
                                          (item) => PopupMenuItem<LogMenuItem>(
                                            value: item,
                                            child: Text(item.title),
                                          ),
                                        )
                                        .toList(),
                                  );

                              selectedItem?.onTap();
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: entry.color ?? Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${entry.timestamp}: ${entry.content}',
                                style: TextStyle(
                                  color: AppColors.textPrimary(isDark),
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }
}
