import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:qa_flutter/widgets/switch_alert.dart';

import '../theme/app_colors.dart';
import '../theme/app_settings.dart';
import '../widgets/input_dialog.dart';
import 'test_chat_room_members_page.dart';
import 'test_chat_room_admins_page.dart';
import 'test_chat_room_white_list_page.dart';
import 'test_chat_room_mute_list_page.dart';
import 'test_chat_room_change_owner_page.dart';
import '../widgets/log_view.dart';
import '../widgets/grid_action_menu.dart';
import '../pages/log_content_page.dart';

/// 聊天室信息编辑类型
enum RoomInfoEditType {
  /// 名称
  name,

  /// 描述
  description,

  /// 公告
  announcement,
}

class TestChatRoomPage extends StatefulWidget {
  const TestChatRoomPage({super.key, this.roomId});
  final String? roomId;
  @override
  State<TestChatRoomPage> createState() => _TestChatRoomPageState();
}

class _TestChatRoomPageState extends State<TestChatRoomPage> {
  final _eventKey = 'room_test';
  final _settings = AppSettings();
  final _roomIdController = TextEditingController();
  final _messageController = TextEditingController();
  final _logController = LogController();
  String _roomId = '';

  @override
  void initState() {
    _roomIdController.text = widget.roomId ?? '';
    super.initState();
    _addListener();
  }

