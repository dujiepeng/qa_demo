import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// 日志条目模型，包含内容、时间戳和可选背景色
class LogEntry {
  final String content;
  final String timestamp;
  final Color? color;

  LogEntry({required this.content, required this.timestamp, this.color});
}

/// 日志控制器，用于管理日志数据的增加、清空和监听
class LogController extends ChangeNotifier {
  final List<LogEntry> _logs = [];

  List<LogEntry> get logs => List.unmodifiable(_logs);

  /// 添加一条日志
  void addLog(String message, {Color? color}) {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';

    _logs.insert(
      0,
      LogEntry(content: message, timestamp: timeStr, color: color),
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
class LogView extends StatefulWidget {
  final LogController controller;
  final bool isDark;

  const LogView({super.key, required this.controller, required this.isDark});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return Container(
          height: 400,
          decoration: BoxDecoration(
            color: AppColors.inputBackground(widget.isDark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.glassBorder(widget.isDark)),
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
                      '操作日志',
                      style: TextStyle(
                        color: AppColors.textPrimary(widget.isDark),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        size: 20,
                        color: AppColors.textSecondary(widget.isDark),
                      ),
                      tooltip: '清空日志',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => widget.controller.clearLogs(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.glassBorder(widget.isDark)),
              Expanded(
                child: widget.controller.logs.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            '暂无日志',
                            style: TextStyle(
                              color: AppColors.textSecondary(widget.isDark),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    : Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(8),
                          itemCount: widget.controller.logs.length,
                          itemBuilder: (context, index) {
                            final entry = widget.controller.logs[index];
                            return GestureDetector(
                              onLongPressStart: (details) async {
                                final position = details.globalPosition;
                                final value = await showMenu<String>(
                                  context: context,
                                  position: RelativeRect.fromLTRB(
                                    position.dx,
                                    position.dy,
                                    position.dx,
                                    position.dy,
                                  ),
                                  items: [
                                    const PopupMenuItem(
                                      value: 'copy',
                                      child: Text('复制'),
                                    ),
                                  ],
                                );

                                if (value == 'copy') {
                                  final text =
                                      '${entry.timestamp}: ${entry.content}';
                                  await Clipboard.setData(
                                    ClipboardData(text: text),
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('已复制到剪贴板'),
                                        duration: Duration(milliseconds: 500),
                                      ),
                                    );
                                  }
                                }
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
                                    color: AppColors.textPrimary(widget.isDark),
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
