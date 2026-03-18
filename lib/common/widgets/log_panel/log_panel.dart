import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import '../../../theme/app_colors.dart';
import 'dart:io';
import 'dart:async';

class LogPanel extends StatefulWidget {
  final bool isDark;
  const LogPanel({super.key, required this.isDark});

  @override
  State<LogPanel> createState() => _LogPanelState();
}

class _LogPanelState extends State<LogPanel> with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  final ScrollController _logScrollController = ScrollController();

  String _sdkLogContent = '正在加载 SDK 日志...';
  Timer? _logTimer;
  String? _lastLogPath;
  bool _autoScroll = true;
  int _lastFileLength = 0;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.2).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    _initAndStartLogSync();
  }

  Future<void> _initAndStartLogSync() async {
    try {
      final logZipPath = await EMClient.getInstance.compressLogs();
      _lastLogPath = logZipPath.replaceFirst('log.gz', 'easemob.log');
      _startLogSync();
    } catch (e) {
      debugPrint('Init log path error: $e');
    }
  }

  void _startLogSync() {
    _logTimer?.cancel();
    _logTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _syncSdkLogs();
    });
  }

  Future<void> _syncSdkLogs() async {
    if (_lastLogPath == null) return;
    try {
      final file = File(_lastLogPath!);
      if (await file.exists()) {
        final stat = await file.stat();
        if (stat.size != _lastFileLength) {
          final content = await file.readAsString();
          if (mounted) {
            setState(() {
              _sdkLogContent = content;
              _lastFileLength = stat.size;
            });
            if (_autoScroll) {
              _scrollToBottom();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Sync SDK logs error: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.jumpTo(
          _logScrollController.position.maxScrollExtent,
        );
      }
    });
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _logScrollController.dispose();
    _logTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    
    if (_autoScroll) {
      _scrollToBottom();
    }

    return Container(
      color: isDark ? Colors.black87 : Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '日志',
                style: TextStyle(
                  color: AppColors.primary(isDark),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  Builder(
                    builder: (context) {
                      if (!_autoScroll) {
                        _blinkController.repeat(reverse: true);
                      } else {
                        _blinkController.stop();
                        _blinkController.value = 0;
                      }

                      return FadeTransition(
                        opacity: _autoScroll
                            ? const AlwaysStoppedAnimation(1.0)
                            : _blinkAnimation,
                        child: IconButton(
                          icon: Icon(
                            _autoScroll
                                ? Icons.pause_circle_outline
                                : Icons.play_circle_outline,
                            size: 18,
                            color: _autoScroll ? null : Colors.orange,
                          ),
                          onPressed: () {
                            setState(() {
                              _autoScroll = !_autoScroll;
                              if (_autoScroll) {
                                _scrollToBottom();
                              }
                            });
                          },
                          tooltip: _autoScroll ? '暂停滚动' : '继续滚动',
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_all, size: 18),
                    onPressed: () async {
                      if (_sdkLogContent.isNotEmpty) {
                        await Clipboard.setData(
                          ClipboardData(text: _sdkLogContent),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('SDK日志已复制')),
                          );
                        }
                      }
                    },
                    tooltip: '复制全部',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () async {
                      if (_lastLogPath != null) {
                        final file = File(_lastLogPath!);
                        if (await file.exists()) {
                          await file.writeAsString('');
                          setState(() {
                            _sdkLogContent = '';
                            _autoScroll = true;
                          });
                        }
                      }
                    },
                    tooltip: '清空日志',
                  ),
                ],
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification &&
                    notification.scrollDelta != null &&
                    notification.scrollDelta! < 0) {
                  if (_autoScroll) {
                    setState(() {
                      _autoScroll = false;
                    });
                  }
                }
                return false;
              },
              child: SingleChildScrollView(
                controller: _logScrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SelectableText(
                  _sdkLogContent,
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 12,
                    color: isDark ? Colors.greenAccent : Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
