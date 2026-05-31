import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import '../../common/widgets/switch_alert.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_settings.dart';
import '../../common/widgets/input_dialog.dart';
import 'room_members_page.dart';
import 'room_admins_page.dart';
import 'room_white_list_page.dart';
import 'room_block_list_page.dart';
import 'room_mute_list_page.dart';
import 'room_change_owner_page.dart';
import '../../common/widgets/log_view.dart';
import '../../common/widgets/log_view_actions.dart';
import '../../common/widgets/grid_action_menu.dart';
import '../../common/widgets/common_input_row.dart';
import '../../common/widgets/common_section_title.dart';
import '../../common/widgets/common_layout.dart';
import '../../common/mixins/base_mixin.dart';
import '../../common/widgets/log_page_launcher.dart';
import '../../common/widgets/info_dialog.dart';

/// 聊天室信息编辑类型
enum RoomInfoEditType { name, description, announcement }

const chatRoomMessageEditContent = 'Chatroom edited message';
const chatRoomMessageEditCustomEvent = 'chatroom_message_edited';
const chatRoomMessageEditExtKey = 'qa_chatroom_edit';
const chatRoomMessageEditExtValue = 'chatroom_edit_ext_updated';

typedef ChatRoomMembersLoader =
    Future<EMCursorResult<String>> Function(
      String roomId, {
      String cursor,
      int pageSize,
    });
typedef ChatRoomMessageModifier =
    Future<EMMessage> Function({
      required String messageId,
      EMMessageBody? msgBody,
      Map<String, dynamic>? attributes,
    });
typedef ChatRoomRemoteMessageRemover =
    Future<void> Function({
      required String conversationId,
      required EMConversationType type,
      required List<String> msgIds,
    });
typedef ChatRoomRemoteMessageBeforeTimeRemover =
    Future<void> Function({
      required String conversationId,
      required EMConversationType type,
      required int timestamp,
    });
typedef ChatRoomCreator =
    Future<EMChatRoom> Function({
      required String name,
      String? desc,
      String? welcomeMsg,
      required int maxUserCount,
      List<String>? members,
    });

bool canUseChatRoomOwnerOnlyActions(EMChatRoom? room) {
  return room?.permissionType == EMChatRoomPermissionType.Owner;
}

List<String>? parseChatRoomReceiverList(String rawValue) {
  final members = rawValue
      .split(RegExp(r'[\s,，]+'))
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty);
  final uniqueMembers = <String>[];
  final seenMembers = <String>{};
  for (final member in members) {
    if (seenMembers.add(member)) {
      uniqueMembers.add(member);
    }
  }
  return uniqueMembers.isEmpty ? null : uniqueMembers;
}

bool isChatRoomRecallForRoom(RecallMessageInfo info, String roomId) {
  return info.conversationId == roomId ||
      info.recallMessage?.conversationId == roomId;
}

String buildChatRoomRecallLog(RecallMessageInfo info) {
  final parts = <String>[
    'msgId=${info.recallMessageId}',
    'recallBy=${info.recallBy}',
  ];
  if (info.ext?.isNotEmpty == true) {
    parts.add('ext=${info.ext}');
  }
  if (info.recallMessage != null) {
    parts.add('hasMessage=true');
  }
  return '收到聊天室消息撤回: ${parts.join(', ')}';
}

