import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_settings.dart';
import '../../common/widgets/common_gradient_background.dart';

enum ConversationListFilter { all, pinned, mark1, mark2, mark3 }

typedef ConversationPageLoader =
    Future<EMCursorResult<EMConversation>> Function({
      String? cursor,
      int pageSize,
      ConversationListFilter filter,
    });

typedef LocalConversationsLoader = Future<List<EMConversation>> Function();

/// 会话列表页面
class ConversationListPage extends StatefulWidget {
  const ConversationListPage({
    super.key,
    this.loadConversationsPage,
    this.loadLocalConversations,
    this.unreadCountBuilder,
    this.latestMessageBuilder,
    this.addConversationMark,
    this.removeConversationMark,
  });

  final ConversationPageLoader? loadConversationsPage;
  final LocalConversationsLoader? loadLocalConversations;
  final Future<int> Function(EMConversation conversation)? unreadCountBuilder;
  final Future<EMMessage?> Function(EMConversation conversation)?
  latestMessageBuilder;
  final Future<void> Function(String conversationId, ConversationMarkType mark)?
  addConversationMark;
  final Future<void> Function(String conversationId, ConversationMarkType mark)?
  removeConversationMark;

  @override
  State<ConversationListPage> createState() => _ConversationListPageState();
}

class _ConversationListPageState extends State<ConversationListPage> {
  final _settings = AppSettings();
  final ScrollController _scrollController = ScrollController();
  List<EMConversation> _conversations = [];
  ConversationListFilter _currentFilter = ConversationListFilter.all;
  bool _isLoading = false;
  String? _cursor;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
    // 监听消息变化，实时刷新会话列表
    EMClient.getInstance.chatManager.addEventHandler(
      'conversation_list_page',
      EMChatEventHandler(
        onMessagesReceived: (messages) => _fetchConversations(silent: true),
        onMessagesRead: (messages) => _fetchConversations(silent: true),
        onMessagesDelivered: (messages) => _fetchConversations(silent: true),
        onMessagesRecalled: (messages) => _fetchConversations(silent: true),
        onMessagesRecalledInfo: (infos) => _fetchConversations(silent: true),
        onConversationsUpdate: () => _fetchConversations(silent: true),
        onConversationRead: (from, to) => _fetchConversations(silent: true),
      ),
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    EMClient.getInstance.chatManager.removeEventHandler(
      'conversation_list_page',
    );
    _scrollController.dispose();
    super.dispose();
  }

