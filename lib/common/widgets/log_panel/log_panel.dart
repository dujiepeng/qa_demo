import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_colors.dart';
import '../../utils/sdk_log_update_stream.dart';
import 'log_panel_controller.dart';
import 'log_panel_visibility_observer.dart';

class LogPanel extends StatefulWidget {
  final bool isDark;
  final PrepareLogFileForPanelCallback? prepareLogFile;
  final ReadLogPanelStateCallback? readLogState;
  final LogUpdateStreamFactory? logUpdateStreamFactory;
  final bool enableFallbackPolling;
  const LogPanel({
    super.key,
    required this.isDark,
    this.prepareLogFile,
    this.readLogState,
    this.logUpdateStreamFactory,
    this.enableFallbackPolling = true,
  });

  @override
  State<LogPanel> createState() => _LogPanelState();
}

class _LogPanelState extends State<LogPanel> with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  late final LogPanelController _controller;
  late final LogPanelVisibilityObserver _visibilityObserver;
  final ScrollController _logScrollController = ScrollController();

  bool _autoScroll = true;
  bool _hasPendingNewLogs = false;

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
    _controller = LogPanelController(
      prepareLogFile: widget.prepareLogFile,
      readLogState: widget.readLogState,
      logUpdateStreamFactory: widget.logUpdateStreamFactory,
      enableFallbackPolling: widget.enableFallbackPolling,
      onStateChanged: _handleControllerStateChanged,
    );
    _visibilityObserver = LogPanelVisibilityObserver(
      onVisibilityChanged: _controller.setMonitoringActive,
    );

    _initializeController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visibilityObserver.attach(context);
  }

  Future<void> _initializeController() async {
    await _controller.initialize();
  }

  void _handleControllerStateChanged() {
    if (!mounted) {
      return;
    }

    setState(() {
      if (!_autoScroll) {
        _hasPendingNewLogs = true;
      }
    });
    if (_autoScroll) {
      _scrollToBottom();
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
    _visibilityObserver.detach();
    _controller.dispose();
    _blinkController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

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
                  if (_hasPendingNewLogs && !_autoScroll)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _autoScroll = true;
                            _hasPendingNewLogs = false;
                          });
                          _scrollToBottom();
                        },
                        icon: const Icon(Icons.fiber_new, size: 16),
                        label: const Text('新日志'),
                      ),
                    ),
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
                                _hasPendingNewLogs = false;
                              }
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
                      if (_controller.content.isNotEmpty) {
                        await Clipboard.setData(
                          ClipboardData(text: _controller.content),
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
                      await _controller.clearLog();
                      if (!mounted) return;
                      setState(() {
                        _autoScroll = true;
                        _hasPendingNewLogs = false;
                      });
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
                  _controller.content,
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