class RoomPage extends StatefulWidget {
  const RoomPage({
    super.key,
    this.roomId,
    this.showAppBar = true,
    this.userInfoLoader,
    this.roomInfoLoader,
    this.chatRoomMembersLoader,
    this.messageModifier,
    this.remoteMessageRemover,
    this.remoteMessageBeforeTimeRemover,
    this.chatRoomCreator,
    this.settingsOverride,
  });
  final String? roomId;
  final bool showAppBar;
  final RoomInfoDialogUserInfoLoader? userInfoLoader;
  final RoomInfoDialogChatRoomLoader? roomInfoLoader;
  final ChatRoomMembersLoader? chatRoomMembersLoader;
  final ChatRoomMessageModifier? messageModifier;
  final ChatRoomRemoteMessageRemover? remoteMessageRemover;
  final ChatRoomRemoteMessageBeforeTimeRemover? remoteMessageBeforeTimeRemover;
  final ChatRoomCreator? chatRoomCreator;
  final AppSettings? settingsOverride;
  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> with BaseMixin {
  final _eventKey = 'room_test';
  late final AppSettings _settings;
  final _roomIdController = TextEditingController();
  final _messageController = TextEditingController();
  final _receiverListController = TextEditingController();
  final _logController = LogController();
  final _repeatCountController = TextEditingController(text: '1');
  String _roomId = '';
  bool _isJoined = false;
  EMChatRoom? _currentRoomInfo;

  @override
  LogController get logController => _logController;

  @override
  void initState() {
    _settings = widget.settingsOverride ?? AppSettings();
    _roomId = widget.roomId ?? '';
    _roomIdController.text = _roomId;
    super.initState();
    _addListener();
    _roomIdController.addListener(() => setState(() {}));
    _checkChatRoomStatus();
  }

  void _checkChatRoomStatus() async {
    if (_roomId.isEmpty) return;
    try {
      final room = await _fetchChatRoomInfo(_roomId);
      _isJoined = room.permissionType != EMChatRoomPermissionType.None;
      _currentRoomInfo = room;
    } catch (e) {
      _isJoined = false;
      _currentRoomInfo = null;
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<EMChatRoom> _fetchChatRoomInfo(String roomId) {
    final loader = widget.roomInfoLoader;
    if (loader != null) {
      return loader(roomId);
    }
    return EMClient.getInstance.chatRoomManager.fetchChatRoomInfoFromServer(
      roomId,
    );
  }

  Future<EMChatRoom> _createChatRoomOnServer({
    required String name,
    String? desc,
    String? welcomeMsg,
    int maxUserCount = 300,
    List<String>? members,
  }) {
    final creator = widget.chatRoomCreator;
    if (creator != null) {
      return creator(
        name: name,
        desc: desc,
        welcomeMsg: welcomeMsg,
        maxUserCount: maxUserCount,
        members: members,
      );
    }
    return EMClient.getInstance.chatRoomManager.createChatRoom(
      name,
      desc: desc,
      welcomeMsg: welcomeMsg,
      maxUserCount: maxUserCount,
      members: members,
    );
  }

  @override
  void dispose() {
    _roomIdController.dispose();
    _messageController.dispose();
    _receiverListController.dispose();
    _repeatCountController.dispose();
    super.dispose();
  }

  void _addListener() {
    EMClient.getInstance.chatManager.addMessageEvent(
      _eventKey,
      ChatMessageEvent(
        onSuccess: (msgId, msg) => addSendLog(
          '${msg.from}: ${msg.toJson().toString()}',
          attachment: msg,
          tag: 'message',
        ),
        onError: (msgId, msg, error) => addSendLog('发送失败: ${error.toString()}'),
      ),
    );

    EMClient.getInstance.chatManager.addEventHandler(
      _eventKey,
      EMChatEventHandler(
        onMessagesReceived: (messages) {
          for (var msg in messages) {
            if (msg.conversationId == _roomId) {
              addReceiveLog(
                '${msg.from}: ${msg.toJson().toString()}',
                attachment: msg,
                tag: 'message',
              );
            }
          }
        },
        onMessagesRecalledInfo: (infos) {
          for (final info in infos) {
            if (isChatRoomRecallForRoom(info, _roomId)) {
              _handleChatRoomRecall(info);
            }
          }
        },
        onMessageContentChanged: (msg, operator, operationTime) {
          if (msg.conversationId == _roomId) {
            addReceiveLog(
              '聊天室消息编辑回调: operator=$operator, operationTime=$operationTime, ${msg.from}: ${msg.toJson().toString()}',
              attachment: msg,
              tag: 'message',
            );
          }
        },
      ),
    );

    EMClient.getInstance.chatRoomManager.addEventHandler(
      _eventKey,
      EMChatRoomEventHandler(
        onAdminAddedFromChatRoom: (roomId, admin) =>
            _handleRoomEvent(roomId, 'onAdminAdded: $admin'),
        onAdminRemovedFromChatRoom: (roomId, admin) =>
            _handleRoomEvent(roomId, 'onAdminRemoved: $admin'),
        onAllChatRoomMemberMuteStateChanged: (roomId, isAllMuted) =>
            _handleRoomEvent(roomId, 'onAllMutedChanged: $isAllMuted'),
        onAllowListAddedFromChatRoom: (roomId, members) =>
            _handleRoomEvent(roomId, 'onAllowListAdded: $members'),
        onAllowListRemovedFromChatRoom: (roomId, members) =>
            _handleRoomEvent(roomId, 'onAllowListRemoved: $members'),
        onAnnouncementChangedFromChatRoom: (roomId, announcement) =>
            _handleRoomEvent(roomId, 'onAnnouncementChanged: $announcement'),
        onAttributesRemoved: (roomId, removedKeys, from) => _handleRoomEvent(
          roomId,
          'onAttributesRemoved: keys: $removedKeys, from: $from',
        ),
        onAttributesUpdated: (roomId, attributes, from) => _handleRoomEvent(
          roomId,
          'onAttributesUpdated: attrs: $attributes, from: $from',
        ),
        onChatRoomDestroyed: (roomId, roomName) {
          if (roomId == _roomId) {
            setState(() {
              _roomId = '';
              _isJoined = false;
            });
            addReceiveLog('onChatRoomDestroyed: $roomName');
          }
        },
        onRemovedFromChatRoom: (roomId, roomName, participant, reason) {
          if (roomId == _roomId) {
            setState(() {
              _roomId = '';
              _isJoined = false;
              _currentRoomInfo = null;
            });
            addReceiveLog('onRemoved: reason: $reason');
          }
        },
        onSpecificationChanged: (room) => _handleRoomEvent(
          room.roomId,
          'onSpecificationChanged: name: ${room.name}',
          refreshRoomInfo: true,
        ),
        onMemberJoinedFromChatRoom: (roomId, participant, ext) => _handleRoomEvent(
          roomId,
          'onMemberJoinedFromChatRoom: roomId: $roomId, participant: $participant, ext: $ext',
        ),
        onMemberExitedFromChatRoom: (roomId, roomName, participant) =>
            _handleRoomEvent(
              roomId,
              'onMemberExitedFromChatRoom: roomName: $roomName, participant: $participant',
            ),
        onMuteListAddedFromChatRoom: (roomId, mutes) => _handleRoomEvent(
          roomId,
          'onMuteListAddedFromChatRoom: name: ${mutes.toString()}',
        ),
        onMuteListRemovedFromChatRoom: (roomId, mutes) => _handleRoomEvent(
          roomId,
          'onMuteListRemovedFromChatRoom: name: ${mutes.toString()}',
        ),
        onOwnerChangedFromChatRoom: (roomId, newOwner, oldOwner) =>
            _handleRoomEvent(
              roomId,
              'onOwnerChangedFromChatRoom: newOwner: $newOwner, oldOwner: $oldOwner',
              refreshRoomInfo: true,
            ),
      ),
    );
  }

  void _handleRoomEvent(
    String roomId,
    String log, {
    bool refreshRoomInfo = false,
  }) {
    if (roomId == _roomId) {
      addReceiveLog(log);
      if (refreshRoomInfo) {
        _checkChatRoomStatus();
      }
    }
  }

  void _handleChatRoomRecall(RecallMessageInfo info) {
    final recalledEntries = logController.entities
        .where((element) => element.attachment is EMMessage)
        .where((element) {
          final message = element.attachment as EMMessage;
          return message.msgId == info.recallMessageId;
        })
        .toList();
    logController.changeEntities(
      recalledEntries,
      style: LogStyle.lineThrough,
      overlayLabel: '消息已撤回',
      overlayStyle: LogOverlayStyle.warning,
    );
    addReceiveLog(buildChatRoomRecallLog(info));
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textPrimary(isDark)),
      title: Text(
        _roomId.isNotEmpty ? '$_roomId(室)' : '聊天室测试',
        style: TextStyle(color: AppColors.textPrimary(isDark)),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: '信息',
          onPressed: () => InfoDialog.show(
            context,
            _settings,
            roomId: _roomId,
            userInfoLoader: widget.userInfoLoader,
            roomInfoLoader: widget.roomInfoLoader,
          ),
        ),
      ],
    );
  }

