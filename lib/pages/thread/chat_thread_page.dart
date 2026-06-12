import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import '../../common/mixins/base_mixin.dart';
import '../../common/widgets/common_input_row.dart';
import '../../common/widgets/common_layout.dart';
import '../../common/widgets/common_section_title.dart';
import '../../common/widgets/grid_action_menu.dart';
import '../../common/widgets/log_view.dart';
import '../../common/widgets/log_view_actions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_settings.dart';

typedef ChatThreadCreateCallback =
    Future<EMChatThread> Function({
      required String name,
      required String messageId,
      required String parentId,
    });
typedef ChatThreadFetchCallback =
    Future<EMChatThread?> Function({required String chatThreadId});
typedef ChatThreadPageCallback =
    Future<EMCursorResult<EMChatThread>> Function({String? cursor, int limit});
typedef ChatThreadParentPageCallback =
    Future<EMCursorResult<EMChatThread>> Function({
      required String parentId,
      String? cursor,
      int limit,
    });
typedef ChatThreadMembersCallback =
    Future<EMCursorResult<String>> Function({
      required String chatThreadId,
      String? cursor,
      int limit,
    });
typedef ChatThreadLatestMessagesCallback =
    Future<Map<String, EMMessage>> Function({
      required List<String> chatThreadIds,
    });
typedef ChatThreadJoinCallback =
    Future<EMChatThread> Function({required String chatThreadId});
typedef ChatThreadIdCallback =
    Future<void> Function({required String chatThreadId});
typedef ChatThreadRemoveMemberCallback =
    Future<void> Function({
      required String memberId,
      required String chatThreadId,
    });
typedef ChatThreadRenameCallback =
    Future<void> Function({
      required String chatThreadId,
      required String newName,
    });
typedef ChatThreadMessageSender = Future<EMMessage> Function(EMMessage message);
typedef ChatThreadHistoryFetcher =
    Future<EMCursorResult<EMMessage>> Function({
      required String threadId,
      String? cursor,
      int pageSize,
    });
typedef ChatThreadConversationGetter =
    Future<EMConversation?> Function({required String threadId});
typedef ChatThreadLocalMessagesLoader =
    Future<List<EMMessage>> Function({
      required EMConversation conversation,
      String startMsgId,
      int loadCount,
    });
typedef ChatThreadMessageRecaller =
    Future<void> Function({required String messageId});

const chatThreadEventHandlerId = 'thread_test';
const chatThreadMessageEventHandlerId = 'thread_message_test';

