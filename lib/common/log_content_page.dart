import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import 'utils/log_file_helper.dart';
import 'utils/log_content_loader.dart';

const int maxClipboardLogBytes = 512 * 1024;
const String defaultLogShareDeviceId = 'emulator-5556';
const String defaultLogShareHostDirectory = r'$HOME/Downloads/';

enum FullLogCopyStatus { copiedContent, exportedPath, unavailable }

class FullLogCopyResult {
  const FullLogCopyResult({
    required this.status,
    required this.message,
    this.exportPath,
  });

  final FullLogCopyStatus status;
  final String message;
  final String? exportPath;
}

typedef CopyTextCallback = Future<void> Function(String text);

Future<String> readFullLogFile(String logPath) {
  return File(logPath).readAsString();
}

Future<FullLogCopyResult> copyFullLogForClipboard({
  required String logPath,
  required CopyTextCallback copyText,
  Future<LogFileExportResult> Function(String logPath)? exportLogFile,
  int maxClipboardBytes = maxClipboardLogBytes,
}) async {
  final file = File(logPath);
  if (!await file.exists()) {
    return const FullLogCopyResult(
      status: FullLogCopyStatus.unavailable,
      message: '日志文件不存在，无法复制',
    );
  }

  final content = await readFullLogFile(logPath);
  final contentBytes = utf8.encode(content).length;
  if (contentBytes <= maxClipboardBytes) {
    await copyText(content);
    return const FullLogCopyResult(
      status: FullLogCopyStatus.copiedContent,
      message: '完整日志已复制到剪贴板',
    );
  }

  final export = exportLogFile ?? exportLogFileForSharing;
  final exportResult = await export(logPath);
  final exportPath = exportResult.exportPath;
  if (exportPath == null) {
    return FullLogCopyResult(
      status: FullLogCopyStatus.unavailable,
      message: '日志过大，且导出失败: ${exportResult.message}',
    );
  }

  await copyText(
    buildLogShareText(
      exportPath,
      deviceId: defaultLogShareDeviceId,
      hostTargetDirectory: defaultLogShareHostDirectory,
    ),
  );
  return FullLogCopyResult(
    status: FullLogCopyStatus.exportedPath,
    exportPath: exportPath,
    message: '日志过大，已导出完整日志并复制分享文本到剪贴板',
  );
}

class LogContentPage extends StatefulWidget {
  const LogContentPage({
    super.key,
    required this.logPath,
    this.chunkSizeBytes = 256 * 1024,
    this.exportLogFile,
  });

  final String logPath;
  final int chunkSizeBytes;
  final Future<LogFileExportResult> Function(String logPath)? exportLogFile;

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
  bool _isExporting = false;
  String? _exportedLogPath;

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
    try {
      final result = await copyFullLogForClipboard(
        logPath: widget.logPath,
        copyText: (text) => Clipboard.setData(ClipboardData(text: text)),
        exportLogFile: widget.exportLogFile ?? _defaultExportLogFile,
      );
      if (!mounted) return;

      if (result.exportPath != null) {
        setState(() {
          _exportedLogPath = result.exportPath;
        });
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('复制完整日志失败: $e')));
    }
  }

  Future<void> _copyLogPath() async {
    await Clipboard.setData(ClipboardData(text: widget.logPath));
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('日志路径已复制到剪贴板')));
  }

  Future<void> _exportLogFile() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final export = widget.exportLogFile ?? _defaultExportLogFile;
      final result = await export(widget.logPath);
      if (!mounted) return;

      final exportedPath = result.exportPath;
      if (exportedPath != null) {
        await Clipboard.setData(
          ClipboardData(
            text: buildLogShareText(
              exportedPath,
              deviceId: defaultLogShareDeviceId,
              hostTargetDirectory: defaultLogShareHostDirectory,
            ),
          ),
        );
      }

      setState(() {
        _isExporting = false;
        _exportedLogPath = exportedPath;
      });

      final feedbackMessage = exportedPath == null
          ? result.message
          : '${result.message}，分享文本已复制到剪贴板';
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(feedbackMessage)));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isExporting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('日志导出失败: $e')));
    }
  }

  Future<LogFileExportResult> _defaultExportLogFile(String logPath) {
    return exportLogFileForSharing(sourceLogPath: logPath);
  }

  Future<void> _copyAdbPullCommand() async {
    final exportPath = _exportedLogPath;
    if (exportPath == null) return;

    await Clipboard.setData(
      ClipboardData(
        text: buildLogShareText(
          exportPath,
          deviceId: defaultLogShareDeviceId,
          hostTargetDirectory: defaultLogShareHostDirectory,
        ),
      ),
    );
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('分享文本已复制到剪贴板')));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final content = _isLoading
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
        : Expanded(
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
                      fontFamily: defaultTargetPlatform == TargetPlatform.iOS
                          ? 'Courier'
                          : 'monospace',
                      fontSize: 12,
                      color: AppColors.textPrimary(isDark),
                    ),
                  );
                },
              ),
            ),
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Content'),
        backgroundColor: AppColors.backgroundStart(isDark),
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
            onPressed: _isExporting ? null : _exportLogFile,
            tooltip: '导出完整日志',
          ),
          IconButton(
            icon: const Icon(Icons.terminal_outlined),
            onPressed: _exportedLogPath == null ? null : _copyAdbPullCommand,
            tooltip: '复制 adb pull 命令',
          ),
          IconButton(
            icon: const Icon(Icons.link_outlined),
            onPressed: _copyLogPath,
            tooltip: '复制日志路径',
          ),
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
      body: Column(
        children: [
          if (_exportedLogPath != null)
            Material(
              color: AppColors.inputBackground(isDark),
              child: ListTile(
                dense: true,
                title: Text(
                  '导出路径: $_exportedLogPath',
                  style: TextStyle(
                    color: AppColors.textPrimary(isDark),
                    fontSize: 12,
                  ),
                ),
                subtitle: Text(
                  '可在电脑上执行 adb pull 拉取完整日志',
                  style: TextStyle(color: AppColors.textSecondary(isDark)),
                ),
              ),
            ),
          if (_statusMessage == null && _fileSize > widget.chunkSizeBytes)
            Material(
              color: AppColors.inputBackground(isDark),
              child: ListTile(
                title: Text(
                  _hasMoreContent ? '当前仅显示日志尾部内容' : '日志已完整加载',
                  style: TextStyle(color: AppColors.textPrimary(isDark)),
                ),
                subtitle: Text(
                  '已加载 ${_lines.length} 行',
                  style: TextStyle(color: AppColors.textSecondary(isDark)),
                ),
                trailing: _hasMoreContent
                    ? TextButton(
                        onPressed: () => _loadLogContent(loadMore: true),
                        child: const Text('加载更多'),
                      )
                    : null,
              ),
            ),
          Expanded(child: content),
        ],
      ),
    );
  }
}