  Widget _buildControlPanel(bool isDark, bool isWide) {
    return Column(
      children: [
        CommonInputRow(
          controller: _roomIdController,
          hintText: '输入聊天室 ID',
          buttonText: _isJoined ? 'Leave' : 'Join',
          onPressed: _handleJoinLeaveRoom,
          isDark: isDark,
        ),
        const SizedBox(height: 20),
        CommonInputRow(
          controller: _messageController,
          hintText: '输入消息内容',
          buttonText: 'Send',
          onPressed: () => _sendTextMessage(_messageController.text),
          isDark: isDark,
          countController: _repeatCountController,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: CommonInputRow(
                controller: _receiverListController,
                hintText: '定向接收人，最多20个，空则发全体',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _roomId.isEmpty ? null : _showReceiverPicker,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.inputBackground(isDark),
                foregroundColor: AppColors.textPrimary(isDark),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.glassBorder(isDark)),
                ),
                elevation: 0,
              ),
              child: const Text('选择'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        CommonSectionTitle(title: '消息', isDark: isDark),
        const SizedBox(height: 10),
        _buildMessageTypeButtons(isDark),
        const SizedBox(height: 10),
        CommonSectionTitle(title: '控制', isDark: isDark),
        const SizedBox(height: 10),
        _buildChatRoomManagementButtons(isDark),
        const SizedBox(height: 10),
        CommonSectionTitle(title: '工具', isDark: isDark),
        const SizedBox(height: 10),
        _buildItemsButtons(isDark),
      ],
    );
  }

  Widget _buildLogPanel(bool isDark) {
    return LogView(
      controller: _logController,
      isDark: isDark,
      asyncActionsBuilder: _buildLogActions,
    );
  }

