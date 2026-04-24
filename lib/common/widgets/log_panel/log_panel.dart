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
  final int maxRetainedCharacters;
  final bool enableFallbackPolling;
  const LogPanel({
    super.key,
    required this.isDark,
    this.prepareLogFile,
    this.readLogState,
    this.logUpdateStreamFactory,
    this.maxRetainedCharacters = maxRetainedLogPanelCharacters,
    this.enableFallbackPolling = true,
  });

  @override
  State<LogPanel> createState() => _LogPanelState();
}

class _LogPanelState extends State<LogPanel> with TickerProviderStateMixin {
  static const double _controlsMaxHeight = 180;
  static const double _controlsMaxHeightRatio = 0.4;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  late final LogPanelController _controller;
  late final LogPanelVisibilityObserver _visibilityObserver;
  final ScrollController _logScrollController = ScrollController();
  final TextEditingController _filterController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _autoScroll = true;
  bool _hasPendingNewLogs = false;
  bool _showFilterField = false;
  bool _showSearchField = false;
  String _filterKeyword = '';
  String _searchKeyword = '';
  String _lastRawContent = '';
  String _lastFilterKeyword = '';
  List<String> _visibleLinesCache = const [];
  List<int> _searchMatchIndices = const [];
  int _currentSearchMatchIndex = -1;

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
      maxRetainedCharacters: widget.maxRetainedCharacters,
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
      _rebuildVisibleLinesCache();
      _refreshSearchMatches();
      if (!_autoScroll) {
        _hasPendingNewLogs = true;
      }
    });
    if (_autoScroll) {
      _scrollToBottom();
    }
  }

  String get _visibleContent => _visibleLinesCache.join('\n');

  List<String> get _visibleLines => _visibleLinesCache;

  void _rebuildVisibleLinesCache() {
    final rawContent = _controller.content;
    final normalizedKeyword = _filterKeyword.trim().toLowerCase();
    if (rawContent == _lastRawContent &&
        normalizedKeyword == _lastFilterKeyword) {
      return;
    }

    _lastRawContent = rawContent;
    _lastFilterKeyword = normalizedKeyword;

    if (rawContent.isEmpty) {
      _visibleLinesCache = const [];
      return;
    }

    final allLines = rawContent.split('\n');
    if (normalizedKeyword.isEmpty) {
      _visibleLinesCache = List.unmodifiable(allLines);
      return;
    }

    _visibleLinesCache = List.unmodifiable(
      allLines.where((line) => line.toLowerCase().contains(normalizedKeyword)),
    );
  }

  void _refreshSearchMatches() {
    final keyword = _searchKeyword.trim().toLowerCase();
    if (keyword.isEmpty) {
      _searchMatchIndices = const [];
      _currentSearchMatchIndex = -1;
      return;
    }

    final matches = <int>[];
    final lines = _visibleLines;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].toLowerCase().contains(keyword)) {
        matches.add(i);
      }
    }
    _searchMatchIndices = matches;
    if (matches.isEmpty) {
      _currentSearchMatchIndex = -1;
      return;
    }
    if (_currentSearchMatchIndex < 0 ||
        _currentSearchMatchIndex >= matches.length) {
      _currentSearchMatchIndex = 0;
    }
    if (!_autoScroll) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSearchMatch();
    });
  }

  void _scrollToSearchMatch() {
    if (!_logScrollController.hasClients || _currentSearchMatchIndex == -1) {
      return;
    }
    final lines = _visibleLines;
    if (lines.isEmpty) {
      return;
    }
    final lineIndex = _searchMatchIndices[_currentSearchMatchIndex];
    final ratio = lines.length <= 1 ? 0.0 : lineIndex / (lines.length - 1);
    final offset = _logScrollController.position.maxScrollExtent * ratio;
    _logScrollController.jumpTo(
      offset.clamp(
        _logScrollController.position.minScrollExtent,
        _logScrollController.position.maxScrollExtent,
      ),
    );
  }

  void _moveToSearchMatch(int delta) {
    if (_searchMatchIndices.isEmpty) {
      return;
    }
    setState(() {
      _currentSearchMatchIndex =
          (_currentSearchMatchIndex + delta) % _searchMatchIndices.length;
      if (_currentSearchMatchIndex < 0) {
        _currentSearchMatchIndex += _searchMatchIndices.length;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSearchMatch();
    });
  }

  Widget _buildSearchableContent(bool isDark) {
    final lines = _visibleLines;
    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      controller: _logScrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final isCurrentMatch =
            _currentSearchMatchIndex != -1 &&
            _searchMatchIndices[_currentSearchMatchIndex] == index;
        return Container(
          width: double.infinity,
          color: isCurrentMatch
              ? (isDark
                    ? Colors.yellow.withValues(alpha: 0.18)
                    : Colors.yellow.withValues(alpha: 0.35))
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: SelectableText(
            lines[index],
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 12,
              color: isDark ? Colors.greenAccent : Colors.black87,
              height: 1.5,
              fontWeight: isCurrentMatch ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        );
      },
    );
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
    _filterController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    _rebuildVisibleLinesCache();
    final visibleContent = _visibleContent;
    final hasFilter = _filterKeyword.trim().isNotEmpty;
    final searchCount = _searchMatchIndices.length;
    final currentSearchDisplay = searchCount == 0
        ? '0/0'
        : '${_currentSearchMatchIndex + 1}/$searchCount';

    return LayoutBuilder(
      builder: (context, constraints) {
        final controlsMaxHeight = (constraints.maxHeight *
                _controlsMaxHeightRatio)
            .clamp(0.0, _controlsMaxHeight);

        return Container(
          color: isDark ? Colors.black87 : Colors.grey[100],
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: controlsMaxHeight),
                child: SingleChildScrollView(
                  primary: false,
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                      Flexible(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_hasPendingNewLogs && !_autoScroll)
                                TextButton.icon(
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
                                        color: _autoScroll
                                            ? null
                                            : Colors.orange,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _autoScroll = !_autoScroll;
                                          if (_autoScroll) {
                                            _hasPendingNewLogs = false;
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
                                icon: Icon(
                                  _showSearchField
                                      ? Icons.search_off_outlined
                                      : Icons.search_outlined,
                                  size: 18,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showSearchField = !_showSearchField;
                                    if (!_showSearchField) {
                                      _searchController.clear();
                                      _searchKeyword = '';
                                      _refreshSearchMatches();
                                    }
                                  });
                                },
                                tooltip: _showSearchField ? '收起搜索' : '搜索日志',
                              ),
                              IconButton(
                                icon: Icon(
                                  _showFilterField
                                      ? Icons.filter_alt_off_outlined
                                      : Icons.filter_alt_outlined,
                                  size: 18,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showFilterField = !_showFilterField;
                                  });
                                },
                                tooltip: _showFilterField ? '收起过滤' : '过滤日志',
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy_all, size: 18),
                                onPressed: () async {
                                  if (visibleContent.isNotEmpty) {
                                    await Clipboard.setData(
                                      ClipboardData(text: visibleContent),
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            hasFilter
                                                ? '过滤日志已复制'
                                                : 'SDK日志已复制',
                                          ),
                                        ),
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
                        ),
                      ),
                    ],
                  ),
                  if (_showFilterField) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _filterController,
                      onChanged: (value) {
                        setState(() {
                          _filterKeyword = value;
                          _rebuildVisibleLinesCache();
                          _refreshSearchMatches();
                        });
                      },
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: '过滤关键字',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: _filterKeyword.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  _filterController.clear();
                                  setState(() {
                                    _filterKeyword = '';
                                    _rebuildVisibleLinesCache();
                                    _refreshSearchMatches();
                                  });
                                },
                              ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                  if (_showSearchField) ...[
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 220,
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                setState(() {
                                  _searchKeyword = value;
                                  _refreshSearchMatches();
                                });
                              },
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: '搜索关键字',
                                hintStyle: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white54 : Colors.black45,
                                ),
                                prefixIcon: const Icon(Icons.search, size: 18),
                                suffixIcon: _searchKeyword.isEmpty
                                    ? null
                                    : IconButton(
                                        icon: const Icon(Icons.close, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchKeyword = '';
                                            _refreshSearchMatches();
                                          });
                                        },
                                      ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currentSearchDisplay,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_up),
                            onPressed: searchCount == 0
                                ? null
                                : () => _moveToSearchMatch(-1),
                            tooltip: '上一个',
                          ),
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down),
                            onPressed: searchCount == 0
                                ? null
                                : () => _moveToSearchMatch(1),
                            tooltip: '下一个',
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
                  ),
                ),
              ),
              const Divider(),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification &&
                        notification.dragDetails != null &&
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
                  child: visibleContent.isEmpty && hasFilter
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '无匹配日志',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        )
                      : visibleContent.isEmpty
                      ? const SizedBox.shrink()
                      : _buildSearchableContent(isDark),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
