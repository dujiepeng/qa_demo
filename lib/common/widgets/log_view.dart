import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// 日志显示样式
enum LogStyle {
  none,
  lineThrough, // 划掉样式
}

/// 日志条目模型
/// [content] 和 [color] 为可变字段，支持外部通过 [LogController.updateEntry] 更新。
class LogEntry {
  String content; // 可变：支持外部修改文字内容
  final String timestamp;
  Color? color; // 可变：支持外部修改颜色
  final Object? attachment;
  final String? tag;
  LogStyle style; // 可变：支持外部修改样式

  LogEntry({
    required this.content,
    required this.timestamp,
    this.color,
    this.attachment,
    this.tag,
    this.style = LogStyle.none,
  });

  LogEntry copyWith({
    String? content,
    String? timestamp,
    Color? color,
    Object? attachment,
    String? tag,
    LogStyle? style,
  }) {
    return LogEntry(
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      color: color ?? this.color,
      attachment: attachment ?? this.attachment,
      tag: tag ?? this.tag,
      style: style ?? this.style,
    );
  }
}

/// 日志菜单项模型
class LogMenuItem {
  final String title;
  final VoidCallback onTap; // 修改为返回 Future<LogStyle?>
  LogMenuItem({required this.title, required this.onTap});
}

/// 日志控制器，用于管理日志数据的增加、清空和监听
class LogController extends ChangeNotifier {
  final List<LogEntry> _logs = [];

  List<LogEntry> get entities => List.unmodifiable(_logs);

  void changeEntities(
    List<LogEntry> entries, {
    String? content,
    Color? color,
    LogStyle? style,
  }) {
    for (var element in entries) {
      if (content != null) element.content = content;
      if (color != null) element.color = color;
      if (style != null) element.style = style;
    }
    notifyListeners();
  }

  /// 添加一条日志，返回被插入的 [LogEntry] 引用。
  /// 调用方可持有该引用，后续通过 [updateEntry] / [removeEntry] 精确操作该条日志。
  LogEntry addLog(String str, {Color? color, Object? attachment, String? tag}) {
    final now = DateTime.now();
    final timeStr =
        '(${now.millisecondsSinceEpoch}) ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';

    final entry = LogEntry(
      content: str,
      timestamp: timeStr,
      color: color,
      attachment: attachment,
      tag: tag,
    );
    _logs.insert(0, entry);
    notifyListeners();
    // 返回引用，便于调用方后续通过 updateEntry / removeEntry 精确控制该条日志
    return entry;
  }

  /// 更新指定 [LogEntry] 的内容、颜色或样式，并通知视图刷新。
  /// 使用对象引用匹配，无需额外 ID 字段。
  void updateEntry(
    LogEntry entry, {
    String? content,
    Color? color,
    LogStyle? style,
  }) {
    // 检查该条目是否仍存在于列表中
    if (!_logs.contains(entry)) return;
    if (content != null) entry.content = content;
    if (color != null) entry.color = color;
    if (style != null) entry.style = style;
    notifyListeners();
  }

  /// 从日志列表中删除指定的 [LogEntry]，并通知视图刷新。
  void removeEntry(LogEntry entry) {
    if (_logs.remove(entry)) {
      notifyListeners();
    }
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
  final VoidCallback? menuShowCallback;

  const LogView({
    super.key,
    required this.controller,
    required this.isDark,
    this.menuBuilder,
    this.menuShowCallback,
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
              controller.entities.isEmpty
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
                        itemCount: controller.entities.length,
                        itemBuilder: (context, index) {
                          final entry = controller.entities[index];
                          return GestureDetector(
                            onLongPressStart: (details) async {
                              if (menuBuilder == null) return;
                              final items = menuBuilder!(entry);
                              if (items.isEmpty) return;
                              menuShowCallback?.call();
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
                                  decoration:
                                      entry.style == LogStyle.lineThrough
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
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