  Future<List<LogAction>> _buildLogActions(LogEntry entry) async {
    final actions = <LogAction>[LogViewActions.copyEntry()];
    final attachment = entry.attachment;
    if (entry.tag == 'message' && attachment is EMMessage) {
      actions.add(
        LogAction(
          id: 'modify',
          title: '修改',
          icon: Icons.edit_outlined,
          foregroundColor: Colors.purple,
          isVisible: (_) =>
              attachment.chatType == ChatType.ChatRoom &&
              _canEditChatRoomMessage(attachment),
          onSelected: (_) async {
            try {
              final body = _chatRoomEditedBody(attachment);
              final msg = await _modifyChatRoomMessage(
                messageId: attachment.msgId,
                msgBody: body,
                attributes: _chatRoomEditedAttributes(attachment),
              );
              addSendLog(
                '${msg.from}: ${msg.toJson().toString()}',
                attachment: msg,
                tag: 'message',
                color: Colors.purple,
              );
              return const LogActionResult(
                overlayLabel: '已编辑',
                overlayStyle: LogOverlayStyle.info,
              );
            } catch (e) {
              return LogActionResult(
                overlayLabel: '编辑失败: $e',
                overlayStyle: LogOverlayStyle.error,
              );
            }
          },
        ),
      );
      actions.add(
        LogAction(
          id: 'delete_server_history',
          title: '删服务端',
          icon: Icons.delete_sweep_outlined,
          foregroundColor: Colors.deepOrange,
          isDestructive: true,
          isVisible: (_) => attachment.chatType == ChatType.ChatRoom,
          onSelected: (_) async {
            try {
              await _removeChatRoomMessageFromServer(attachment);
              return LogActionResult(
                overlayLabel: '已删服务端',
                overlayStyle: LogOverlayStyle.warning,
                color: Colors.deepOrange.withValues(alpha: 0.14),
                style: LogStyle.lineThrough,
              );
            } catch (e) {
              return LogActionResult(
                overlayLabel: '删服务端失败: $e',
                overlayStyle: LogOverlayStyle.error,
              );
            }
          },
        ),
      );
      actions.add(
        LogAction(
          id: 'delete_server_history_before_time',
          title: '按时间删',
          icon: Icons.history_toggle_off_outlined,
          foregroundColor: Colors.deepOrange,
          isDestructive: true,
          isVisible: (_) => attachment.chatType == ChatType.ChatRoom,
          onSelected: (_) async {
            try {
              await _removeChatRoomMessagesFromServerBeforeTime(attachment);
              return LogActionResult(
                overlayLabel: '已按时间删服务端',
                overlayStyle: LogOverlayStyle.warning,
                color: Colors.deepOrange.withValues(alpha: 0.14),
                style: LogStyle.lineThrough,
              );
            } catch (e) {
              return LogActionResult(
                overlayLabel: '按时间删失败: $e',
                overlayStyle: LogOverlayStyle.error,
              );
            }
          },
        ),
      );
      actions.add(
        LogAction(
          id: 'recall',
          title: '撤回',
          icon: Icons.undo_outlined,
          isDestructive: true,
          isVisible: (_) =>
              attachment.direction == MessageDirection.SEND &&
              attachment.chatType == ChatType.ChatRoom,
          onSelected: (_) async {
            try {
              await EMClient.getInstance.chatManager.recallMessage(
                attachment.msgId,
                ext: 'qa_demo_chatroom_recall',
              );
              return LogActionResult(
                overlayLabel: '已撤回',
                overlayStyle: LogOverlayStyle.warning,
                color: Colors.red.withValues(alpha: 0.14),
                style: LogStyle.lineThrough,
              );
            } catch (e) {
              return LogActionResult(
                overlayLabel: '撤回失败: $e',
                overlayStyle: LogOverlayStyle.error,
              );
            }
          },
        ),
      );
    }
    return actions;
  }

  bool _canEditChatRoomMessage(EMMessage message) {
    if (message.chatType != ChatType.ChatRoom) {
      return false;
    }
    return message.body is! EMCmdMessageBody;
  }

  EMMessageBody? _chatRoomEditedBody(EMMessage message) {
    final body = message.body;
    if (body is EMTextMessageBody) {
      return EMTextMessageBody(content: chatRoomMessageEditContent);
    }
    if (body is EMCustomMessageBody) {
      return EMCustomMessageBody(
        event: chatRoomMessageEditCustomEvent,
        params: {...?body.params, 'content': chatRoomMessageEditContent},
      );
    }
    return null;
  }

  Map<String, dynamic> _chatRoomEditedAttributes(EMMessage message) {
    return {
      ...?message.attributes,
      chatRoomMessageEditExtKey: chatRoomMessageEditExtValue,
    };
  }

  Future<EMMessage> _modifyChatRoomMessage({
    required String messageId,
    EMMessageBody? msgBody,
    Map<String, dynamic>? attributes,
  }) {
    final modifier = widget.messageModifier;
    if (modifier != null) {
      return modifier(
        messageId: messageId,
        msgBody: msgBody,
        attributes: attributes,
      );
    }
    return EMClient.getInstance.chatManager.modifyMessage(
      messageId: messageId,
      msgBody: msgBody,
      attributes: attributes,
    );
  }

  Future<void> _removeChatRoomMessageFromServer(EMMessage message) {
    final conversationId = message.conversationId ?? _roomId;
    final remover = widget.remoteMessageRemover;
    if (remover != null) {
      return remover(
        conversationId: conversationId,
        type: EMConversationType.ChatRoom,
        msgIds: [message.msgId],
      );
    }
    return EMClient.getInstance.chatManager.deleteRemoteMessagesWithIds(
      conversationId: conversationId,
      type: EMConversationType.ChatRoom,
      msgIds: [message.msgId],
    );
  }

