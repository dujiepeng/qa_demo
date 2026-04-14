import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import 'utils/log_content_loader.dart';

class LogContentPage extends StatefulWidget {
  const LogContentPage({
    super.key,
    required this.logPath,
    this.chunkSizeBytes = 256 * 1024,
  });

  final String logPath;
  final int chunkSizeBytes;

  @override
  State<LogContentPage> createState() => _LogContentPageState();
}

class _LogContentPageState extends State<LogContentPage> {
  final ScrollController _scrollController = ScrollController();
  List<String> _lines = const [];
  bool _isLoading = true;
  bool _hasMoreContent = false;
  int _loadedFromByte = 0;
  int _fileSize = 0;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadLogContent();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLogContent({bool loadMore = false}) async {
    try {
      final snapshot = await loadLogContentSnapshot(
        logPath: widget.logPath,
        chunkSizeBytes: widget.chunkSizeBytes,
        loadMore: loadMore,
        loadedFromByte: _loadedFromByte,
        existingLines: _lines,
      );

      if (!mounted) return;

      setState(() {
        _lines = snapshot.lines;
        _loadedFromByte = snapshot.loadedFromByte;
        _fileSize = snapshot.fileSize;
        _hasMoreContent = snapshot.hasMoreContent;
        _isLoading = false;
        _statusMessage = snapshot.statusMessage;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error reading log file: $e';
      });
    }
  }

  Future<void> _clearLog() async {
    try {
      final file = File(widget.logPath);
      if (!await file.exists()) {
        return;
      }

      await file.writeAsString('');
      if (!mounted) return;

      setState(() {
        _lines = const [];
        _loadedFromByte = 0;
        _fileSize = 0;
        _hasMoreContent = false;
        _statusMessage = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('日志已清空')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('清空日志失败: $e')));
    }
  }

  Future<void> _copyToClipboard() async {
    if (_lines.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: _lines.join('\n')));
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('当前已加载日志已复制到剪贴板')));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Content'),
        backgroundColor: AppColors.backgroundStart(isDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: _lines.isEmpty ? null : _copyToClipboard,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('清理日志'),
                  content: const Text('确定要清空所有日志内容吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _clearLog();
                      },
                      child: const Text(
                        '确定',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: AppColors.backgroundStart(isDark),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _statusMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _statusMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textPrimary(isDark)),
                ),
              ),
            )
          : Column(
              children: [
                if (_fileSize > widget.chunkSizeBytes)
                  Material(
                    color: AppColors.inputBackground(isDark),
                    child: ListTile(
                      title: Text(
                        _hasMoreContent ? '当前仅显示日志尾部内容' : '日志已完整加载',
                        style: TextStyle(color: AppColors.textPrimary(isDark)),
                      ),
                      subtitle: Text(
                        '已加载 ${_lines.length} 行',
                        style: TextStyle(
                          color: AppColors.textSecondary(isDark),
                        ),
                      ),
                      trailing: _hasMoreContent
                          ? TextButton(
                              onPressed: () => _loadLogContent(loadMore: true),
                              child: const Text('加载更多'),
                            )
                          : null,
                    ),
                  ),
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _lines.length,
                      itemBuilder: (context, index) {
                        final line = _lines[index];
                        return SelectableText(
                          line,
                          style: TextStyle(
                            fontFamily:
                                defaultTargetPlatform == TargetPlatform.iOS
                                ? 'Courier'
                                : 'monospace',
                            fontSize: 12,
                            color: AppColors.textPrimary(isDark),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
