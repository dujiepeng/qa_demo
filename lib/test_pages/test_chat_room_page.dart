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
  const TestChatRoomPage({super.key});

  @override
  State<TestChatRoomPage> createState() => _TestChatRoomPageState();
}

class _TestChatRoomPageState extends State<TestChatRoomPage> {
  final _eventKey = 'room_test';
  final _settings = AppSettings();
  final _roomIdController = TextEditingController();
  final _messageController = TextEditingController();
  final List<String> _logs = [];
  String _roomId = '';

  @override
  void initState() {
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
          _addLog('${msg.from}: ${msg.toJson().toString()}');
        },
        onError: (msgId, msg, error) {
          _addLog('发送失败: ${error.toString()}');
        },
      ),
    );

    EMClient.getInstance.chatManager.addEventHandler(
      _eventKey,
      EMChatEventHandler(
        onMessagesReceived: (messages) {
          for (var msg in messages) {
            _addLog('${msg.from}: ${msg.toJson().toString()}');
          }
        },
      ),
    );

    EMClient.getInstance.chatRoomManager.addEventHandler(
      _eventKey,
      EMChatRoomEventHandler(
        onAdminAddedFromChatRoom: (roomId, admin) {
          _addLog('onAdminAddedFromChatRoom: roomId: $roomId, admin: $admin');
        },
        onAdminRemovedFromChatRoom: (roomId, admin) {
          _addLog('onAdminRemovedFromChatRoom: roomId: $roomId, admin: $admin');
        },
        onAllChatRoomMemberMuteStateChanged: (roomId, isAllMuted) {
          _addLog(
            'onAllChatRoomMemberMuteStateChanged: roomId: $roomId, isAllMuted: $isAllMuted',
          );
        },
        onAllowListAddedFromChatRoom: (roomId, members) {
          _addLog(
            'onAllowListAddedFromChatRoom: roomId: $roomId, members: $members',
          );
        },
        onAllowListRemovedFromChatRoom: (roomId, members) {
          _addLog(
            'onAllowListRemovedFromChatRoom: roomId: $roomId, members: $members',
          );
        },
        onAnnouncementChangedFromChatRoom: (roomId, announcement) {
          _addLog(
            'onAnnouncementChangedFromChatRoom: roomId: $roomId, announcement: $announcement',
          );
        },
        onAttributesRemoved: (roomId, removedKeys, from) {
          _addLog(
            'onAttributesRemoved: roomId: $roomId, removedKeys: $removedKeys, from: $from',
          );
        },
        onAttributesUpdated: (roomId, attributes, from) {
          _addLog(
            'onAttributesUpdated: roomId: $roomId, attributes: $attributes, from: $from',
          );
        },
        onChatRoomDestroyed: (roomId, roomName) {
          _addLog('onChatRoomDestroyed: roomId: $roomId, roomName: $roomName');
        },
        onMemberExitedFromChatRoom: (roomId, roomName, participant) {
          _addLog(
            'onMemberExitedFromChatRoom: roomId: $roomId, roomName: $roomName, participant: $participant',
          );
        },
        onMemberJoinedFromChatRoom: (roomId, participant, ext) {
          _addLog(
            'onMemberJoinedFromChatRoom: roomId: $roomId, participant: $participant, ext: $ext',
          );
        },
        onMuteListAddedFromChatRoom: (roomId, mutes) {
          _addLog(
            'onMuteListAddedFromChatRoom: roomId: $roomId, mutes: $mutes',
          );
        },
        onMuteListRemovedFromChatRoom: (roomId, mutes) {
          _addLog(
            'onMuteListRemovedFromChatRoom: roomId: $roomId, mutes: $mutes',
          );
        },
        onOwnerChangedFromChatRoom: (roomId, newOwner, oldOwner) {
          _addLog(
            'onOwnerChangedFromChatRoom: roomId: $roomId, newOwner: $newOwner, oldOwner: $oldOwner',
          );
        },
        onRemovedFromChatRoom: (roomId, roomName, participant, reason) {
          _addLog(
            'onRemovedFromChatRoom: roomId: $roomId, roomName: $roomName, participant: $participant, reason: $reason',
          );
        },
        onSpecificationChanged: (room) {
          _addLog('onSpecificationChanged: $room');
        },
      ),
    );
  }

  void _addLog(String content) {
    setState(() {
      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';
      _logs.insert(0, '$timeStr: $content');
    });
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
      _addLog('请先加入聊天室');
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
            _addLog('修改聊天室名称成功');
            break;
          case RoomInfoEditType.description:
            await EMClient.getInstance.chatRoomManager
                .changeChatRoomDescription(_roomId, newValue);
            _addLog('修改聊天室描述成功');
            break;
          case RoomInfoEditType.announcement:
            await EMClient.getInstance.chatRoomManager
                .updateChatRoomAnnouncement(_roomId, newValue);
            _addLog('修改聊天室公告成功');
            break;
        }
      }
    } catch (e) {
      _addLog('获取聊天室信息失败: ${e.toString()}');
    }
  }

  void _showMembersBottomSheet() {
    if (_roomId.isEmpty) {
      _addLog('请先加入聊天室');
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
      _addLog('请先加入聊天室');
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
      _addLog('请先加入聊天室');
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
      _addLog('请先加入聊天室');
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
      _addLog('请先加入聊天室');
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
      _addLog('请先加入聊天室');
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
            icon: const Icon(Icons.exit_to_app),
            tooltip: '退出聊天室',
            onPressed: () async {
              try {
                await EMClient.getInstance.chatRoomManager.leaveChatRoom(
                  _roomId,
                );
                _roomId = '';
                _addLog('退出成功');
              } catch (e) {
                _addLog('退出失败: ${e.toString()}');
              }
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
        child: SingleChildScrollView(
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
                  buttonText: 'Join',
                  onPressed: () async {
                    String showMsg = '';
                    try {
                      await EMClient.getInstance.chatRoomManager.joinChatRoom(
                        _roomIdController.text.trim(),
                      );
                      _roomId = _roomIdController.text;
                      showMsg = "加入成功";
                    } catch (e) {
                      showMsg =
                          '加入 ${_roomIdController.text} 失败：${e.toString()}';
                    } finally {
                      _addLog(showMsg);
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

                    final msg = EMMessage.createTxtSendMessage(
                      targetId: _roomId,
                      content: text,
                      chatType: ChatType.ChatRoom,
                    );
                    try {
                      await EMClient.getInstance.chatManager.sendMessage(msg);
                    } catch (e) {
                      _addLog('发送失败: ${e.toString()}');
                    }
                    _messageController.clear();
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('消息', isDark),
                const SizedBox(height: 10),
                _buildMessageTypeButtons(isDark),
                const SizedBox(height: 20),
                _buildSectionTitle('控制', isDark),
                const SizedBox(height: 10),
                _buildChatRoomManagementButtons(isDark),
                const SizedBox(height: 20),
                // 日志显示区域
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground(isDark),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.glassBorder(isDark)),
                  ),
                  constraints: const BoxConstraints(minHeight: 300),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '操作日志',
                              style: TextStyle(
                                color: AppColors.textPrimary(isDark),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.refresh,
                                size: 20,
                                color: AppColors.textSecondary(isDark),
                              ),
                              tooltip: '清空日志',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  _logs.clear();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: AppColors.glassBorder(isDark)),
                      _logs.isEmpty
                          ? Center(
                              child: Text(
                                '暂无日志',
                                style: TextStyle(
                                  color: AppColors.textSecondary(isDark),
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: _logs.length,
                              shrinkWrap: true, // 嵌套在滚动视图中需要 shrinkWrap
                              physics:
                                  const NeverScrollableScrollPhysics(), // 由外层 SingleChildScrollView 处理滚动
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    _logs[index],
                                    style: TextStyle(
                                      color: AppColors.textPrimary(isDark),
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
    final messageTypes = [
      {'icon': Icons.image_outlined, 'label': '图片'},
      {'icon': Icons.videocam_outlined, 'label': '视频'},
      {'icon': Icons.mic_outlined, 'label': '语音'},
      {'icon': Icons.description_outlined, 'label': '文件'},
      {'icon': Icons.location_on_outlined, 'label': '位置'},
      {'icon': Icons.extension_outlined, 'label': '自定义'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: messageTypes.map((type) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              onPressed: () async {
                if (type['label'] == '图片') {
                  try {
                    final filePath = await _getAssetFilePath(
                      'assets/image.jpg',
                    );
                    final msg = EMMessage.createImageSendMessage(
                      targetId: _roomId,
                      filePath: filePath,
                      width: 1920,
                      height: 1080,
                      fileSize: 111916,
                      chatType: ChatType.ChatRoom,
                    );
                    await EMClient.getInstance.chatManager.sendMessage(msg);
                  } catch (e) {
                    _addLog('发送图片失败: ${e.toString()}');
                  }
                }
                if (type['label'] == '视频') {
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
                  await EMClient.getInstance.chatManager.sendMessage(msg);
                }
                if (type['label'] == '语音') {
                  final filePath = await _getAssetFilePath('assets/voice.mp3');
                  final msg = EMMessage.createVoiceSendMessage(
                    targetId: _roomId,
                    filePath: filePath,
                    duration: 10,
                    fileSize: 111916,
                    chatType: ChatType.ChatRoom,
                  );
                  await EMClient.getInstance.chatManager.sendMessage(msg);
                }
                if (type['label'] == '文件') {
                  final filePath = await _getAssetFilePath('assets/voice.mp3');
                  final msg = EMMessage.createFileSendMessage(
                    targetId: _roomId,
                    filePath: filePath,
                    fileSize: 111916,
                    chatType: ChatType.ChatRoom,
                  );
                  await EMClient.getInstance.chatManager.sendMessage(msg);
                }
                if (type['label'] == '位置') {
                  final msg = EMMessage.createLocationSendMessage(
                    targetId: _roomId,
                    latitude: 39.9042,
                    longitude: 116.4074,
                    address: '北京市海淀区中关村',
                    chatType: ChatType.ChatRoom,
                  );
                  await EMClient.getInstance.chatManager.sendMessage(msg);
                }
                if (type['label'] == '自定义') {
                  _addLog('暂不支持');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.inputBackground(isDark),
                foregroundColor: AppColors.textPrimary(isDark),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.glassBorder(isDark)),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type['icon'] as IconData,
                    color: AppColors.primary(isDark),
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type['label'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChatRoomManagementButtons(bool isDark) {
    final managementActions = [
      {'icon': Icons.info_outline, 'label': '名称'},
      {'icon': Icons.info_outline, 'label': '描述'},
      {'icon': Icons.campaign_outlined, 'label': '公告'},
      {'icon': Icons.group_outlined, 'label': '成员'},
      {'icon': Icons.admin_panel_settings_outlined, 'label': '管理员'},
      {'icon': Icons.verified_user_outlined, 'label': '白名单'},
      {'icon': Icons.mic_off_outlined, 'label': '禁言列表'},
      {'icon': Icons.voice_over_off_outlined, 'label': '全部禁言'},
      {'icon': Icons.swap_horiz_outlined, 'label': '转移聊天室'},
    ];

    // 分组，每行6个
    List<List<Map<String, dynamic>>> rows = [];
    for (int i = 0; i < managementActions.length; i += 6) {
      rows.add(
        managementActions.sublist(
          i,
          i + 6 > managementActions.length ? managementActions.length : i + 6,
        ),
      );
    }

    return Column(
      children: rows.map((rowActions) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ...rowActions.map((action) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: () {
                        if (action['label'] == '名称') {
                          _showRoomInfoDialog(RoomInfoEditType.name);
                        } else if (action['label'] == '描述') {
                          _showRoomInfoDialog(RoomInfoEditType.description);
                        } else if (action['label'] == '公告') {
                          _showRoomInfoDialog(RoomInfoEditType.announcement);
                        } else if (action['label'] == '成员') {
                          _showMembersBottomSheet();
                        } else if (action['label'] == '管理员') {
                          _showAdminsBottomSheet();
                        } else if (action['label'] == '白名单') {
                          _showWhiteListBottomSheet();
                        } else if (action['label'] == '禁言列表') {
                          _showMuteListBottomSheet();
                        } else if (action['label'] == '全部禁言') {
                          _showMuteAllMuteAlert();
                        } else if (action['label'] == '转移聊天室') {
                          _showChangeOwnerBottomSheet();
                        } else {
                          _addLog('点击了${action['label']}');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.inputBackground(isDark),
                        foregroundColor: AppColors.textPrimary(isDark),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: AppColors.glassBorder(isDark),
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            action['icon'] as IconData,
                            color: AppColors.primary(isDark),
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            action['label'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary(isDark),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              // 如果这一行不满6个，添加空白占位
              ...List.generate(
                6 - rowActions.length,
                (index) => Expanded(child: SizedBox()),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
