import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:qa_flutter/common/widgets/switch_alert.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_settings.dart';
import '../../common/widgets/async_button.dart';
import '../../common/widgets/input_dialog.dart';
import 'test_chat_room_members_page.dart';
import 'test_chat_room_admins_page.dart';
import 'test_chat_room_white_list_page.dart';
import 'test_chat_room_mute_list_page.dart';
import 'test_chat_room_change_owner_page.dart';
import '../../common/widgets/log_view.dart';
import '../../common/widgets/grid_action_menu.dart';
import '../../common/log_content_page.dart';

/// 聊天室信息编辑类型
enum RoomInfoEditType { name, description, announcement }

class TestChatRoomPage extends StatefulWidget {
  const TestChatRoomPage({super.key, this.roomId, this.showAppBar = true});
  final String? roomId;
  final bool showAppBar;
  @override
  State<TestChatRoomPage> createState() => _TestChatRoomPageState();
}

class _TestChatRoomPageState extends State<TestChatRoomPage> {
  final _eventKey = 'room_test';
  final _settings = AppSettings();
  final _roomIdController = TextEditingController();
  final _messageController = TextEditingController();
  final _logController = LogController();
  final _repeatCountController = TextEditingController(text: '1');
  String _roomId = '';
  bool _isJoined = false;

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
      _addLog('正在检查聊天室状态: $_roomId...');
      final room = await EMClient.getInstance.chatRoomManager
          .fetchChatRoomInfoFromServer(_roomId);
      _addLog('已获取聊天室详情: ${room.name} (Owner: ${room.owner})');
      _isJoined = true;
    } catch (e) {
      _addLog('获取聊天室信息失败，请尝试重新 Join: $e');
      _isJoined = false;
    } finally {
      setState(() {});
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
            _addSendLog('${msg.from}: ${msg.toJson().toString()}'),
        onError: (msgId, msg, error) =>
            _addSendLog('发送失败: ${error.toString()}'),
      ),
    );

    EMClient.getInstance.chatManager.addEventHandler(
      _eventKey,
      EMChatEventHandler(
        onMessagesReceived: (messages) {
          for (var msg in messages) {
            if (msg.conversationId == _roomId) {
              _addReceiveLog('${msg.from}: ${msg.toJson().toString()}');
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
            setState(() => _roomId = '');
            _addReceiveLog('onChatRoomDestroyed: $roomName');
          }
        },
        onRemovedFromChatRoom: (roomId, roomName, participant, reason) {
          if (roomId == _roomId) {
            setState(() => _roomId = '');
            _addReceiveLog('onRemoved: reason: $reason');
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
    if (roomId == _roomId) _addReceiveLog(log);
  }

  void _addLog(String content) => _logController.addLog(content);
  void _addAppErrLog(String content) =>
      _logController.addLog(content, color: Colors.red);
  void _addSendLog(String content) =>
      _logController.addLog(content, color: Colors.green);
  void _addReceiveLog(String content) =>
      _logController.addLog(content, color: Colors.blue);

  Future<String> _getAssetFilePath(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final fileName = assetPath.split('/').last;
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file.path;
  }

  // --- UI 区块 ---

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textPrimary(isDark)),
      title: Text(
        _roomId.isNotEmpty ? '$_roomId(聊天室)' : '聊天室测试',
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
        _buildInputRow(
          controller: _roomIdController,
          hintText: '输入聊天室 ID',
          buttonText: _isJoined ? 'Leave' : 'Join',
          onPressed: _handleJoinLeaveRoom,
          isDark: isDark,
        ),
        const SizedBox(height: 20),
        _buildInputRow(
          controller: _messageController,
          hintText: '输入消息内容',
          buttonText: 'Send',
          onPressed: () => _sendTextMessage(_messageController.text),
          isDark: isDark,
          countController: _repeatCountController,
        ),
        const SizedBox(height: 10),
        _buildSectionTitle('消息', isDark),
        const SizedBox(height: 10),
        _buildMessageTypeButtons(isDark),
        const SizedBox(height: 10),
        _buildSectionTitle('控制', isDark),
        const SizedBox(height: 10),
        _buildChatRoomManagementButtons(isDark),
        const SizedBox(height: 10),
        _buildSectionTitle('工具', isDark),
        const SizedBox(height: 10),
        _buildItemsButtons(isDark),
      ],
    );
  }

  Widget _buildLogPanel(bool isDark) {
    return LogView(controller: _logController, isDark: isDark);
  }

  // --- 业务逻辑 ---

  Future<void> _handleJoinLeaveRoom() async {
    final inputId = _roomIdController.text.trim();
    if (inputId.isEmpty) return;

    if (_roomId.isNotEmpty && _roomId == inputId) {
      _addLog('开始离开 $_roomId');
      try {
        await EMClient.getInstance.chatRoomManager.leaveChatRoom(_roomId);
        _addLog('退出 $_roomId 成功');
        _isJoined = false;
        setState(() => _roomId = '');
      } catch (e) {
        _addLog('退出失败: $e');
      }
    } else {
      _addLog('开始加入 $inputId');
      try {
        await EMClient.getInstance.chatRoomManager.joinChatRoom(inputId);
        _isJoined = true;
        setState(() => _roomId = inputId);
        _addLog('加入成功: $inputId');
      } catch (e) {
        _addLog('加入失败: $e');
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
      _addAppErrLog('发送失败: $e');
    }
  }

  Future<void> sendMessage(EMMessage msg) async {
    if (_roomId.isEmpty) {
      _addSendLog('请先加入聊天室');
      return;
    }
    try {
      msg.attributes = {
        'extKey1': 'extValue1',
        'date': DateTime.now().toString(),
      };
      _addSendLog('开始发送消息');
      await EMClient.getInstance.chatManager.sendMessage(msg);
    } catch (e) {
      rethrow;
    }
  }

  // --- 弹窗/抽屉逻辑 ---

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
        _addSendLog('修改成功');
      }
    } catch (e) {
      _addSendLog('报错: $e');
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
      _addLog('失败: $e');
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

  @override
  Widget build(BuildContext context) {
    final isDark = _settings.isDarkMode;
    final padding = EdgeInsets.only(
      top: widget.showAppBar ? (kToolbarHeight + 60) : 20,
      left: 15,
      right: 15,
      bottom: 30,
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: widget.showAppBar ? _buildAppBar(isDark) : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundStart(isDark),
              AppColors.backgroundEnd(isDark),
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      padding: padding,
                      child: _buildControlPanel(isDark, true),
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.glassBorder(isDark).withValues(alpha: 0.2),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: padding,
                      child: _buildLogPanel(isDark),
                    ),
                  ),
                ],
              );
            }
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: padding,
                  child: Column(
                    children: [
                      _buildControlPanel(isDark, false),
                      const SizedBox(height: 20),
                      SizedBox(height: 400, child: _buildLogPanel(isDark)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- 辅助组件 ---

  Widget _buildInputRow({
    required TextEditingController controller,
    required String hintText,
    required String buttonText,
    required Future<void> Function() onPressed,
    required bool isDark,
    TextEditingController? countController,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: TextStyle(color: AppColors.textPrimary(isDark)),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: AppColors.textSecondary(isDark)),
              filled: true,
              fillColor: AppColors.inputBackground(isDark),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.glassBorder(isDark)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.glassBorder(isDark)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary(isDark)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
            ),
          ),
        ),
        if (countController != null) ...[
          const SizedBox(width: 8),
          Text('X', style: TextStyle(color: AppColors.textPrimary(isDark))),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: TextField(
              controller: countController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textPrimary(isDark)),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '次数',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary(isDark),
                  fontSize: 12,
                ),
                filled: true,
                fillColor: AppColors.inputBackground(isDark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.glassBorder(isDark)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
        const SizedBox(width: 12),
        AsyncButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary(isDark),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(buttonText),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary(isDark),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

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
            _addAppErrLog('失败: $e');
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
          filePath: await _getAssetFilePath('assets/image.jpg'),
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
          filePath: await _getAssetFilePath('assets/video.mp4'),
          thumbnailLocalPath: await _getAssetFilePath('assets/image.jpg'),
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
          filePath: await _getAssetFilePath('assets/voice.mp3'),
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
          filePath: await _getAssetFilePath('assets/voice.mp3'),
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
        onTap: () => _showBottomSheet(TestChatRoomMembersPage(roomId: _roomId)),
      ),
      GridActionItem(
        icon: Icons.admin_panel_settings_outlined,
        label: '管理员',
        onTap: () => _showBottomSheet(TestChatRoomAdminsPage(roomId: _roomId)),
      ),
      GridActionItem(
        icon: Icons.verified_user_outlined,
        label: '白名单',
        onTap: () =>
            _showBottomSheet(TestChatRoomWhiteListPage(roomId: _roomId)),
      ),
      GridActionItem(
        icon: Icons.mic_off_outlined,
        label: '禁言列表',
        onTap: () =>
            _showBottomSheet(TestChatRoomMuteListPage(roomId: _roomId)),
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
            _addLog('成功');
          } catch (e) {
            _addLog('失败: $e');
          }
        },
      ),
      GridActionItem(
        icon: Icons.swap_horiz_outlined,
        label: '转移',
        onTap: () =>
            _showBottomSheet(TestChatRoomChangeOwnerPage(roomId: _roomId)),
      ),
      GridActionItem(
        icon: Icons.add_circle_outline,
        label: '创建',
        onTap: _createChatRoom,
      ),
      GridActionItem(icon: Icons.dangerous_outlined, label: '解散', onTap: a),
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
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => LogContentPage(
                  logPath: logZipPath.replaceFirst('log.gz', 'easemob.log'),
                ),
              ),
            );
          }
        },
      ),
      GridActionItem(
        icon: Icons.info_outline,
        label: '信息',
        onTap: () async {
          final u = await EMClient.getInstance.getCurrentUserId();
          final d = await EMClient.getInstance.getCurrentDeviceId();
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('个人信息'),
              content: Text('用户: $u\n设备: $d'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('确定'),
                ),
              ],
            ),
          );
        },
      ),
    ];
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: GridActionMenu(items: items, isDark: isDark, columns: 6),
    );
  }
}
