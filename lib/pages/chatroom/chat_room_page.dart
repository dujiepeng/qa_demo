import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import '../../common/widgets/switch_alert.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_settings.dart';
import '../../common/widgets/input_dialog.dart';
import 'chat_room_members_page.dart';
import 'chat_room_admins_page.dart';
import 'chat_room_white_list_page.dart';
import 'chat_room_mute_list_page.dart';
import 'chat_room_change_owner_page.dart';
import '../../common/widgets/log_view.dart';
import '../../common/widgets/grid_action_menu.dart';
import '../../common/log_content_page.dart';
import '../../common/widgets/common_input_row.dart';
import '../../common/widgets/common_section_title.dart';
import '../../common/widgets/common_layout.dart';
import '../../common/mixins/base_mixin.dart';

/// 聊天室信息编辑类型
enum RoomInfoEditType { name, description, announcement }

class ChatRoomPage extends StatefulWidget {
  const ChatRoomPage({super.key, this.roomId, this.showAppBar = true});
  final String? roomId;
  final bool showAppBar;
  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> with BaseMixin {
  final _eventKey = 'room_test';
  final _settings = AppSettings();
  final _roomIdController = TextEditingController();
  final _messageController = TextEditingController();
  final _logController = LogController();
  final _repeatCountController = TextEditingController(text: '1');
  String _roomId = '';
  bool _isJoined = false;

  @override
  LogController get logController => _logController;

  @override
  void initState() {
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
      addLog('正在检查聊天室状态: $_roomId...');
      final room = await EMClient.getInstance.chatRoomManager
          .fetchChatRoomInfoFromServer(_roomId);
      addLog('已获取聊天室详情: ${room.name} (Owner: ${room.owner})');
      _isJoined = true;
    } catch (e) {
      addLog('获取聊天室信息失败，请尝试重新 Join: $e');
      _isJoined = false;
    } finally {
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _roomIdController.dispose();
    _messageController.dispose();
    _repeatCountController.dispose();
    super.dispose();
  }

  void _addListener() {
    EMClient.getInstance.chatManager.addMessageEvent(
      _eventKey,
      ChatMessageEvent(
        onSuccess: (msgId, msg) =>
            addSendLog('${msg.from}: ${msg.toJson().toString()}', message: msg),
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
                message: msg,
              );
            }
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
            });
            addReceiveLog('onRemoved: reason: $reason');
          }
        },
        onSpecificationChanged: (room) => _handleRoomEvent(
          room.roomId,
          'onSpecificationChanged: name: ${room.name}',
        ),
      ),
    );
  }

  void _handleRoomEvent(String roomId, String log) {
    if (roomId == _roomId) addReceiveLog(log);
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
          icon: const Icon(Icons.info),
          onPressed: () => Navigator.of(context).pushNamed('/settings'),
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
    return LogView(controller: _logController, isDark: isDark);
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
        });
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
    try {
      msg.attributes = {
        'extKey1': 'extValue1',
        'date': DateTime.now().toString(),
      };
      addSendLog('开始发送消息');
      await EMClient.getInstance.chatManager.sendMessage(msg);
    } catch (e) {
      rethrow;
    }
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
        addLog('开始创建聊天室: $name');
        final room = await EMClient.getInstance.chatRoomManager.createChatRoom(
          name,
          desc: desc,
        );
        addLog('创建成功 ID: ${room.roomId}');
        setState(() {
          _roomId = room.roomId;
          _roomIdController.text = _roomId;
          _isJoined = true;
        });
      } catch (e) {
        addLog('创建失败: $e');
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
        });
      } catch (e) {
        addLog('解散失败: $e');
      }
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
        onTap: () => _showBottomSheet(ChatRoomMembersPage(roomId: _roomId)),
      ),
      GridActionItem(
        icon: Icons.admin_panel_settings_outlined,
        label: '管理员',
        onTap: () => _showBottomSheet(ChatRoomAdminsPage(roomId: _roomId)),
      ),
      GridActionItem(
        icon: Icons.verified_user_outlined,
        label: '白名单',
        onTap: () => _showBottomSheet(ChatRoomWhiteListPage(roomId: _roomId)),
      ),
      GridActionItem(
        icon: Icons.mic_off_outlined,
        label: '禁言列表',
        onTap: () => _showBottomSheet(ChatRoomMuteListPage(roomId: _roomId)),
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
        icon: Icons.swap_horiz_outlined,
        label: '转移',
        onTap: () => _showBottomSheet(ChatRoomChangeOwnerPage(roomId: _roomId)),
      ),
      GridActionItem(
        icon: Icons.add_circle_outline,
        label: '创建',
        onTap: _createChatRoom,
      ),
      GridActionItem(
        icon: Icons.dangerous_outlined,
        label: '解散',
        onTap: _destroyChatRoom,
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
        onTap: () async {
          final logZipPath = await EMClient.getInstance.compressLogs();
          final logPath = logZipPath.replaceFirst('log.gz', 'easemob.log');
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => LogContentPage(logPath: logPath),
              ),
            );
          }
        },
      ),
    ];
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: GridActionMenu(items: items, isDark: isDark, columns: 6),
    );
  }
}