  Future<void> _removeChatRoomMessagesFromServerBeforeTime(EMMessage message) {
    final conversationId = message.conversationId ?? _roomId;
    final remover = widget.remoteMessageBeforeTimeRemover;
    if (remover != null) {
      return remover(
        conversationId: conversationId,
        type: EMConversationType.ChatRoom,
        timestamp: message.serverTime,
      );
    }
    return EMClient.getInstance.chatManager.deleteRemoteMessagesBefore(
      conversationId: conversationId,
      type: EMConversationType.ChatRoom,
      timestamp: message.serverTime,
    );
  }

  Future<void> _handleJoinLeaveRoom() async {
    final inputId = _roomIdController.text.trim();
    if (inputId.isEmpty) return;

    if (_isJoined && _roomId == inputId) {
      addLog('开始离开 $_roomId');
      try {
        await EMClient.getInstance.chatRoomManager.leaveChatRoom(_roomId);
        addLog('退出 $_roomId 成功');
        setState(() {
          _roomId = '';
          _isJoined = false;
          _currentRoomInfo = null;
        });
      } catch (e) {
        addLog('退出失败: $e');
      }
    } else {
      addLog('开始加入 $inputId');
      try {
        await EMClient.getInstance.chatRoomManager.joinChatRoom(inputId);
        setState(() {
          _roomId = inputId;
          _isJoined = true;
          _currentRoomInfo = null;
        });
        _checkChatRoomStatus();
        addLog('加入成功: $inputId');
      } catch (e) {
        _isJoined = false;
        addLog('加入失败: $e');
      }
    }
  }