List<String>? parseChatThreadIdList(String rawValue) {
  final list = rawValue
      .split(RegExp(r'[\s,，;；]+'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList();
  return list.isEmpty ? null : list;
}

class ChatThreadTestController {
  ChatThreadTestController({
    this.createChatThread,
    this.fetchChatThread,
    this.fetchChatThreadMembers,
    this.fetchChatThreadsWithParentId,
    this.fetchJoinedChatThreads,
    this.fetchJoinedChatThreadsWithParentId,
    this.fetchLatestMessageWithChatThreads,
    this.joinChatThread,
    this.leaveChatThread,
    this.destroyChatThread,
    this.removeMemberFromChatThread,
    this.updateChatThreadName,
    this.sendMessage,
    this.fetchThreadHistoryMessages,
    this.getThreadConversation,
    this.loadThreadLocalMessages,
    this.recallMessage,
  });

  final _eventHandlers = <String, EMChatThreadEventHandler>{};
  final _chatEventHandlers = <String, EMChatEventHandler>{};
  final ChatThreadCreateCallback? createChatThread;
  final ChatThreadFetchCallback? fetchChatThread;
  final ChatThreadMembersCallback? fetchChatThreadMembers;
  final ChatThreadParentPageCallback? fetchChatThreadsWithParentId;
  final ChatThreadPageCallback? fetchJoinedChatThreads;
  final ChatThreadParentPageCallback? fetchJoinedChatThreadsWithParentId;
  final ChatThreadLatestMessagesCallback? fetchLatestMessageWithChatThreads;
  final ChatThreadJoinCallback? joinChatThread;
  final ChatThreadIdCallback? leaveChatThread;
  final ChatThreadIdCallback? destroyChatThread;
  final ChatThreadRemoveMemberCallback? removeMemberFromChatThread;
  final ChatThreadRenameCallback? updateChatThreadName;
  final ChatThreadMessageSender? sendMessage;
  final ChatThreadHistoryFetcher? fetchThreadHistoryMessages;
  final ChatThreadConversationGetter? getThreadConversation;
  final ChatThreadLocalMessagesLoader? loadThreadLocalMessages;
  final ChatThreadMessageRecaller? recallMessage;

  void addEventHandler(String id, EMChatThreadEventHandler handler) {
    _eventHandlers[id] = handler;
  }

  void removeEventHandler(String id) {
    _eventHandlers.remove(id);
  }

  EMChatThreadEventHandler? getEventHandler(String id) => _eventHandlers[id];

  EMChatEventHandler? getChatEventHandler(String id) => _chatEventHandlers[id];

  void addChatEventHandler(String id, EMChatEventHandler handler) {
    _chatEventHandlers[id] = handler;
  }

  void removeChatEventHandler(String id) {
    _chatEventHandlers.remove(id);
  }

  void clearEventHandlers() {
    _eventHandlers.clear();
    _chatEventHandlers.clear();
  }
}

class ChatThreadPage extends StatefulWidget {
  const ChatThreadPage({
    super.key,
    this.showAppBar = true,
    this.controller,
    this.parentGroupId,
    this.parentMessageId,
  });

  final bool showAppBar;
  final ChatThreadTestController? controller;
  final String? parentGroupId;
  final String? parentMessageId;

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage> with BaseMixin {
  final _settings = AppSettings();
  final _logController = LogController();
  final _threadIdController = TextEditingController();
  final _parentIdController = TextEditingController();
  final _messageIdController = TextEditingController();
  final _threadNameController = TextEditingController();
  final _memberIdController = TextEditingController();
  final _threadIdsController = TextEditingController();
  final _messageContentController = TextEditingController(text: 'hello thread');

  @override
  LogController get logController => _logController;

  @override
  void initState() {
    super.initState();
    _parentIdController.text = widget.parentGroupId?.trim() ?? '';
    _messageIdController.text = widget.parentMessageId?.trim() ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _prefillThreadIdFromParent();
      }
    });
  }

  @override
  void dispose() {
    _threadIdController.dispose();
    _parentIdController.dispose();
    _messageIdController.dispose();
    _threadNameController.dispose();
    _memberIdController.dispose();
    _threadIdsController.dispose();
    _messageContentController.dispose();
    super.dispose();
  }

  EMChatThreadManager get _manager => EMClient.getInstance.chatThreadManager;

  bool get _hasFixedParentId =>
      (widget.parentGroupId?.trim().isNotEmpty ?? false);
  bool get _hasFixedParentMessageId =>
      (widget.parentMessageId?.trim().isNotEmpty ?? false);
  String get _threadId => _threadIdController.text.trim();
  String get _parentId => _parentIdController.text.trim();
  String get _messageId => _messageIdController.text.trim();
  String get _threadName => _threadNameController.text.trim();
  String get _memberId => _memberIdController.text.trim();
  String get _messageContent => _messageContentController.text.trim();

  void _addEventHandler() {
    final handler = EMChatThreadEventHandler(
      onChatThreadCreate: (event) => addReceiveLog(_eventLog('创建', event)),
      onChatThreadDestroy: (event) => addReceiveLog(_eventLog('解散', event)),
      onChatThreadUpdate: (event) => addReceiveLog(_eventLog('更新', event)),
      onUserKickOutOfChatThread: (event) =>
          addReceiveLog(_eventLog('移除成员', event)),
    );
    final controller = widget.controller;
    if (controller != null) {
      controller.addEventHandler(chatThreadEventHandlerId, handler);
    } else {
      _manager.addEventHandler(chatThreadEventHandlerId, handler);
    }
    final chatHandler = EMChatEventHandler(
      onMessagesReceived: _handleMessagesReceived,
      onMessagesRecalledInfo: _handleMessagesRecalledInfo,
    );
    if (controller != null) {
      controller.addChatEventHandler(
        chatThreadMessageEventHandlerId,
        chatHandler,
      );
    } else {
      EMClient.getInstance.chatManager.addEventHandler(
        chatThreadMessageEventHandlerId,
        chatHandler,
      );
    }
    addLog('Thread 事件监听已注册: $chatThreadEventHandlerId');
  }

  void _removeEventHandler() {
    final controller = widget.controller;
    if (controller != null) {
      controller.removeEventHandler(chatThreadEventHandlerId);
    } else {
      _manager.removeEventHandler(chatThreadEventHandlerId);
    }
    if (controller != null) {
      controller.removeChatEventHandler(chatThreadMessageEventHandlerId);
    } else {
      EMClient.getInstance.chatManager.removeEventHandler(
        chatThreadMessageEventHandlerId,
      );
    }
    addLog('Thread 事件监听已移除: $chatThreadEventHandlerId');
  }

  void _getEventHandler() {
    final handler =
        widget.controller?.getEventHandler(chatThreadEventHandlerId) ??
        _manager.getEventHandler(chatThreadEventHandlerId);
    addLog('Thread 事件监听存在: ${handler != null}');
  }

  void _clearEventHandlers() {
    final controller = widget.controller;
    if (controller != null) {
      controller.clearEventHandlers();
    } else {
      _manager.clearEventHandlers();
      EMClient.getInstance.chatManager.removeEventHandler(
        chatThreadMessageEventHandlerId,
      );
    }
    addLog('Thread 事件监听已清空');
  }

  void _handleMessagesReceived(List<EMMessage> messages) {
    for (final message in messages) {
      if (message.isChatThreadMessage && message.conversationId == _threadId) {
        addReceiveLog(
          '收到 Thread 消息: threadId=${message.conversationId}, msgId=${message.msgId}, body=${message.body.toJson()}',
          attachment: message,
          tag: 'message',
        );
      }
    }
  }

  void _handleMessagesRecalledInfo(List<RecallMessageInfo> infos) {
    for (final info in infos) {
      final recalled = info.recallMessage;
      final isCurrentThread =
          info.conversationId == _threadId ||
          (recalled != null &&
              recalled.isChatThreadMessage &&
              recalled.conversationId == _threadId);
      if (!isCurrentThread) continue;
      addReceiveLog(
        '收到 Thread 撤回: threadId=${info.conversationId ?? recalled?.conversationId}, msgId=${info.recallMessageId}, by=${info.recallBy}, ext=${info.ext}',
        attachment: recalled,
        tag: 'message',
      );
    }
  }

  String _eventLog(String action, EMChatThreadEvent event) {
    final thread = event.chatThread;
    return 'Thread 事件-$action: type=${event.type.name}, from=${event.from}, threadId=${thread?.threadId}';
  }

  Future<EMChatThread> _createChatThread({
    required String name,
    required String messageId,
    required String parentId,
  }) {
    final callback = widget.controller?.createChatThread;
    if (callback != null) {
      return callback(name: name, messageId: messageId, parentId: parentId);
    }
    return _manager.createChatThread(
      name: name,
      messageId: messageId,
      parentId: parentId,
    );
  }

  Future<EMChatThread?> _fetchChatThread({required String chatThreadId}) {
    final callback = widget.controller?.fetchChatThread;
    if (callback != null) {
      return callback(chatThreadId: chatThreadId);
    }
    return _manager.fetchChatThread(chatThreadId: chatThreadId);
  }

  Future<EMCursorResult<String>> _fetchChatThreadMembers({
    required String chatThreadId,
  }) {
    final callback = widget.controller?.fetchChatThreadMembers;
    if (callback != null) {
      return callback(chatThreadId: chatThreadId, limit: 20);
    }
    return _manager.fetchChatThreadMembers(
      chatThreadId: chatThreadId,
      limit: 20,
    );
  }

  Future<EMCursorResult<EMChatThread>> _fetchChatThreadsWithParentId({
    required String parentId,
  }) {
    final callback = widget.controller?.fetchChatThreadsWithParentId;
    if (callback != null) {
      return callback(parentId: parentId, limit: 20);
    }
    return _manager.fetchChatThreadsWithParentId(parentId: parentId, limit: 20);
  }

  Future<EMCursorResult<EMChatThread>> _fetchJoinedChatThreads() {
    final callback = widget.controller?.fetchJoinedChatThreads;
    if (callback != null) {
      return callback(limit: 20);
    }
    return _manager.fetchJoinedChatThreads(limit: 20);
  }

  Future<EMCursorResult<EMChatThread>> _fetchJoinedChatThreadsWithParentId({
    required String parentId,
  }) {
    final callback = widget.controller?.fetchJoinedChatThreadsWithParentId;
    if (callback != null) {
      return callback(parentId: parentId, limit: 20);
    }
    return _manager.fetchJoinedChatThreadsWithParentId(
      parentId: parentId,
      limit: 20,
    );
  }

  Future<Map<String, EMMessage>> _fetchLatestMessageWithChatThreads({
    required List<String> chatThreadIds,
  }) {
    final callback = widget.controller?.fetchLatestMessageWithChatThreads;
    if (callback != null) {
      return callback(chatThreadIds: chatThreadIds);
    }
    return _manager.fetchLatestMessageWithChatThreads(
      chatThreadIds: chatThreadIds,
    );
  }

  Future<EMChatThread> _joinChatThread({required String chatThreadId}) {
    final callback = widget.controller?.joinChatThread;
    if (callback != null) {
      return callback(chatThreadId: chatThreadId);
    }
    return _manager.joinChatThread(chatThreadId: chatThreadId);
  }

  Future<void> _leaveChatThread({required String chatThreadId}) {
    final callback = widget.controller?.leaveChatThread;
    if (callback != null) {
      return callback(chatThreadId: chatThreadId);
    }
    return _manager.leaveChatThread(chatThreadId: chatThreadId);
  }

  Future<void> _destroyChatThread({required String chatThreadId}) {
    final callback = widget.controller?.destroyChatThread;
    if (callback != null) {
      return callback(chatThreadId: chatThreadId);
    }
    return _manager.destroyChatThread(chatThreadId: chatThreadId);
  }

  Future<void> _removeMemberFromChatThread({
    required String memberId,
    required String chatThreadId,
  }) {
    final callback = widget.controller?.removeMemberFromChatThread;
    if (callback != null) {
      return callback(memberId: memberId, chatThreadId: chatThreadId);
    }
    return _manager.removeMemberFromChatThread(
      memberId: memberId,
      chatThreadId: chatThreadId,
    );
  }

  Future<void> _updateChatThreadName({
    required String chatThreadId,
    required String newName,
  }) {
    final callback = widget.controller?.updateChatThreadName;
    if (callback != null) {
      return callback(chatThreadId: chatThreadId, newName: newName);
    }
    return _manager.updateChatThreadName(
      chatThreadId: chatThreadId,
      newName: newName,
    );
  }

  Future<EMMessage> _sendThreadMessage(EMMessage message) {
    final sender = widget.controller?.sendMessage;
    if (sender != null) {
      return sender(message);
    }
    return EMClient.getInstance.chatManager.sendMessage(message);
  }

  Future<EMCursorResult<EMMessage>> _fetchThreadHistoryMessages({
    required String threadId,
    String? cursor,
    int pageSize = 20,
  }) {
    final fetcher = widget.controller?.fetchThreadHistoryMessages;
    if (fetcher != null) {
      return fetcher(threadId: threadId, cursor: cursor, pageSize: pageSize);
    }
    return EMClient.getInstance.chatManager.fetchHistoryMessagesByOption(
      threadId,
      EMConversationType.GroupChat,
      cursor: cursor,
      pageSize: pageSize,
    );
  }

  Future<EMConversation?> _getThreadConversation({required String threadId}) {
    final getter = widget.controller?.getThreadConversation;
    if (getter != null) {
      return getter(threadId: threadId);
    }
    return EMClient.getInstance.chatManager.getThreadConversation(threadId);
  }

  Future<List<EMMessage>> _loadThreadLocalMessages({
    required EMConversation conversation,
    String startMsgId = '',
    int loadCount = 20,
  }) {
    final loader = widget.controller?.loadThreadLocalMessages;
    if (loader != null) {
      return loader(
        conversation: conversation,
        startMsgId: startMsgId,
        loadCount: loadCount,
      );
    }
    return conversation.loadMessages(
      startMsgId: startMsgId,
      loadCount: loadCount,
    );
  }

  Future<void> _recallThreadMessage({required String messageId}) {
    final recaller = widget.controller?.recallMessage;
    if (recaller != null) {
      return recaller(messageId: messageId);
    }
    return EMClient.getInstance.chatManager.recallMessage(messageId);
  }

  Future<void> _handleCreate() async {
    if (_parentId.isEmpty) {
      addSendLog('创建 Thread 失败: 父级群组 ID 不能为空');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建子区'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('父级群组 ID: $_parentId'),
            const SizedBox(height: 12),
            if (_hasFixedParentMessageId)
              Text('父消息 ID: $_messageId')
            else
              TextField(
                controller: _messageIdController,
                decoration: const InputDecoration(labelText: '父消息 ID'),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _threadNameController,
              decoration: const InputDecoration(labelText: 'Thread 名称'),
            ),
          ],
        ),
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
    if (confirmed != true) return;
    if (_threadName.isEmpty || _messageId.isEmpty) {
      addSendLog('创建 Thread 失败: 名称、父消息 ID 不能为空');
      return;
    }
    try {
      final thread = await _createChatThread(
        name: _threadName,
        messageId: _messageId,
        parentId: _parentId,
      );
      _setThreadIdFromServer(thread.threadId, source: '创建');
      addSendLog('创建 Thread 成功: ${_threadSummary(thread)}');
    } catch (e) {
      addAppErrLog('创建 Thread 失败: $e');
    }
  }

  Future<void> _handleFetchDetail() async {
    if (!_requireThreadId()) return;
    try {
      final thread = await _fetchChatThread(chatThreadId: _threadId);
      if (thread != null) {
        _setThreadIdFromServer(thread.threadId, source: '详情');
      }
      addReceiveLog(
        thread == null
            ? 'Thread 详情为空: $_threadId'
            : 'Thread 详情: ${_threadSummary(thread)}',
      );
    } catch (e) {
      addAppErrLog('获取 Thread 详情失败: $e');
    }
  }

  Future<void> _handleFetchMembers() async {
    if (!_requireThreadId()) return;
    try {
      final result = await _fetchChatThreadMembers(chatThreadId: _threadId);
      if (result.data.isEmpty) {
        addReceiveLog('Thread 成员为空: $_threadId');
        return;
      }
      for (final member in result.data) {
        addReceiveLog('Thread 成员: $member');
      }
    } catch (e) {
      addAppErrLog('获取 Thread 成员失败: $e');
    }
  }

  Future<void> _handleFetchParentThreads() async {
    if (!_requireParentId()) return;
    try {
      final result = await _fetchChatThreadsWithParentId(parentId: _parentId);
      _logThreadList('父级 Thread', result.data);
      _prefillThreadIdListFromThreads(result.data, source: '父级 Thread');
      _prefillThreadIdFromThreads(result.data, source: '父级 Thread');
    } catch (e) {
      addAppErrLog('获取父级 Thread 列表失败: $e');
    }
  }

  Future<void> _handleFetchJoinedThreads() async {
    try {
      final result = await _fetchJoinedChatThreads();
      _logThreadList('已加入 Thread', result.data);
      _prefillThreadIdListFromThreads(result.data, source: '已加入 Thread');
      _prefillThreadIdFromThreads(result.data, source: '已加入 Thread');
    } catch (e) {
      addAppErrLog('获取已加入 Thread 失败: $e');
    }
  }

  Future<void> _handleFetchJoinedParentThreads() async {
    if (!_requireParentId()) return;
    try {
      final result = await _fetchJoinedChatThreadsWithParentId(
        parentId: _parentId,
      );
      _logThreadList('父级已加入 Thread', result.data);
      _prefillThreadIdListFromThreads(result.data, source: '父级已加入 Thread');
      _prefillThreadIdFromThreads(result.data, source: '父级已加入 Thread');
    } catch (e) {
      addAppErrLog('获取父级已加入 Thread 失败: $e');
    }
  }

  Future<void> _handleFetchLatestMessages() async {
    final ids =
        parseChatThreadIdList(_threadIdsController.text) ??
        (_threadId.isEmpty ? null : <String>[_threadId]);
    if (ids == null) {
      addSendLog('获取 Thread 最新消息失败: Thread ID 列表不能为空');
      return;
    }
    try {
      final result = await _fetchLatestMessageWithChatThreads(
        chatThreadIds: ids,
      );
      if (result.isEmpty) {
        addReceiveLog('Thread 最新消息为空');
        return;
      }
      for (final entry in result.entries) {
        addReceiveLog(
          'Thread 最新消息: ${entry.key}, msgId=${entry.value.msgId}, body=${entry.value.body.toJson()}',
          attachment: entry.value,
          tag: 'message',
        );
      }
    } catch (e) {
      addAppErrLog('获取 Thread 最新消息失败: $e');
    }
  }

  Future<void> _handleJoin() async {
    if (!_requireThreadId()) return;
    try {
      final thread = await _joinChatThread(chatThreadId: _threadId);
      _setThreadIdFromServer(thread.threadId, source: '加入');
      addSendLog('加入 Thread 成功: ${_threadSummary(thread)}');
    } catch (e) {
      addAppErrLog('加入 Thread 失败: $e');
    }
  }

  Future<void> _handleLeave() async {
    if (!_requireThreadId()) return;
    try {
      await _leaveChatThread(chatThreadId: _threadId);
      addSendLog('退出 Thread 成功: $_threadId');
    } catch (e) {
      addAppErrLog('退出 Thread 失败: $e');
    }
  }

  Future<void> _handleDestroy() async {
    if (!_requireThreadId()) return;
    try {
      await _destroyChatThread(chatThreadId: _threadId);
      addSendLog('解散 Thread 成功: $_threadId');
    } catch (e) {
      addAppErrLog('解散 Thread 失败: $e');
    }
  }

  Future<void> _handleRemoveMember() async {
    if (!_requireThreadId()) return;
    if (_memberId.isEmpty) {
      addSendLog('移除 Thread 成员失败: 成员 ID 不能为空');
      return;
    }
    try {
      await _removeMemberFromChatThread(
        chatThreadId: _threadId,
        memberId: _memberId,
      );
      addSendLog('移除 Thread 成员成功: threadId=$_threadId, memberId=$_memberId');
    } catch (e) {
      addAppErrLog('移除 Thread 成员失败: $e');
    }
  }

  Future<void> _handleRename() async {
    if (!_requireThreadId()) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改子区名称'),
        content: TextField(
          controller: _threadNameController,
          decoration: const InputDecoration(labelText: 'Thread 新名称'),
        ),
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
    if (confirmed != true) return;
    final newName = _threadName;
    if (newName.isEmpty) {
      addSendLog('修改 Thread 名称失败: 新名称不能为空');
      return;
    }
    try {
      await _updateChatThreadName(chatThreadId: _threadId, newName: newName);
      addSendLog('修改 Thread 名称成功: threadId=$_threadId, name=$newName');
    } catch (e) {
      addAppErrLog('修改 Thread 名称失败: $e');
    }
  }

  Future<void> _handleSendThreadMessage() async {
    if (!_requireThreadId()) return;
    if (_messageContent.isEmpty) {
      addSendLog('发送 Thread 消息失败: 消息内容不能为空');
      return;
    }
    try {
      final message = EMMessage.createTxtSendMessage(
        targetId: _threadId,
        content: _messageContent,
        chatType: ChatType.GroupChat,
      );
      message.isChatThreadMessage = true;
      final sent = await _sendThreadMessage(message);
      _messageIdController.text = sent.msgId;
      addSendLog(
        '发送 Thread 消息成功: threadId=$_threadId, msgId=${sent.msgId}, isThread=${sent.isChatThreadMessage}, content=$_messageContent',
        attachment: sent,
        tag: 'message',
      );
    } catch (e) {
      addAppErrLog('发送 Thread 消息失败: $e');
    }
  }

  Future<void> _handleFetchThreadServerMessages() async {
    if (!_requireThreadId()) return;
    try {
      final result = await _fetchThreadHistoryMessages(threadId: _threadId);
      _logThreadMessages('Thread 服务端消息', result.data);
      addReceiveLog('Thread 服务端消息 cursor: ${result.cursor ?? ''}');
    } catch (e) {
      addAppErrLog('获取 Thread 服务端消息失败: $e');
    }
  }

  Future<void> _handleLoadThreadLocalMessages() async {
    if (!_requireThreadId()) return;
    try {
      final conversation = await _getThreadConversation(threadId: _threadId);
      if (conversation == null) {
        addReceiveLog('Thread 本地会话为空: $_threadId');
        return;
      }
      addReceiveLog(
        'Thread 本地会话: id=${conversation.id}, type=${conversation.type.name}, isThread=${conversation.isChatThread}',
      );
      final messages = await _loadThreadLocalMessages(
        conversation: conversation,
      );
      _logThreadMessages('Thread 本地消息', messages);
    } catch (e) {
      addAppErrLog('加载 Thread 本地消息失败: $e');
    }
  }

  Future<void> _handleRecallThreadMessage() async {
    if (!_requireThreadId()) return;
    if (_messageId.isEmpty) {
      addSendLog('撤回 Thread 消息失败: 消息 ID 不能为空');
      return;
    }
    try {
      await _recallThreadMessage(messageId: _messageId);
      addSendLog('撤回 Thread 消息成功: threadId=$_threadId, msgId=$_messageId');
    } catch (e) {
      addAppErrLog('撤回 Thread 消息失败: $e');
    }
  }

  bool _requireThreadId() {
    if (_threadId.isNotEmpty) return true;
    addSendLog('操作失败: Thread ID 不能为空');
    return false;
  }

  bool _requireParentId() {
    if (_parentId.isNotEmpty) return true;
    addSendLog('操作失败: 父级群组 ID 不能为空');
    return false;
  }

  void _logThreadList(String label, List<EMChatThread> threads) {
    if (threads.isEmpty) {
      addReceiveLog('$label 为空');
      return;
    }
    for (final thread in threads) {
      addReceiveLog('$label: ${_threadSummary(thread)}');
    }
  }

  Future<void> _prefillThreadIdFromParent() async {
    if (_parentId.isEmpty || _threadId.isNotEmpty) return;
    try {
      final result = await _fetchChatThreadsWithParentId(parentId: _parentId);
      _prefillThreadIdListFromThreads(result.data, source: '父级 Thread');
      _prefillThreadIdFromThreads(result.data, source: '父级 Thread');
      if (_threadId.isEmpty) {
        addReceiveLog('自动带入 Thread ID 跳过: 父级 Thread 为空');
      }
    } catch (e) {
      addAppErrLog('自动带入 Thread ID 失败: $e');
    }
  }

  void _prefillThreadIdFromThreads(
    List<EMChatThread> threads, {
    required String source,
  }) {
    if (_threadId.isNotEmpty || threads.isEmpty) return;
    EMChatThread? selected;
    if (_messageId.isNotEmpty) {
      for (final thread in threads) {
        if (thread.messageId == _messageId) {
          selected = thread;
          break;
        }
      }
    }
    selected ??= threads.first;
    _setThreadIdFromServer(selected.threadId, source: source);
  }

  void _prefillThreadIdListFromThreads(
    List<EMChatThread> threads, {
    required String source,
  }) {
    if (_threadIdsController.text.trim().isNotEmpty || threads.isEmpty) return;
    final ids = <String>[];
    final seen = <String>{};
    for (final thread in threads) {
      final threadId = thread.threadId;
      if (threadId.isEmpty || seen.contains(threadId)) continue;
      ids.add(threadId);
      seen.add(threadId);
    }
    if (ids.isEmpty) return;
    _threadIdsController.text = ids.join('\n');
    addReceiveLog('自动带入 Thread ID 列表: ${ids.join(',')} ($source)');
  }

  void _setThreadIdFromServer(String threadId, {required String source}) {
    if (threadId.isEmpty) return;
    final shouldLog = _threadId != threadId;
    void updateThreadId() {
      _threadIdController.text = threadId;
      _appendThreadIdToList(threadId);
    }

    if (mounted) {
      setState(updateThreadId);
    } else {
      updateThreadId();
    }
    if (shouldLog) {
      addReceiveLog('自动带入 Thread ID: $threadId ($source)');
    }
  }

  void _appendThreadIdToList(String threadId) {
    final ids = parseChatThreadIdList(_threadIdsController.text) ?? <String>[];
    if (ids.contains(threadId)) return;
    ids.add(threadId);
    _threadIdsController.text = ids.join('\n');
  }

  void _logThreadMessages(String label, List<EMMessage> messages) {
    if (messages.isEmpty) {
      addReceiveLog('$label 为空');
      return;
    }
    for (final message in messages) {
      addReceiveLog(
        '$label: threadId=${message.conversationId ?? message.to}, msgId=${message.msgId}, isThread=${message.isChatThreadMessage}, body=${message.body.toJson()}',
        attachment: message,
        tag: 'message',
      );
    }
  }

  String _threadSummary(EMChatThread thread) {
    return 'threadId=${thread.threadId}, name=${thread.threadName}, parentId=${thread.parentId}, msgId=${thread.messageId}, owner=${thread.owner}, members=${thread.membersCount}, messages=${thread.messageCount}';
  }

  PreferredSizeWidget? _buildAppBar(bool isDark) {
    if (!widget.showAppBar) return null;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textPrimary(isDark)),
      title: Text(
        'Thread / 子区测试',
        style: TextStyle(color: AppColors.textPrimary(isDark)),
      ),
      centerTitle: true,
    );
  }

  Widget _buildLogPanel(bool isDark) {
    return LogView(
      controller: _logController,
      isDark: isDark,
      actionsBuilder: (_) => [LogViewActions.copyEntry()],
    );
  }

  Widget _buildControlPanel(bool isDark) {
    final items = [
      GridActionItem(
        icon: Icons.notifications_active_outlined,
        label: '注册事件',
        onTap: _addEventHandler,
      ),
      GridActionItem(
        icon: Icons.search_outlined,
        label: '取事件',
        onTap: _getEventHandler,
      ),
      GridActionItem(
        icon: Icons.notifications_off_outlined,
        label: '移除事件',
        onTap: _removeEventHandler,
      ),
      GridActionItem(
        icon: Icons.clear_all_outlined,
        label: '清空事件',
        onTap: _clearEventHandlers,
      ),
      GridActionItem(
        icon: Icons.add_circle_outline,
        label: '创建',
        onTap: _handleCreate,
      ),
      GridActionItem(
        icon: Icons.assignment_outlined,
        label: '详情',
        onTap: _handleFetchDetail,
      ),
      GridActionItem(
        icon: Icons.people_outline,
        label: '成员',
        onTap: _handleFetchMembers,
      ),
      GridActionItem(
        icon: Icons.account_tree_outlined,
        label: '父级列表',
        onTap: _handleFetchParentThreads,
      ),
      GridActionItem(
        icon: Icons.how_to_reg_outlined,
        label: '已加入',
        onTap: _handleFetchJoinedThreads,
      ),
      GridActionItem(
        icon: Icons.subdirectory_arrow_right_outlined,
        label: '父级已加入',
        onTap: _handleFetchJoinedParentThreads,
      ),
      GridActionItem(
        icon: Icons.message_outlined,
        label: '最新消息',
        onTap: _handleFetchLatestMessages,
      ),
      GridActionItem(
        icon: Icons.login_outlined,
        label: '加入',
        onTap: _handleJoin,
      ),
      GridActionItem(
        icon: Icons.logout_outlined,
        label: '退出',
        onTap: _handleLeave,
      ),
      GridActionItem(
        icon: Icons.delete_forever_outlined,
        label: '解散',
        onTap: _handleDestroy,
      ),
      GridActionItem(
        icon: Icons.person_remove_outlined,
        label: '移除成员',
        onTap: _handleRemoveMember,
      ),
      GridActionItem(
        icon: Icons.drive_file_rename_outline,
        label: '改名',
        onTap: _handleRename,
      ),
      GridActionItem(
        icon: Icons.send_outlined,
        label: '发消息',
        onTap: _handleSendThreadMessage,
      ),
      GridActionItem(
        icon: Icons.cloud_download_outlined,
        label: '拉服务端消息',
        onTap: _handleFetchThreadServerMessages,
      ),
      GridActionItem(
        icon: Icons.forum_outlined,
        label: '本地会话',
        onTap: _handleLoadThreadLocalMessages,
      ),
      GridActionItem(
        icon: Icons.undo_outlined,
        label: '撤回消息',
        onTap: _handleRecallThreadMessage,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonSectionTitle(title: 'Thread / 子区上下文', isDark: isDark),
        Text(
          '子区是群组成员的子集，支持多人沟通；使用前需要联系商务开通。可从群消息长按“创建子区”自动带入父消息 ID，也可在此页点击“创建”后手动填写父消息 ID 和名称。',
          style: TextStyle(
            color: AppColors.textSecondary(isDark),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        if (_hasFixedParentId)
          Text(
            '当前父级群组 ID: $_parentId',
            style: TextStyle(
              color: AppColors.textPrimary(isDark),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          CommonInputRow(
            controller: _parentIdController,
            hintText: '父级群组 ID',
            isDark: isDark,
          ),
        if (_hasFixedParentMessageId) ...[
          const SizedBox(height: 8),
          Text(
            '当前父消息 ID: $_messageId',
            style: TextStyle(
              color: AppColors.textPrimary(isDark),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (_threadId.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '当前 Thread ID: $_threadId',
            style: TextStyle(
              color: AppColors.textPrimary(isDark),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 16),
        CommonSectionTitle(title: 'Thread / 子区参数', isDark: isDark),
        CommonInputRow(
          controller: _threadIdController,
          hintText: 'Thread ID',
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        CommonInputRow(
          controller: _memberIdController,
          hintText: '成员 ID',
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        CommonInputRow(
          controller: _threadIdsController,
          hintText: 'Thread ID 列表',
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        CommonInputRow(
          controller: _messageIdController,
          hintText: '父消息 ID / 子区消息 ID',
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        CommonInputRow(
          controller: _messageContentController,
          hintText: '子区消息内容',
          isDark: isDark,
        ),
        const SizedBox(height: 20),
        CommonSectionTitle(title: 'Thread / 子区 API', isDark: isDark),
        GridActionMenu(items: items, isDark: isDark, columns: 4),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _settings.isDarkMode;
    return CommonLayout(
      isDark: isDark,
      appBar: _buildAppBar(isDark),
      showAppBar: widget.showAppBar,
      controlPanel: _buildControlPanel(isDark),
      logPanel: _buildLogPanel(isDark),
    );
  }
}