  /// 获取会话列表
  Future<void> _fetchConversations({bool silent = false}) async {
    if (mounted && !silent) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final result = await _loadConversationsPage(pageSize: 30);
      if (mounted) {
        setState(() {
          _conversations = result.data;
          _cursor = result.cursor;
          _hasMore = _hasMoreConversations(result);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('获取会话列表失败: $e')));
      }
    } finally {
      if (mounted && !silent) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 加载更多会话
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final result = await _loadConversationsPage(
        pageSize: 30,
        cursor: _cursor,
      );
      if (mounted) {
        setState(() {
          _conversations.addAll(result.data);
          _cursor = result.cursor;
          _hasMore = _hasMoreConversations(result);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载更多失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  /// 复制会话 ID
  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已复制: $text'),
          duration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  Future<EMCursorResult<EMConversation>> _loadConversationsPage({
    String? cursor,
    int pageSize = 30,
  }) async {
    final loadConversationsPage = widget.loadConversationsPage;
    final EMCursorResult<EMConversation> result;
    if (loadConversationsPage != null) {
      result = await loadConversationsPage(
        cursor: cursor,
        pageSize: pageSize,
        filter: _currentFilter,
      );
    } else {
      result = await EMClient.getInstance.chatManager
          .fetchConversationsByOptions(
            options: _buildFetchOptions(cursor: cursor, pageSize: pageSize),
          );
    }
    if (cursor != null) return result;
    final shouldLoadLocalConversations =
        widget.loadLocalConversations != null || loadConversationsPage == null;
    if (!shouldLoadLocalConversations) return result;

    final localConversations = await _loadLocalConversations();
    final localChatRoomConversations = localConversations.where(
      (conversation) =>
          conversation.type == EMConversationType.ChatRoom &&
          _matchesCurrentFilter(conversation),
    );
    if (localChatRoomConversations.isEmpty) return result;

    final merged = _mergeConversations(result.data, localChatRoomConversations);
    return EMCursorResult<EMConversation>(result.cursor, merged);
  }

  Future<List<EMConversation>> _loadLocalConversations() {
    final loadLocalConversations = widget.loadLocalConversations;
    if (loadLocalConversations != null) {
      return loadLocalConversations();
    }
    return EMClient.getInstance.chatManager.loadAllConversations();
  }

  List<EMConversation> _mergeConversations(
    List<EMConversation> remoteConversations,
    Iterable<EMConversation> localConversations,
  ) {
    final merged = <EMConversation>[];
    final seenKeys = <String>{};
    for (final conversation in [
      ...remoteConversations,
      ...localConversations,
    ]) {
      final key = '${conversation.type.index}:${conversation.id}';
      if (seenKeys.add(key)) {
        merged.add(conversation);
      }
    }
    return merged;
  }

  bool _hasMoreConversations(EMCursorResult<EMConversation> result) {
    return result.cursor?.isNotEmpty == true;
  }

  bool _matchesCurrentFilter(EMConversation conversation) {
    switch (_currentFilter) {
      case ConversationListFilter.all:
        return true;
      case ConversationListFilter.pinned:
        return conversation.isPinned;
      case ConversationListFilter.mark1:
        return _hasMark(conversation, ConversationMarkType.Type1);
      case ConversationListFilter.mark2:
        return _hasMark(conversation, ConversationMarkType.Type2);
      case ConversationListFilter.mark3:
        return _hasMark(conversation, ConversationMarkType.Type3);
    }
  }

  ConversationFetchOptions _buildFetchOptions({
    String? cursor,
    required int pageSize,
  }) {
    switch (_currentFilter) {
      case ConversationListFilter.all:
        return ConversationFetchOptions(pageSize: pageSize, cursor: cursor);
      case ConversationListFilter.pinned:
        return ConversationFetchOptions.pinned(
          pageSize: pageSize,
          cursor: cursor,
        );
      case ConversationListFilter.mark1:
        return ConversationFetchOptions.mark(
          ConversationMarkType.Type1,
          pageSize: pageSize.clamp(1, 10),
          cursor: cursor,
        );
      case ConversationListFilter.mark2:
        return ConversationFetchOptions.mark(
          ConversationMarkType.Type2,
          pageSize: pageSize.clamp(1, 10),
          cursor: cursor,
        );
      case ConversationListFilter.mark3:
        return ConversationFetchOptions.mark(
          ConversationMarkType.Type3,
          pageSize: pageSize.clamp(1, 10),
          cursor: cursor,
        );
    }
  }

  bool _hasMark(EMConversation conversation, ConversationMarkType mark) {
    return conversation.marks?.contains(mark) ?? false;
  }

  Future<void> _setConversationMark(
    EMConversation conversation,
    ConversationMarkType mark,
  ) async {
    try {
      final addConversationMark = widget.addConversationMark;
      if (addConversationMark != null) {
        await addConversationMark(conversation.id, mark);
      } else {
        await EMClient.getInstance.chatManager
            .addRemoteAndLocalConversationsMark(
              conversationIds: [conversation.id],
              mark: mark,
            );
      }
      _fetchConversations(silent: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('标记失败: $e')));
      }
    }
  }

  Future<void> _removeConversationMark(
    EMConversation conversation,
    ConversationMarkType mark,
  ) async {
    try {
      final removeConversationMark = widget.removeConversationMark;
      if (removeConversationMark != null) {
        await removeConversationMark(conversation.id, mark);
      } else {
        await EMClient.getInstance.chatManager
            .deleteRemoteAndLocalConversationsMark(
              conversationIds: [conversation.id],
              mark: mark,
            );
      }
      _fetchConversations(silent: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('取消标记失败: $e')));
      }
    }
  }

  void _selectFilter(ConversationListFilter filter) {
    if (_currentFilter == filter) return;
    setState(() {
      _currentFilter = filter;
      _cursor = null;
      _hasMore = true;
      _conversations = [];
    });
    _fetchConversations();
  }

  Future<int> _getUnreadCount(EMConversation conversation) {
    final unreadCountBuilder = widget.unreadCountBuilder;
    if (unreadCountBuilder != null) {
      return unreadCountBuilder(conversation);
    }
    return conversation.unreadCount();
  }

  Future<EMMessage?> _getLatestMessage(EMConversation conversation) {
    final latestMessageBuilder = widget.latestMessageBuilder;
    if (latestMessageBuilder != null) {
      return latestMessageBuilder(conversation);
    }
    return conversation.latestMessage();
  }