  Future<void> _sendTextMessage(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty || _roomId.isEmpty) return;
    int count = int.tryParse(_repeatCountController.text) ?? 1;
    try {
      for (int i = 0; i < count; i++) {
        final msg = EMMessage.createTxtSendMessage(
          targetId: _roomId,
          content: count > 1 ? '$trimmedText ($i)' : trimmedText,
          chatType: ChatType.ChatRoom,
        );
        await sendMessage(msg);
      }
      _messageController.clear();
    } catch (e) {
      addAppErrLog('发送失败: $e');
    }
  }

  Future<void> sendMessage(EMMessage msg) async {
    if (_roomId.isEmpty) {
      addSendLog('请先加入聊天室');
      return;
    }
    final receiverList = parseChatRoomReceiverList(
      _receiverListController.text,
    );
    if (receiverList != null && receiverList.length > 20) {
      addSendLog('定向消息接收人不能超过20个');
      return;
    }
    try {
      msg.receiverList = receiverList;
      msg.attributes = {
        'extKey1': 'extValue1',
        'date': DateTime.now().toString(),
      };
      addSendLog(
        receiverList == null
            ? '开始发送消息'
            : '开始发送定向消息: ${receiverList.join(', ')}',
      );
      await EMClient.getInstance.chatManager.sendMessage(msg);
    } catch (e) {
      rethrow;
    }
  }

  Future<EMCursorResult<String>> _loadChatRoomMembersPage(
    String roomId, {
    String cursor = '',
    int pageSize = 50,
  }) {
    final loader = widget.chatRoomMembersLoader;
    if (loader != null) {
      return loader(roomId, cursor: cursor, pageSize: pageSize);
    }
    return EMClient.getInstance.chatRoomManager.fetchChatRoomMembers(
      roomId,
      cursor: cursor,
      pageSize: pageSize,
    );
  }

  Future<void> _showReceiverPicker() async {
    if (_roomId.isEmpty) return;
    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ChatRoomReceiverPicker(
        roomId: _roomId,
        initialSelectedMembers:
            parseChatRoomReceiverList(_receiverListController.text) ??
            const <String>[],
        membersLoader: _loadChatRoomMembersPage,
        isDark: _settings.isDarkMode,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _receiverListController.text = selected.join(', ');
    });
  }

  Future<void> _showRoomInfoDialog(RoomInfoEditType type) async {
    if (_roomId.isEmpty) return;
    try {
      final room = await EMClient.getInstance.chatRoomManager
          .fetchChatRoomInfoFromServer(_roomId);
      if (!mounted) return;
      String title = '', fieldTitle = '', placeholder = '', currentValue = '';
      bool multiline = false;

      switch (type) {
        case RoomInfoEditType.name:
          title = '编辑名称';
          fieldTitle = '名称';
          placeholder = '输入名称';
          currentValue = room.name ?? '';
          break;
        case RoomInfoEditType.description:
          title = '编辑描述';
          fieldTitle = '描述';
          placeholder = '输入描述';
          currentValue = room.description ?? '';
          multiline = true;
          break;
        case RoomInfoEditType.announcement:
          title = '编辑公告';
          fieldTitle = '公告';
          placeholder = '输入公告';
          currentValue = room.announcement ?? '';
          multiline = true;
          break;
      }

      final result = await showInputDialog(
        context: context,
        title: title,
        fields: [
          InputFieldData(
            title: fieldTitle,
            placeholder: placeholder,
            text: currentValue,
            multiline: multiline,
          ),
        ],
      );
      if (result != null) {
        final newValue = result[0].text;
        if (currentValue == newValue) return;
        switch (type) {
          case RoomInfoEditType.name:
            await EMClient.getInstance.chatRoomManager.changeChatRoomName(
              _roomId,
              newValue,
            );
            break;
          case RoomInfoEditType.description:
            await EMClient.getInstance.chatRoomManager
                .changeChatRoomDescription(_roomId, newValue);
            break;
          case RoomInfoEditType.announcement:
            await EMClient.getInstance.chatRoomManager
                .updateChatRoomAnnouncement(_roomId, newValue);
            break;
        }
        addSendLog('修改成功');
      }
    } catch (e) {
      addSendLog('报错: $e');
    }
  }

  Future<void> _showChatRoomDetails() async {
    if (_roomId.isEmpty) return;
    try {
      final room = await EMClient.getInstance.chatRoomManager
          .fetchChatRoomInfoFromServer(_roomId);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(room.name ?? '详情'),
          content: Text(
            'ID: ${room.roomId}\nOwner: ${room.owner}\nMembers: ${room.memberCount}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    } catch (e) {
      addLog('失败: $e');
    }
  }

  void _showBottomSheet(Widget page) {
    if (_roomId.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: _settings.isDarkMode
                ? const Color(0xFF1C1C1E)
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: page,
        ),
      ),
    );
  }

  void _showMuteAllMuteAlert() async {
    if (_roomId.isEmpty) return;
    final room = await EMClient.getInstance.chatRoomManager
        .fetchChatRoomInfoFromServer(_roomId);
    if (!mounted) return;
    showSwitchAlert(
      context: context,
      title: '全部禁言',
      description: '操作全部禁言？',
      initialValue: room.isAllMemberMuted ?? false,
      onChanged: (value) async {
        try {
          if (value) {
            await EMClient.getInstance.chatRoomManager.muteAllChatRoomMembers(
              _roomId,
            );
          } else {
            await EMClient.getInstance.chatRoomManager.unMuteAllChatRoomMembers(
              _roomId,
            );
          }
          return true;
        } catch (e) {
          return false;
        }
      },
    );
  }

  Future<void> _createChatRoom() async {
    final result = await showInputDialog(
      context: context,
      title: '创建聊天室',
      fields: [
        InputFieldData(title: '名称', placeholder: '输入聊天室名称', text: ''),
        InputFieldData(
          title: '描述',
          placeholder: '输入聊天室描述',
          text: '',
          multiline: true,
        ),
      ],
    );

    if (result != null) {
      final name = result[0].text.trim();
      final desc = result[1].text.trim();
      if (name.isEmpty) return;
      try {
        final startMessage = '开始创建聊天室: $name';
        addLog(startMessage);
        _showSnackBar(startMessage);
        final room = await _createChatRoomOnServer(name: name, desc: desc);
        final successMessage = '创建成功 ID: ${room.roomId}';
        addLog(successMessage);
        _showSnackBar(successMessage);
        EMChatRoom? serverRoom;
        try {
          serverRoom = await _fetchChatRoomInfo(room.roomId);
        } catch (e) {
          addLog('创建后拉取聊天室详情失败: $e');
        }
        if (!mounted) return;
        setState(() {
          _roomId = room.roomId;
          _roomIdController.text = _roomId;
          _isJoined =
              (serverRoom ?? room).permissionType !=
              EMChatRoomPermissionType.None;
          _currentRoomInfo = serverRoom ?? room;
        });
      } catch (e) {
        final errorMessage = '创建失败: $e';
        addLog(errorMessage);
        _showSnackBar(errorMessage);
      }
    }
  }

  Future<void> _destroyChatRoom() async {
    if (_roomId.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('解散聊天室'),
        content: Text('确定要解散聊天室 $_roomId 吗？'),
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
        addLog('开始解散聊天室: $_roomId');
        await EMClient.getInstance.chatRoomManager.destroyChatRoom(_roomId);
        addLog('解散成功');
        setState(() {
          _roomId = '';
          _roomIdController.text = '';
          _isJoined = false;
          _currentRoomInfo = null;
        });
      } catch (e) {
        addLog('解散失败: $e');
      }
    }
  }

  Future<void> _removeChatRoomAttribute() async {
    if (_roomId.isEmpty) return;
    try {
      final result = await EMClient.getInstance.chatRoomManager
          .removeAttributes(_roomId, keys: const ['attKey'], force: true);
      final failures = result ?? const <String, int>{};
      if (failures.isEmpty) {
        addLog('删除聊天室属性成功: attKey');
      } else {
        if (failures.containsKey('attKey')) {
          const missingMessage = '聊天室属性 attKey 不存在，无需删除';
          addLog(missingMessage);
          _showSnackBar(missingMessage);
        }
        addLog('删除聊天室属性失败详情: $failures');
      }
    } catch (e) {
      addLog('删除聊天室属性失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _settings.isDarkMode;
    return CommonLayout(
      isDark: isDark,
      showAppBar: widget.showAppBar,
      appBar: widget.showAppBar ? _buildAppBar(isDark) : null,
      controlPanel: LayoutBuilder(
        builder: (context, constraints) {
          return _buildControlPanel(isDark, constraints.maxWidth > 800);
        },
      ),
      logPanel: _buildLogPanel(isDark),
    );
  }

  // --- 辅助组件 ---

  Widget _buildMessageTypeButtons(bool isDark) {
    GridActionItem bi(
      IconData icon,
      String label,
      Future<EMMessage> Function() creator,
    ) {
      return GridActionItem(
        icon: icon,
        label: label,
        onTap: () async {
          try {
            await sendMessage(await creator());
          } catch (e) {
            addAppErrLog('失败: $e');
          }
        },
      );
    }

    final items = [
      bi(
        Icons.image_outlined,
        '图片',
        () async => EMMessage.createImageSendMessage(
          targetId: _roomId,
          filePath: await getAssetFilePath('assets/image.jpg'),
          width: 1920,
          height: 1080,
          fileSize: 111916,
          chatType: ChatType.ChatRoom,
        ),
      ),
      bi(
        Icons.videocam_outlined,
        '视频',
        () async => EMMessage.createVideoSendMessage(
          targetId: _roomId,
          filePath: await getAssetFilePath('assets/video.mp4'),
          thumbnailLocalPath: await getAssetFilePath('assets/image.jpg'),
          width: 1920,
          height: 1080,
          duration: 10,
          fileSize: 4006696,
          chatType: ChatType.ChatRoom,
        ),
      ),
      bi(
        Icons.mic_outlined,
        '语音',
        () async => EMMessage.createVoiceSendMessage(
          targetId: _roomId,
          filePath: await getAssetFilePath('assets/voice.mp3'),
          duration: 10,
          fileSize: 111916,
          chatType: ChatType.ChatRoom,
        ),
      ),
      bi(
        Icons.description_outlined,
        '文件',
        () async => EMMessage.createFileSendMessage(
          targetId: _roomId,
          filePath: await getAssetFilePath('assets/voice.mp3'),
          fileSize: 111916,
          chatType: ChatType.ChatRoom,
        ),
      ),
      bi(
        Icons.location_on_outlined,
        '位置',
        () async => EMMessage.createLocationSendMessage(
          targetId: _roomId,
          latitude: 39.9042,
          longitude: 116.4074,
          address: '北京市海淀区中关村',
          chatType: ChatType.ChatRoom,
        ),
      ),
      bi(
        Icons.extension_outlined,
        '自定义',
        () async => EMMessage.createCustomSendMessage(
          targetId: _roomId,
          event: 'ev',
          params: {'p': 'v'},
          chatType: ChatType.ChatRoom,
        ),
      ),
    ];
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: GridActionMenu(items: items, isDark: isDark, columns: 6),
    );
  }

  Widget _buildChatRoomManagementButtons(bool isDark) {
    final canUseOwnerOnlyActions = canUseChatRoomOwnerOnlyActions(
      _currentRoomInfo,
    );
    final items = [
      GridActionItem(
        icon: Icons.assignment_outlined,
        label: '详情',
        onTap: _showChatRoomDetails,
      ),
      GridActionItem(
        icon: Icons.drive_file_rename_outline,
        label: '名称',
        onTap: () => _showRoomInfoDialog(RoomInfoEditType.name),
      ),
      GridActionItem(
        icon: Icons.subject,
        label: '描述',
        onTap: () => _showRoomInfoDialog(RoomInfoEditType.description),
      ),
      GridActionItem(
        icon: Icons.campaign_outlined,
        label: '公告',
        onTap: () => _showRoomInfoDialog(RoomInfoEditType.announcement),
      ),
      GridActionItem(
        icon: Icons.group_outlined,
        label: '成员',
        onTap: () => _showBottomSheet(RoomMembersPage(roomId: _roomId)),
      ),
      GridActionItem(
        icon: Icons.admin_panel_settings_outlined,
        label: '管理员',
        onTap: () => _showBottomSheet(RoomAdminsPage(roomId: _roomId)),
      ),
      GridActionItem(
        icon: Icons.verified_user_outlined,
        label: '白名单',
        onTap: () => _showBottomSheet(RoomWhiteListPage(roomId: _roomId)),
      ),
      GridActionItem(
        icon: Icons.block_outlined,
        label: '黑名单',
        onTap: () => _showBottomSheet(RoomBlockListPage(roomId: _roomId)),
      ),
      GridActionItem(
        icon: Icons.mic_off_outlined,
        label: '禁言列表',
        onTap: () => _showBottomSheet(RoomMuteListPage(roomId: _roomId)),
      ),
      GridActionItem(
        icon: Icons.voice_over_off_outlined,
        label: '全部禁言',
        onTap: _showMuteAllMuteAlert,
      ),
      GridActionItem(
        icon: Icons.tune,
        label: '自定义',
        onTap: () async {
          if (_roomId.isEmpty) return;
          try {
            await EMClient.getInstance.chatRoomManager.addAttributes(
              _roomId,
              attributes: {'attKey': 'att_${DateTime.now()}'},
              overwrite: true,
            );
            addLog('成功');
          } catch (e) {
            addLog('失败: $e');
          }
        },
      ),
      GridActionItem(
        icon: Icons.playlist_remove_outlined,
        label: '删属性',
        onTap: _removeChatRoomAttribute,
      ),
      GridActionItem(
        icon: Icons.swap_horiz_outlined,
        label: '转移',
        onTap: canUseOwnerOnlyActions
            ? () => _showBottomSheet(RoomChangeOwnerPage(roomId: _roomId))
            : null,
      ),
      GridActionItem(
        icon: Icons.add_circle_outline,
        label: '创建',
        onTap: _createChatRoom,
      ),
      GridActionItem(
        icon: Icons.dangerous_outlined,
        label: '解散',
        onTap: canUseOwnerOnlyActions ? _destroyChatRoom : null,
      ),
    ];
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: GridActionMenu(items: items, isDark: isDark, columns: 6),
    );
  }

  Widget _buildItemsButtons(bool isDark) {
    final items = [
      GridActionItem(
        icon: Icons.article_outlined,
        label: '日志',
        onTap: () => openSdkLogPage(context),
      ),
    ];
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: GridActionMenu(items: items, isDark: isDark, columns: 6),
    );
  }
}

