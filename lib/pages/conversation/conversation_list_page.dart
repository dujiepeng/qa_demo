import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/pages/single/single_chat_page.dart';
import 'package:qa_flutter/pages/group/group_page.dart';
import 'package:qa_flutter/pages/chatroom/room_page.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_settings.dart';
import '../../common/widgets/common_gradient_background.dart';

/// 会话列表页面
class ConversationListPage extends StatefulWidget {
  final Function(EMConversation conversation)? onItemTap;
  const ConversationListPage({super.key, this.onItemTap});

  @override
  State<ConversationListPage> createState() => _ConversationListPageState();
}

class _ConversationListPageState extends State<ConversationListPage> {
  final _settings = AppSettings();
  final ScrollController _scrollController = ScrollController();
  List<EMConversation> _conversations = [];
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
      final result = await EMClient.getInstance.chatManager
          .fetchConversationsByOptions(
        options: ConversationFetchOptions(pageSize: 30),
      );
      if (mounted) {
        setState(() {
          _conversations = result.data;
          _cursor = result.cursor;
          _hasMore = result.data.length >= 30;
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
      final result = await EMClient.getInstance.chatManager
          .fetchConversationsByOptions(
        options: ConversationFetchOptions(pageSize: 30, cursor: _cursor),
      );
      if (mounted) {
        setState(() {
          _conversations.addAll(result.data);
          _cursor = result.cursor;
          _hasMore = result.data.length >= 30;
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

  /// 删除会话
  Future<void> _deleteConversation(EMConversation conversation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除会话'),
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
        await EMClient.getInstance.chatManager.deleteConversation(
          conversation.id,
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
            ),
            body: (_isLoading && _conversations.isEmpty)
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary(isDark),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _fetchConversations(silent: true),
                    child: _conversations.isEmpty
                        ? CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverFillRemaining(
                                child: Center(
                                  child: Text(
                                    '暂无会话',
                                    style: TextStyle(
                                      color: AppColors.textSecondary(isDark),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            controller: _scrollController,
                            itemCount: _conversations.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index < _conversations.length) {
                                final conv = _conversations[index];
                                return _buildConversationItem(conv, isDark);
                              } else {
                                return _buildLoadingIndicator(isDark);
                              }
                            },
                          ),
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
            const PopupMenuItem(
              value: 'delete',
              child: Text('删除会话', style: TextStyle(color: Colors.red)),
            ),
          ],
        );

        if (value == 'copy_id') {
          _copyToClipboard(conversation.id);
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
                future: conversation.unreadCount(),
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
          title: Text(
            conversation.id,
            style: TextStyle(
              color: AppColors.textPrimary(isDark),
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: FutureBuilder<EMMessage?>(
            future: conversation.latestMessage(),
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
          trailing: Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary(isDark),
          ),
          onTap: () {
            if (widget.onItemTap != null) {
              widget.onItemTap!(conversation);
            } else {
              Widget page;
              switch (conversation.type) {
                case EMConversationType.Chat:
                  page = SingleChatPage(userId: conversation.id);
                  break;
                case EMConversationType.GroupChat:
                  page = GroupPage(groupId: conversation.id);
                  break;
                case EMConversationType.ChatRoom:
                  page = RoomPage(roomId: conversation.id);
                  break;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => page),
              );
            }
          },
        ),
      ),
    );
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