  @override
  void dispose() {
    _roomIdController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _addListener() {
    EMClient.getInstance.chatManager.addMessageEvent(
      _eventKey,
      ChatMessageEvent(
        onSuccess: (msgId, msg) {
          _addSendLog('${msg.from}: ${msg.toJson().toString()}');
        },
        onError: (msgId, msg, error) {
          _addSendLog('发送失败: ${error.toString()}');
        },
      ),
    );

    EMClient.getInstance.chatManager.addEventHandler(
      _eventKey,
      EMChatEventHandler(
        onMessagesReceived: (messages) {
          for (var msg in messages) {
            if (msg.from != _roomId) return;
            _addReceiveLog('${msg.from}: ${msg.toJson().toString()}');
          }
        },
      ),
    );

    EMClient.getInstance.chatRoomManager.addEventHandler(
      _eventKey,
      EMChatRoomEventHandler(
        onAdminAddedFromChatRoom: (roomId, admin) {
          _addReceiveLog(
            'onAdminAddedFromChatRoom: roomId: $roomId, admin: $admin',
          );
        },
        onAdminRemovedFromChatRoom: (roomId, admin) {
          _addReceiveLog(
            'onAdminRemovedFromChatRoom: roomId: $roomId, admin: $admin',
          );
        },
        onAllChatRoomMemberMuteStateChanged: (roomId, isAllMuted) {
          _addReceiveLog(
            'onAllChatRoomMemberMuteStateChanged: roomId: $roomId, isAllMuted: $isAllMuted',
          );
        },
        onAllowListAddedFromChatRoom: (roomId, members) {
          _addReceiveLog(
            'onAllowListAddedFromChatRoom: roomId: $roomId, members: $members',
          );
        },
        onAllowListRemovedFromChatRoom: (roomId, members) {
          _addReceiveLog(
            'onAllowListRemovedFromChatRoom: roomId: $roomId, members: $members',
          );
        },
        onAnnouncementChangedFromChatRoom: (roomId, announcement) {
          _addReceiveLog(
            'onAnnouncementChangedFromChatRoom: roomId: $roomId, announcement: $announcement',
          );
        },
        onAttributesRemoved: (roomId, removedKeys, from) {
          _addReceiveLog(
            'onAttributesRemoved: roomId: $roomId, removedKeys: $removedKeys, from: $from',
          );
        },
        onAttributesUpdated: (roomId, attributes, from) {
          _addReceiveLog(
            'onAttributesUpdated: roomId: $roomId, attributes: $attributes, from: $from',
          );
        },
        onChatRoomDestroyed: (roomId, roomName) {
          _addReceiveLog(
            'onChatRoomDestroyed: roomId: $roomId, roomName: $roomName',
          );
        },
        onMemberExitedFromChatRoom: (roomId, roomName, participant) {
          _addReceiveLog(
            'onMemberExitedFromChatRoom: roomId: $roomId, roomName: $roomName, participant: $participant',
          );
        },
        onMemberJoinedFromChatRoom: (roomId, participant, ext) {
          _addReceiveLog(
            'onMemberJoinedFromChatRoom: roomId: $roomId, participant: $participant, ext: $ext',
          );
        },
        onMuteListAddedFromChatRoom: (roomId, mutes) {
          _addReceiveLog(
            'onMuteListAddedFromChatRoom: roomId: $roomId, mutes: $mutes',
          );
        },
        onMuteListRemovedFromChatRoom: (roomId, mutes) {
          _addReceiveLog(
            'onMuteListRemovedFromChatRoom: roomId: $roomId, mutes: $mutes',
          );
        },
        onOwnerChangedFromChatRoom: (roomId, newOwner, oldOwner) {
          _addReceiveLog(
            'onOwnerChangedFromChatRoom: roomId: $roomId, newOwner: $newOwner, oldOwner: $oldOwner',
          );
        },
        onRemovedFromChatRoom: (roomId, roomName, participant, reason) {
          _addReceiveLog(
            'onRemovedFromChatRoom: roomId: $roomId, roomName: $roomName, participant: $participant, reason: $reason',
          );
        },
        onSpecificationChanged: (room) {
          _addReceiveLog(
            'onSpecificationChanged: name: ${room.name}, description: ${room.description}',
          );
        },
      ),
    );
  }

  void _addLog(String content) {
    _logController.addLog(content);
  }

  void _addAppErrLog(String content) {
    _logController.addLog(content, color: Colors.red);
  }

  void _addSendLog(String content) {
    _logController.addLog(content, color: Colors.green);
  }

  void _addReceiveLog(String content) {
    _logController.addLog(content, color: Colors.blue);
  }

  Future<String> _getAssetFilePath(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final fileName = assetPath.split('/').last;
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file.path;
  }

  Future<void> _showRoomInfoDialog(RoomInfoEditType type) async {
    if (_roomId.isEmpty) {
      _addSendLog('请先加入聊天室');
      return;
    }

    try {
      // 获取聊天室信息
      final room = await EMClient.getInstance.chatRoomManager
          .fetchChatRoomInfoFromServer(_roomId);

      if (!mounted) return;

      // 根据类型确定标题和字段
      String title;
      String fieldTitle;
      String placeholder;
      String currentValue;
      bool multiline = false;

      switch (type) {
        case RoomInfoEditType.name:
          title = '编辑聊天室名称';
          fieldTitle = '聊天室名称';
          placeholder = '请输入聊天室名称';
          currentValue = room.name ?? '';
          break;
        case RoomInfoEditType.description:
          title = '编辑聊天室描述';
          fieldTitle = '聊天室描述';
          placeholder = '请输入聊天室描述';
          currentValue = room.description ?? '';
          multiline = true;
          break;
        case RoomInfoEditType.announcement:
          title = '编辑聊天室公告';
          fieldTitle = '聊天室公告';
          placeholder = '请输入聊天室公告';
          currentValue = room.announcement ?? '';
          multiline = true;
          break;
      }

      // 使用通用输入对话框
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

      // 用户点击了确定
      if (result != null) {
        final newValue = result[0].text;

        // 如果值没有变化，直接返回
        if (currentValue == newValue) {
          return;
        }

        // 调用对应的 API
        switch (type) {
          case RoomInfoEditType.name:
            await EMClient.getInstance.chatRoomManager.changeChatRoomName(
              _roomId,
              newValue,
            );
            _addSendLog('修改聊天室名称成功');
            break;
          case RoomInfoEditType.description:
            await EMClient.getInstance.chatRoomManager
                .changeChatRoomDescription(_roomId, newValue);
            _addSendLog('修改聊天室描述成功');
            break;
          case RoomInfoEditType.announcement:
            await EMClient.getInstance.chatRoomManager
                .updateChatRoomAnnouncement(_roomId, newValue);
            _addSendLog('修改聊天室公告成功');
            break;
        }
      }
    } catch (e) {
      _addSendLog('获取聊天室信息失败: ${e.toString()}');
    }
  }

  Future<void> _showChatRoomDetails() async {
    if (_roomId.isEmpty) {
      _addSendLog('请先加入聊天室');
      return;
    }
    try {
      final room = await EMClient.getInstance.chatRoomManager
          .fetchChatRoomInfoFromServer(_roomId);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(room.name ?? '聊天室详情'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID: ${room.roomId}'),
                    const SizedBox(height: 8),
                    Text('Name: ${room.name}'),
                    const SizedBox(height: 8),
                    Text('Description: ${room.description}'),
                    const SizedBox(height: 8),
                    Text('Owner: ${room.owner}'),
                    const SizedBox(height: 8),
                    Text('Max Users: ${room.maxUsers}'),
                    const SizedBox(height: 8),
                    Text('Member Count: ${room.memberCount}'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('关闭'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      _addSendLog('获取详情失败: $e');
    }
  }

  void _showMembersBottomSheet() {
    if (_roomId.isEmpty) {
      _addSendLog('请先加入聊天室');
      return;
    }

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
          child: TestChatRoomMembersPage(roomId: _roomId),
        ),
      ),
    );
  }

  void _showAdminsBottomSheet() {
    if (_roomId.isEmpty) {
      _addSendLog('请先加入聊天室');
      return;
    }

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
          child: TestChatRoomAdminsPage(roomId: _roomId),
        ),
      ),
    );
  }

  void _showWhiteListBottomSheet() {
    if (_roomId.isEmpty) {
      _addSendLog('请先加入聊天室');
      return;
    }

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
          child: TestChatRoomWhiteListPage(roomId: _roomId),
        ),
      ),
    );
  }

  void _showMuteListBottomSheet() {
    if (_roomId.isEmpty) {
      _addSendLog('请先加入聊天室');
      return;
    }

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
          child: TestChatRoomMuteListPage(roomId: _roomId),
        ),
      ),
    );
  }

  void _showMuteAllMuteAlert() async {
    if (_roomId.isEmpty) {
      _addSendLog('请先加入聊天室');
      return;
    }
    final room = await EMClient.getInstance.chatRoomManager
        .fetchChatRoomInfoFromServer(_roomId);
    if (mounted) {
      showSwitchAlert(
        context: context,
        title: '全部禁言',
        description: '确定要禁言所有成员吗？',
        initialValue: room.isAllMemberMuted ?? false,
        onChanged: (value) async {
          try {
            if (value) {
              await EMClient.getInstance.chatRoomManager.muteAllChatRoomMembers(
                _roomId,
              );
            } else {
              await EMClient.getInstance.chatRoomManager
                  .unMuteAllChatRoomMembers(_roomId);
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('设置成功'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString()),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
            return false;
          }
          return true;
        },
      );
    }
  }

  void _showChangeOwnerBottomSheet() {
    if (_roomId.isEmpty) {
      _addSendLog('请先加入聊天室');
      return;
    }

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
          child: TestChatRoomChangeOwnerPage(roomId: _roomId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _settings.isDarkMode;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary(isDark)),
        title: Text(
          _roomId.isNotEmpty ? _roomId : '聊天室测试',
          style: TextStyle(color: AppColors.textPrimary(isDark)),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
          ),
        ],
      ),
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
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: kToolbarHeight + 60,
                    left: 15,
                    right: 15,
                    bottom: 30, // 增加底部间距
                  ),
                  child: Column(
                    children: [
                      _buildInputRow(
                        controller: _roomIdController,
                        hintText: '输入聊天室 ID',
                        buttonText: _roomId.isNotEmpty ? 'Leave' : 'Join',
                        onPressed: () async {
                          String showMsg = '';
                          try {
                            if (_roomId.isNotEmpty) {
                              await EMClient.getInstance.chatRoomManager
                                  .leaveChatRoom(_roomId);
                              showMsg = '退出 $_roomId 成功';
                              _roomId = '';
                            } else {
                              await EMClient.getInstance.chatRoomManager
                                  .joinChatRoom(_roomIdController.text.trim());
                              _roomId = _roomIdController.text;
                              showMsg =
                                  "加入成功，roomId: ${_roomIdController.text.trim()} ";
                            }
                          } catch (e) {
                            showMsg = '操作失败';
                          } finally {
                            _addLog(showMsg);
                            setState(() {});
                          }
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),
                      _buildInputRow(
                        controller: _messageController,
                        hintText: '输入消息内容',
                        buttonText: 'Send',
                        onPressed: () async {
                          String text = _messageController.text.trim();
                          if (text.isEmpty) return;
                          try {
                            final msg = EMMessage.createTxtSendMessage(
                              targetId: _roomId,
                              content: text,
                              chatType: ChatType.ChatRoom,
                            );
                            await sendMessage(msg);
                            _messageController.clear();
                          } catch (e) {
                            _addAppErrLog('发送文字失败: ${e.toString()}');
                          }
                        },
                        isDark: isDark,
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
                      const SizedBox(height: 20),
                      // 日志显示区域
                      LogView(controller: _logController, isDark: isDark),
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

  Future<void> sendMessage(msg) async {
    try {
      msg.attributes = {
        'extKey1': 'extValue1',
        'date': DateTime.now().toString(),
      };
      await EMClient.getInstance.chatManager.sendMessage(msg);
    } catch (e) {
      rethrow;
    }
  }

  Widget _buildInputRow({
    required TextEditingController controller,
    required String hintText,
    required String buttonText,
    required VoidCallback onPressed,
    required bool isDark,
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
        const SizedBox(width: 12),
        ElevatedButton(
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
    final items = [
      GridActionItem(
        icon: Icons.image_outlined,
        label: '图片',
        onTap: () async {
          try {
            final filePath = await _getAssetFilePath('assets/image.jpg');
            final msg = EMMessage.createImageSendMessage(
              targetId: _roomId,
              filePath: filePath,
              width: 1920,
              height: 1080,
              fileSize: 111916,
              chatType: ChatType.ChatRoom,
            );
            await sendMessage(msg);
          } catch (e) {
            _addAppErrLog('发送图片失败: ${e.toString()}');
          }
        },
      ),
      GridActionItem(
        icon: Icons.videocam_outlined,
        label: '视频',
        onTap: () async {
          try {
            final filePath = await _getAssetFilePath('assets/video.mp4');
            final thumb = await _getAssetFilePath('assets/image.jpg');
            final msg = EMMessage.createVideoSendMessage(
              targetId: _roomId,
              filePath: filePath,
              thumbnailLocalPath: thumb,
              width: 1920,
              height: 1080,
              duration: 10,
              fileSize: 4006696,
              chatType: ChatType.ChatRoom,
            );
            await sendMessage(msg);
          } catch (e) {
            _addAppErrLog('发送视频失败: ${e.toString()}');
          }
        },
      ),
      GridActionItem(
        icon: Icons.mic_outlined,
        label: '语音',
        onTap: () async {
          try {
            final filePath = await _getAssetFilePath('assets/voice.mp3');
            final msg = EMMessage.createVoiceSendMessage(
              targetId: _roomId,
              filePath: filePath,
              duration: 10,
              fileSize: 111916,
              chatType: ChatType.ChatRoom,
            );
            await sendMessage(msg);
          } catch (e) {
            _addAppErrLog('发送语音失败: ${e.toString()}');
          }
        },
      ),
      GridActionItem(
        icon: Icons.description_outlined,
        label: '文件',
        onTap: () async {
          try {
            final filePath = await _getAssetFilePath('assets/voice.mp3');
            final msg = EMMessage.createFileSendMessage(
              targetId: _roomId,
              filePath: filePath,
              fileSize: 111916,
              chatType: ChatType.ChatRoom,
            );
            await sendMessage(msg);
          } catch (e) {
            _addAppErrLog('发送文件失败: ${e.toString()}');
          }
        },
      ),
      GridActionItem(
        icon: Icons.location_on_outlined,
        label: '位置',
        onTap: () async {
          try {
            final msg = EMMessage.createLocationSendMessage(
              targetId: _roomId,
              latitude: 39.9042,
              longitude: 116.4074,
              address: '北京市海淀区中关村',
              chatType: ChatType.ChatRoom,
            );
            await sendMessage(msg);
          } catch (e) {
            _addAppErrLog('发送位置失败: ${e.toString()}');
          }
        },
      ),
      GridActionItem(
        icon: Icons.extension_outlined,
        label: '自定义',
        onTap: () async {
          try {
            final msg = EMMessage.createCustomSendMessage(
              targetId: _roomId,
              event: 'eventValue',
              params: {'paramsKey': 'paramsValue'},
              chatType: ChatType.ChatRoom,
            );
            await sendMessage(msg);
          } catch (e) {
            _addAppErrLog('发送自定义失败: ${e.toString()}');
          }
        },
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
        onTap: _showMembersBottomSheet,
      ),
      GridActionItem(
        icon: Icons.admin_panel_settings_outlined,
        label: '管理员',
        onTap: _showAdminsBottomSheet,
      ),
      GridActionItem(
        icon: Icons.verified_user_outlined,
        label: '白名单',
        onTap: _showWhiteListBottomSheet,
      ),
      GridActionItem(
        icon: Icons.mic_off_outlined,
        label: '禁言列表',
        onTap: _showMuteListBottomSheet,
      ),
      GridActionItem(
        icon: Icons.voice_over_off_outlined,
        label: '全部禁言',
        onTap: _showMuteAllMuteAlert,
      ),
      GridActionItem(
        icon: Icons.swap_horiz_outlined,
        label: '转移',
        onTap: _showChangeOwnerBottomSheet,
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