class _ChatRoomReceiverPicker extends StatefulWidget {
  const _ChatRoomReceiverPicker({
    required this.roomId,
    required this.initialSelectedMembers,
    required this.membersLoader,
    required this.isDark,
  });

  final String roomId;
  final List<String> initialSelectedMembers;
  final ChatRoomMembersLoader membersLoader;
  final bool isDark;

  @override
  State<_ChatRoomReceiverPicker> createState() =>
      _ChatRoomReceiverPickerState();
}

class _ChatRoomReceiverPickerState extends State<_ChatRoomReceiverPicker> {
  static const _pageSize = 50;
  final _members = <String>[];
  late final Set<String> _selectedMembers;
  String _cursor = '';
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedMembers = widget.initialSelectedMembers.toSet();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _cursor = '';
      _hasMore = true;
    });
    try {
      final result = await widget.membersLoader(
        widget.roomId,
        cursor: '',
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _members
          ..clear()
          ..addAll(result.data);
        _cursor = result.cursor ?? '';
        _hasMore = _cursor.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    try {
      final result = await widget.membersLoader(
        widget.roomId,
        cursor: _cursor,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _members.addAll(result.data);
        _cursor = result.cursor ?? '';
        _hasMore = _cursor.isNotEmpty;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _toggleMember(String memberId, bool selected) {
    setState(() {
      if (selected) {
        if (_selectedMembers.length >= 20) return;
        _selectedMembers.add(memberId);
      } else {
        _selectedMembers.remove(memberId);
      }
    });
  }

  void _selectLoadedMembers() {
    setState(() {
      for (final memberId in _members) {
        if (_selectedMembers.length >= 20) break;
        _selectedMembers.add(memberId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '选择定向接收人 (${_selectedMembers.length}/20)',
                      style: TextStyle(
                        color: AppColors.textPrimary(isDark),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: AppColors.primary(isDark)),
                    tooltip: '刷新',
                    onPressed: _isLoading ? null : _fetchMembers,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: AppColors.textSecondary(isDark),
                    ),
                    tooltip: '关闭',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildContent(scrollController, isDark)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedMembers.clear();
                      });
                    },
                    child: const Text('清空'),
                  ),
                  TextButton(
                    onPressed: _members.isEmpty ? null : _selectLoadedMembers,
                    child: const Text('全选'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(context, _selectedMembers.toList()),
                    child: const Text('确定'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ScrollController scrollController, bool isDark) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primary(isDark)),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Text(
          '加载失败: $_errorMessage',
          style: TextStyle(color: AppColors.textSecondary(isDark)),
        ),
      );
    }
    if (_members.isEmpty) {
      return Center(
        child: Text(
          '暂无成员',
          style: TextStyle(color: AppColors.textSecondary(isDark)),
        ),
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 120) {
          _loadMore();
        }
        return false;
      },
      child: ListView.builder(
        controller: scrollController,
        itemCount: _members.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _members.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary(isDark),
                ),
              ),
            );
          }
          final memberId = _members[index];
          final selected = _selectedMembers.contains(memberId);
          final disabled = !selected && _selectedMembers.length >= 20;
          return CheckboxListTile(
            value: selected,
            onChanged: disabled
                ? null
                : (value) => _toggleMember(memberId, value ?? false),
            title: Text(
              memberId,
              style: TextStyle(
                color: disabled
                    ? AppColors.textSecondary(isDark)
                    : AppColors.textPrimary(isDark),
              ),
            ),
            activeColor: AppColors.primary(isDark),
            controlAffinity: ListTileControlAffinity.leading,
          );
        },
      ),
    );
  }
}
