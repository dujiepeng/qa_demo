import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class LogContentPage extends StatefulWidget {
  final String logPath;

  const LogContentPage({super.key, required this.logPath});

  @override
  State<LogContentPage> createState() => _LogContentPageState();
}

class _LogContentPageState extends State<LogContentPage> {
  String _content = 'Loading...';
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

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

  Future<void> _loadLogContent() async {
    try {
      final file = File(widget.logPath);
      if (await file.exists()) {
        final content = await file.readAsString();
        if (mounted) {
          setState(() {
            _content = content;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _content = 'Log file not found at: ${widget.logPath}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _content = 'Error reading log file: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearLog() async {
    try {
      final file = File(widget.logPath);
      if (await file.exists()) {
        await file.writeAsString('');
        if (mounted) {
          setState(() {
            _content = '';
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('日志已清空')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('清空日志失败: $e')));
      }
    }
  }

  Future<void> _copyToClipboard() async {
    if (_content.isNotEmpty && _content != 'Loading...') {
      await Clipboard.setData(ClipboardData(text: _content));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('日志内容已复制到剪贴板')));
      }
    }
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
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('清理日志'),
                  content: const Text('确定要清空所有日志内容吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
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
          : Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onLongPress: _copyToClipboard,
                  child: SelectableText(
                    _content,
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 12,
                      color: AppColors.textPrimary(isDark),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
