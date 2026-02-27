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
import '../../common/widgets/log_view.dart';
import '../../common/widgets/grid_action_menu.dart';
import '../../common/log_content_page.dart';
import 'test_group_admins_page.dart';
import 'test_group_change_owner_page.dart';
import 'test_group_members_page.dart';
import 'test_group_mute_list_page.dart';
import 'test_group_white_list_page.dart';

/// 群组信息编辑类型
enum GroupInfoEditType { name, description, announcement }

class TestGroupPage extends StatefulWidget {
  const TestGroupPage({super.key, this.groupId, this.showAppBar = true});
  final String? groupId;
  final bool showAppBar;
  @override
  State<TestGroupPage> createState() => _TestGroupPageState();
}

class _TestGroupPageState extends State<TestGroupPage> {
  final _eventKey = 'group_test';
  final _settings = AppSettings();
  final _groupIdController = TextEditingController();
  final _messageController = TextEditingController();
  final _logController = LogController();
  final _repeatCountController = TextEditingController(text: '1');
  String _groupId = '';

  @override
  void initState() {
    _groupId = widget.groupId ?? '';
    _groupIdController.text = _groupId;
    super.initState();
    _addListener();
    _groupIdController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _groupIdController.dispose();
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
            if (msg.conversationId == _groupId) {
              _addReceiveLog('${msg.from}: ${msg.toJson().toString()}');
            }
          }
        },
      ),
    );

    EMClient.getInstance.groupManager.addEventHandler(
      _eventKey,
      EMGroupEventHandler(
        onAdminAddedFromGroup: (groupId, admin) =>
            _handleGroupEvent(groupId, 'onAdminAddedFromGroup: admin: $admin'),
        onAdminRemovedFromGroup: (groupId, admin) => _handleGroupEvent(
          groupId,
          'onAdminRemovedFromGroup: admin: $admin',
        ),
        onAllGroupMemberMuteStateChanged: (groupId, isAllMuted) =>
            _handleGroupEvent(
              groupId,
              'onAllGroupMemberMuteStateChanged: isAllMuted: $isAllMuted',
            ),
        onAllowListAddedFromGroup: (groupId, members) => _handleGroupEvent(
          groupId,
          'onAllowListAddedFromGroup: members: $members',
        ),
        onAllowListRemovedFromGroup: (groupId, members) => _handleGroupEvent(
          groupId,
          'onAllowListRemovedFromGroup: members: $members',
        ),
        onAnnouncementChangedFromGroup: (groupId, announcement) =>
            _handleGroupEvent(
              groupId,
              'onAnnouncementChangedFromGroup: announcement: $announcement',
            ),
        onAttributesChangedOfGroupMember:
            (groupId, userId, attributes, operatorId) => _handleGroupEvent(
              groupId,
              'onAttributesChanged: userId: $userId, attributes: $attributes',
            ),
        onGroupDestroyed: (groupId, groupName) {
          if (groupId == _groupId) {
            setState(() => _groupId = '');
            _addReceiveLog('onGroupDestroyed: $groupName');
          }
        },
        onUserRemovedFromGroup: (groupId, groupName) {
          if (groupId == _groupId) {
            setState(() => _groupId = '');
            _addReceiveLog('onUserRemovedFromGroup: $groupName');
          }
        },
        onSpecificationDidUpdate: (group) => _handleGroupEvent(
          group.groupId,
          'onSpecificationDidUpdate: name: ${group.groupName}',
        ),
      ),
    );
  }

  void _handleGroupEvent(String groupId, String log) {
    if (groupId == _groupId) _addReceiveLog(log);
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
      toolbarHeight: kToolbarHeight + 20,
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textPrimary(isDark)),
      title: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Text(
          _groupId.isNotEmpty ? '$_groupId(群)' : '群组测试',
          style: TextStyle(color: AppColors.textPrimary(isDark)),
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: IconButton(
            icon: const Icon(Icons.info),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ),
      ],
    );
  }

  Widget _buildControlPanel(bool isDark, bool isWide) {
    return Column(
      children: [
        _buildInputRow(
          controller: _groupIdController,
          hintText: '输入群组 ID',
          buttonText: _groupId.isNotEmpty ? 'Leave' : 'Join',
          onPressed: _handleJoinLeaveGroup,
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
        _buildGroupManagementButtons(isDark),
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

  Future<void> _handleJoinLeaveGroup() async {
    final inputId = _groupIdController.text.trim();
    if (inputId.isEmpty) return;

    if (_groupId.isNotEmpty && _groupId == inputId) {
      _addLog('开始离开 $_groupId');
      try {
        await EMClient.getInstance.groupManager.leaveGroup(_groupId);
        _addLog('退出 $_groupId 成功');
        setState(() => _groupId = '');
      } catch (e) {
        _addLog('退出 $_groupId 失败: ${e.toString()}');
      }
    } else {
      _addLog('开始加入 $inputId');
      try {
        await EMClient.getInstance.groupManager.joinPublicGroup(inputId);
        setState(() => _groupId = inputId);
        _addLog('加入成功， GroupId: $inputId');
      } catch (e) {
        _addLog('加入 $inputId 失败：${e.toString()}');
      }
    }
  }

  Future<void> _sendTextMessage(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty || _groupId.isEmpty) return;
    int count = int.tryParse(_repeatCountController.text) ?? 1;
    try {
      for (int i = 0; i < count; i++) {
        final msg = EMMessage.createTxtSendMessage(
          targetId: _groupId,
          content: count > 1 ? '$trimmedText ($i)' : trimmedText,
          chatType: ChatType.GroupChat,
        );
        await sendMessage(msg);
      }
      _messageController.clear();
    } catch (e) {
      _addAppErrLog('发送文字失败: ${e.toString()}');
    }
  }

  Future<void> sendMessage(EMMessage msg) async {
    if (_groupId.isEmpty) {
      _addSendLog('请先加入群组');
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

  // --- 弹窗相关逻辑已合并或抽离 ---

  Future<void> _showGroupInfoDialog(GroupInfoEditType type) async {
    if (_groupId.isEmpty) {
      _addSendLog('请先加入群组');
      return;
    }
    try {
      final group = await EMClient.getInstance.groupManager
          .fetchGroupInfoFromServer(_groupId);
      if (!mounted) return;
      String title = '', fieldTitle = '', placeholder = '', currentValue = '';
      bool multiline = false;

      switch (type) {
        case GroupInfoEditType.name:
          title = '编辑群组名称';
          fieldTitle = '群组名称';
          placeholder = '请输入群组名称';
          currentValue = group.groupName ?? '';
          break;
        case GroupInfoEditType.description:
          title = '编辑群组描述';
          fieldTitle = '群组描述';
          placeholder = '请输入群组描述';
          currentValue = group.desc ?? '';
          multiline = true;
          break;
        case GroupInfoEditType.announcement:
          title = '编辑群组公告';
          fieldTitle = '群组公告';
          placeholder = '请输入群组公告';
          currentValue = group.announcement ?? '';
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
          case GroupInfoEditType.name:
            await EMClient.getInstance.groupManager.updateGroupName(
              _groupId,
              newValue,
            );
            break;
          case GroupInfoEditType.description:
            await EMClient.getInstance.groupManager.updateGroupDesc(
              _groupId,
              newValue,
            );
            break;
          case GroupInfoEditType.announcement:
            await EMClient.getInstance.groupManager.updateGroupAnnouncement(
              _groupId,
              newValue,
            );
            break;
        }
        _addSendLog('修改成功');
      }
    } catch (e) {
      _addSendLog('操作失败: ${e.toString()}');
    }
  }

  Future<void> _showGroupDetails() async {
    if (_groupId.isEmpty) {
      _addSendLog('请先加入群组');
      return;
    }
    try {
      final group = await EMClient.getInstance.groupManager
          .fetchGroupInfoFromServer(_groupId);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(group.groupName ?? '群组详情'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: ${group.groupId}'),
                const SizedBox(height: 8),
                Text('Owner: ${group.owner}'),
                const SizedBox(height: 8),
                Text('Member Count: ${group.memberCount}'),
              ],
            ),
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
      _addSendLog('获取详情失败: $e');
    }
  }

  void _showBottomSheet(Widget page) {
    if (_groupId.isEmpty) {
      _addSendLog('请先加入群组');
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
          child: page,
        ),
      ),
    );
  }

  void _showMuteAllMuteAlert() async {
    if (_groupId.isEmpty) return;
    final group = await EMClient.getInstance.groupManager
        .fetchGroupInfoFromServer(_groupId);
    if (!mounted) return;
    showSwitchAlert(
      context: context,
      title: '全部禁言',
      description: '确定要操作吗？',
      initialValue: group.isAllMemberMuted ?? false,
      onChanged: (value) async {
        try {
          if (value) {
            await EMClient.getInstance.groupManager.muteAllMembers(_groupId);
          } else {
            await EMClient.getInstance.groupManager.unMuteAllMembers(_groupId);
          }
          _addLog('操作成功');
          return true;
        } catch (e) {
          _addAppErrLog('报错: $e');
          return false;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _settings.isDarkMode;
    final padding = EdgeInsets.only(
      top: widget.showAppBar ? (kToolbarHeight + 80) : 40,
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
    GridActionItem buildItem(
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
            _addAppErrLog('发送$label失败: $e');
          }
        },
      );
    }

    final items = [
      buildItem(
        Icons.image_outlined,
        '图片',
        () async => EMMessage.createImageSendMessage(
          targetId: _groupId,
          filePath: await _getAssetFilePath('assets/image.jpg'),
          width: 1920,
          height: 1080,
          fileSize: 111916,
          chatType: ChatType.GroupChat,
        ),
      ),
      buildItem(
        Icons.videocam_outlined,
        '视频',
        () async => EMMessage.createVideoSendMessage(
          targetId: _groupId,
          filePath: await _getAssetFilePath('assets/video.mp4'),
          thumbnailLocalPath: await _getAssetFilePath('assets/image.jpg'),
          width: 1920,
          height: 1080,
          duration: 10,
          fileSize: 4006696,
          chatType: ChatType.GroupChat,
        ),
      ),
      buildItem(
        Icons.mic_outlined,
        '语音',
        () async => EMMessage.createVoiceSendMessage(
          targetId: _groupId,
          filePath: await _getAssetFilePath('assets/voice.mp3'),
          duration: 10,
          fileSize: 111916,
          chatType: ChatType.GroupChat,
        ),
      ),
      buildItem(
        Icons.description_outlined,
        '文件',
        () async => EMMessage.createFileSendMessage(
          targetId: _groupId,
          filePath: await _getAssetFilePath('assets/voice.mp3'),
          fileSize: 111916,
          chatType: ChatType.GroupChat,
        ),
      ),
      buildItem(
        Icons.location_on_outlined,
        '位置',
        () async => EMMessage.createLocationSendMessage(
          targetId: _groupId,
          latitude: 39.9042,
          longitude: 116.4074,
          address: '北京市海淀区中关村',
          chatType: ChatType.GroupChat,
        ),
      ),
      buildItem(
        Icons.extension_outlined,
        '自定义',
        () async => EMMessage.createCustomSendMessage(
          targetId: _groupId,
          event: 'eventValue',
          params: {'paramsKey': 'paramsValue'},
          chatType: ChatType.GroupChat,
        ),
      ),
    ];
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: GridActionMenu(items: items, isDark: isDark, columns: 6),
    );
  }

  Widget _buildGroupManagementButtons(bool isDark) {
    final items = [
      GridActionItem(
        icon: Icons.assignment_outlined,
        label: '详情',
        onTap: _showGroupDetails,
      ),
      GridActionItem(
        icon: Icons.drive_file_rename_outline,
        label: '名称',
        onTap: () => _showGroupInfoDialog(GroupInfoEditType.name),
      ),
      GridActionItem(
        icon: Icons.subject,
        label: '描述',
        onTap: () => _showGroupInfoDialog(GroupInfoEditType.description),
      ),
      GridActionItem(
        icon: Icons.campaign_outlined,
        label: '公告',
        onTap: () => _showGroupInfoDialog(GroupInfoEditType.announcement),
      ),
      GridActionItem(
        icon: Icons.group_outlined,
        label: '成员',
        onTap: () => _showBottomSheet(TestGroupMembersPage(groupId: _groupId)),
      ),
      GridActionItem(
        icon: Icons.admin_panel_settings_outlined,
        label: '管理员',
        onTap: () => _showBottomSheet(TestGroupAdminsPage(groupId: _groupId)),
      ),
      GridActionItem(
        icon: Icons.verified_user_outlined,
        label: '白名单',
        onTap: () =>
            _showBottomSheet(TestGroupWhiteListPage(groupId: _groupId)),
      ),
      GridActionItem(
        icon: Icons.mic_off_outlined,
        label: '禁言列表',
        onTap: () => _showBottomSheet(TestGroupMuteListPage(groupId: _groupId)),
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
          if (_groupId.isEmpty) return;
          try {
            await EMClient.getInstance.groupManager.setMemberAttributes(
              groupId: _groupId,
              attributes: {'attKey': 'att_${DateTime.now()}'},
            );
            _addLog('设置成功');
          } catch (e) {
            _addAppErrLog('失败: $e');
          }
        },
      ),
      GridActionItem(
        icon: Icons.swap_horiz_outlined,
        label: '转移',
        onTap: () =>
            _showBottomSheet(TestGroupChangeOwnerPage(groupId: _groupId)),
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
          final userId = await EMClient.getInstance.getCurrentUserId();
          final deviceId = await EMClient.getInstance.getCurrentDeviceId();
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('个人信息'),
              content: Text('用户: $userId\n设备: $deviceId'),
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