  /// 切换置顶状态
  Future<void> _togglePin(EMConversation conversation) async {
    try {
      final isPinned = conversation.isPinned;
      await EMClient.getInstance.chatManager.pinConversation(
        conversationId: conversation.id,
        isPinned: !isPinned,
      );
      _fetchConversations(silent: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('操作失败: $e')));
      }
    }
  }

  /// 删除会话
  Future<void> _deleteConversation(EMConversation conversation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除会话及消息'),
        content: Text('确定要删除与 ${conversation.id} 的会话吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await EMClient.getInstance.chatManager.deleteRemoteConversation(
          conversation.id,
          conversationType: conversation.type,
          isDeleteMessage: true,
        );
        _fetchConversations(silent: true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('删除会话失败: $e')));
        }
      }
    }
  }

  /// 设置为已读
  Future<void> _markAsRead(EMConversation conversation) async {
    try {
      await conversation.markAllMessagesAsRead();
      _fetchConversations(silent: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('操作失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final isDark = _settings.isDarkMode;
        return CommonGradientBackground(
          isDark: isDark,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(
                '会话列表',
                style: TextStyle(color: AppColors.textPrimary(isDark)),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: AppColors.textPrimary(isDark)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: '从服务器重新获取',
                  onPressed: _fetchConversations,
                ),
              ],
            ),
            body: Column(
              children: [
                _buildFilterTabs(isDark),
                Expanded(
                  child: (_isLoading && _conversations.isEmpty)
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary(isDark),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _fetchConversations(silent: true),
                          child: _conversations.isEmpty
                              ? CustomScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  slivers: [
                                    SliverToBoxAdapter(
                                      child: _buildInteractionHint(isDark),
                                    ),
                                    SliverFillRemaining(
                                      child: Center(
                                        child: Text(
                                          '暂无会话',
                                          style: TextStyle(
                                            color: AppColors.textSecondary(
                                              isDark,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  controller: _scrollController,
                                  children: [
                                    _buildInteractionHint(isDark),
                                    ...List.generate(
                                      _conversations.length +
                                          (_hasMore ? 1 : 0),
                                      (index) {
                                        if (index < _conversations.length) {
                                          final conv = _conversations[index];
                                          return _buildConversationItem(
                                            conv,
                                            isDark,
                                          );
                                        }
                                        return _buildLoadingIndicator(isDark);
                                      },
                                    ),
                                  ],
                                ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConversationItem(EMConversation conversation, bool isDark) {
    IconData icon;
    String typeStr;
    switch (conversation.type) {
      case EMConversationType.Chat:
        icon = Icons.person_outlined;
        typeStr = '单聊';
        break;
      case EMConversationType.GroupChat:
        icon = Icons.group_outlined;
        typeStr = '群聊';
        break;
      case EMConversationType.ChatRoom:
        icon = Icons.meeting_room_outlined;
        typeStr = '聊天室';
        break;
    }

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
            const PopupMenuItem(value: 'copy_id', child: Text('复制 ID')),
            PopupMenuItem(
              value: 'toggle_pin',
              child: Text(conversation.isPinned ? '取消置顶' : '会话置顶'),
            ),
            PopupMenuItem(
              value: _hasMark(conversation, ConversationMarkType.Type1)
                  ? 'unmark_1'
                  : 'mark_1',
              child: Text(
                _hasMark(conversation, ConversationMarkType.Type1)
                    ? '取消 Mark1'
                    : '标记 Mark1',
              ),
            ),
            PopupMenuItem(
              value: _hasMark(conversation, ConversationMarkType.Type2)
                  ? 'unmark_2'
                  : 'mark_2',
              child: Text(
                _hasMark(conversation, ConversationMarkType.Type2)
                    ? '取消 Mark2'
                    : '标记 Mark2',
              ),
            ),
            PopupMenuItem(
              value: _hasMark(conversation, ConversationMarkType.Type3)
                  ? 'unmark_3'
                  : 'mark_3',
              child: Text(
                _hasMark(conversation, ConversationMarkType.Type3)
                    ? '取消 Mark3'
                    : '标记 Mark3',
              ),
            ),
            PopupMenuItem(
              value: 'mark_as_read',
              child: FutureBuilder<int>(
                future: conversation.unreadCount(),
                builder: (context, snapshot) {
                  return Text(
                    '设置为已读',
                    style: TextStyle(
                      color: (snapshot.data ?? 0) > 0 ? null : Colors.grey,
                    ),
                  );
                },
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('删除会话', style: TextStyle(color: Colors.red)),
            ),
          ],
        );

        if (value == 'copy_id') {
          _copyToClipboard(conversation.id);
        } else if (value == 'toggle_pin') {
          _togglePin(conversation);
        } else if (value == 'mark_1') {
          _setConversationMark(conversation, ConversationMarkType.Type1);
        } else if (value == 'unmark_1') {
          _removeConversationMark(conversation, ConversationMarkType.Type1);
        } else if (value == 'mark_2') {
          _setConversationMark(conversation, ConversationMarkType.Type2);
        } else if (value == 'unmark_2') {
          _removeConversationMark(conversation, ConversationMarkType.Type2);
        } else if (value == 'mark_3') {
          _setConversationMark(conversation, ConversationMarkType.Type3);
        } else if (value == 'unmark_3') {
          _removeConversationMark(conversation, ConversationMarkType.Type3);
        } else if (value == 'mark_as_read') {
          _markAsRead(conversation);
        } else if (value == 'delete') {
          _deleteConversation(conversation);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.inputBackground(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder(isDark)),
        ),
        child: ListTile(
          tileColor: conversation.isPinned
              ? AppColors.primary(isDark).withValues(alpha: 0.05)
              : null,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary(isDark).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary(isDark)),
              ),
              FutureBuilder<int>(
                future: _getUnreadCount(conversation),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data! > 0) {
                    return Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            '${snapshot.data}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          title: Row(
            children: [
              if (conversation.isPinned)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.push_pin,
                    size: 14,
                    color: AppColors.primary(isDark),
                  ),
                ),
              Expanded(
                child: Text(
                  conversation.id,
                  style: TextStyle(
                    color: AppColors.textPrimary(isDark),
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ..._buildMarkBadges(conversation, isDark),
            ],
          ),
          subtitle: FutureBuilder<EMMessage?>(
            future: _getLatestMessage(conversation),
            builder: (context, snapshot) {
              String lastMsgStr = '暂无消息';
              if (snapshot.hasData && snapshot.data != null) {
                final msg = snapshot.data!;
                if (msg.body.type == MessageType.TXT) {
                  lastMsgStr = (msg.body as EMTextMessageBody).content;
                } else {
                  lastMsgStr = '[${msg.body.type.name}]';
                }
              }
              return Text(
                '[$typeStr] $lastMsgStr',
                style: TextStyle(color: AppColors.textSecondary(isDark)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionHint(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary(isDark).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder(isDark)),
      ),
      child: Text(
        '长按会话可复制 ID、置顶、标记、设为已读或删除',
        style: TextStyle(
          color: AppColors.textSecondary(isDark),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFilterTabs(bool isDark) {
    final filterColors = <ConversationListFilter, Color>{
      ConversationListFilter.all: const Color(0xFF23406B),
      ConversationListFilter.pinned: const Color(0xFF6B3F1E),
      ConversationListFilter.mark1: const Color(0xFF3C2F66),
      ConversationListFilter.mark2: const Color(0xFF1F5A4C),
      ConversationListFilter.mark3: const Color(0xFF6A2339),
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: ConversationListFilter.values.map((filter) {
          final selected = filter == _currentFilter;
          final backgroundColor = selected
              ? filterColors[filter]!
              : filterColors[filter]!.withValues(alpha: 0.74);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_filterLabel(filter)),
              selected: selected,
              onSelected: (_) => _selectFilter(filter),
              showCheckmark: false,
              labelStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              selectedColor: backgroundColor,
              backgroundColor: backgroundColor,
              side: BorderSide(
                color: selected
                    ? Colors.white.withValues(alpha: 0.38)
                    : backgroundColor.withValues(alpha: 0.9),
                width: selected ? 2.2 : 1.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              elevation: selected ? 2 : 0,
              pressElevation: 0,
            ),
          );
        }).toList(),
      ),
    );
  }

  String _filterLabel(ConversationListFilter filter) {
    switch (filter) {
      case ConversationListFilter.all:
        return '全部';
      case ConversationListFilter.pinned:
        return '置顶';
      case ConversationListFilter.mark1:
        return 'Mark1';
      case ConversationListFilter.mark2:
        return 'Mark2';
      case ConversationListFilter.mark3:
        return 'Mark3';
    }
  }

  List<Widget> _buildMarkBadges(EMConversation conversation, bool isDark) {
    final badges = <Widget>[];
    final marks = conversation.marks ?? const <ConversationMarkType>[];
    final candidates = <(ConversationMarkType, String)>[
      (ConversationMarkType.Type1, 'Mark1'),
      (ConversationMarkType.Type2, 'Mark2'),
      (ConversationMarkType.Type3, 'Mark3'),
    ];
    for (final candidate in candidates) {
      if (!marks.contains(candidate.$1)) continue;
      badges.add(
        Container(
          margin: const EdgeInsets.only(left: 6),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary(isDark).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            candidate.$2,
            style: TextStyle(
              color: AppColors.primary(isDark),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    return badges;
  }

  Widget _buildLoadingIndicator(bool isDark) {
    if (!_hasMore) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        color: AppColors.primary(isDark),
        strokeWidth: 2,
      ),
    );
  }
}
