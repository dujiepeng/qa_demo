import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/common/widgets/switch_alert.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_settings.dart';
import '../../common/widgets/input_dialog.dart';
import '../../common/widgets/log_view.dart';
import '../../common/widgets/log_view_actions.dart';
import '../../common/widgets/grid_action_menu.dart';
import '../../common/widgets/common_input_row.dart';
import '../../common/widgets/common_section_title.dart';
import '../../common/widgets/common_layout.dart';
import '../../common/mixins/base_mixin.dart';
import '../../common/widgets/log_page_launcher.dart';
import 'group_admins_page.dart';
import 'group_change_owner_page.dart';
import 'group_members_page.dart';
import 'group_mute_list_page.dart';
import 'group_white_list_page.dart';

/// 群组信息编辑类型
enum GroupInfoEditType { name, description, announcement }

typedef GroupInfoLoader = Future<EMGroup> Function(String groupId);
typedef PublicGroupJoiner = Future<void> Function(String groupId);
typedef PublicGroupJoinRequester =
    Future<void> Function(String groupId, {String? reason});
typedef GroupCreator =
    Future<EMGroup> Function({
      String? groupName,
      String? desc,
      List<String>? inviteMembers,
      String? inviteReason,
      required EMGroupOptions options,
    });
typedef GroupDestroyer = Future<void> Function(String groupId);
typedef GroupMessageBlocker = Future<void> Function(String groupId);

class GroupPage extends StatefulWidget {
  const GroupPage({
    super.key,
    this.groupId,
    this.showAppBar = true,
    this.groupInfoLoader,
    this.publicGroupJoiner,
    this.publicGroupJoinRequester,
    this.groupCreator,
    this.groupDestroyer,
    this.groupMessageBlocker,
    this.groupMessageUnblocker,
  });
  final String? groupId;
  final bool showAppBar;
  final GroupInfoLoader? groupInfoLoader;
  final PublicGroupJoiner? publicGroupJoiner;
  final PublicGroupJoinRequester? publicGroupJoinRequester;
  final GroupCreator? groupCreator;
  final GroupDestroyer? groupDestroyer;
  final GroupMessageBlocker? groupMessageBlocker;
  final GroupMessageBlocker? groupMessageUnblocker;
  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> with BaseMixin {
  final _eventKey = 'group_test';
  final _settings = AppSettings();
  final _groupIdController = TextEditingController();
  final _messageController = TextEditingController();
  final _logController = LogController();
  final _repeatCountController = TextEditingController(text: '1');
  bool _deliverOnlineOnly = false;
  String _groupId = '';
  EMGroupPermissionType? _permissionType;
  bool? _messageBlocked;

  @override
  LogController get logController => _logController;

  @override
  void initState() {
    _groupId = widget.groupId ?? '';
    _groupIdController.text = _groupId;
    super.initState();
    _addListener();
    _groupIdController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshGroupPermission();
      }
    });
  }

  @override
  void dispose() {
    _groupIdController.dispose();
    _messageController.dispose();
    _repeatCountController.dispose();
    super.dispose();
  }

  Future<void> _refreshGroupPermission() async {
    final groupId = _groupId.trim();
    if (groupId.isEmpty) {
      if (_permissionType != null) {
        setState(() => _permissionType = null);
      }
      return;
    }
    try {
      final group = await _fetchGroupInfo(groupId);
      if (!mounted || groupId != _groupId) return;
      setState(() {
        _permissionType = group.permissionType;
        _messageBlocked = group.messageBlocked;
      });
    } catch (e) {
      addLog('获取群权限失败: $e');
      if (mounted && groupId == _groupId) {
        setState(() {
          _permissionType = null;
          _messageBlocked = null;
        });
      }
    }
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
            if (msg.conversationId == _groupId) {
              addReceiveLog(
                '${msg.from}: ${msg.toJson().toString()}',
                attachment: msg,
                tag: 'message',
              );
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
        onInvitationAcceptedFromGroup: (groupId, invitee, reason) =>
            _handleGroupEvent(
              groupId,
              'onInvitationAcceptedFromGroup: invitee: $invitee, reason: $reason',
            ),
        onInvitationDeclinedFromGroup: (groupId, invitee, reason) =>
            _handleGroupEvent(
              groupId,
              'onInvitationDeclinedFromGroup: invitee: $invitee, reason: $reason',
            ),
        onAttributesChangedOfGroupMember:
            (groupId, userId, attributes, operatorId) => _handleGroupEvent(
              groupId,
              'onAttributesChanged: userId: $userId, attributes: $attributes',
            ),
        onGroupDestroyed: (groupId, groupName) {
          if (groupId == _groupId) {
            setState(() {
              _groupId = '';
              _permissionType = null;
              _messageBlocked = null;
            });
            addReceiveLog('onGroupDestroyed: $groupName');
          }
        },
        onUserRemovedFromGroup: (groupId, groupName) {
          if (groupId == _groupId) {
            setState(() {
              _groupId = '';
              _permissionType = null;
              _messageBlocked = null;
            });
            addReceiveLog('onUserRemovedFromGroup: $groupName');
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
    if (groupId == _groupId) addReceiveLog(log);
  }

  Future<EMGroup> _fetchGroupInfo(String groupId) {
    final loader = widget.groupInfoLoader;
    if (loader != null) {
      return loader(groupId);
    }
    return EMClient.getInstance.groupManager.fetchGroupInfoFromServer(groupId);
  }

  Future<void> _joinPublicGroup(String groupId) {
    final joiner = widget.publicGroupJoiner;
    if (joiner != null) {
      return joiner(groupId);
    }
    return EMClient.getInstance.groupManager.joinPublicGroup(groupId);
  }

  Future<void> _requestToJoinPublicGroup(String groupId, {String? reason}) {
    final requester = widget.publicGroupJoinRequester;
    if (requester != null) {
      return requester(groupId, reason: reason);
    }
    return EMClient.getInstance.groupManager.requestToJoinPublicGroup(
      groupId,
      reason: reason,
    );
  }

  Future<EMGroup> _createGroup({
    String? groupName,
    String? desc,
    List<String>? inviteMembers,
    String? inviteReason,
    required EMGroupOptions options,
  }) {
    final creator = widget.groupCreator;
    if (creator != null) {
      return creator(
        groupName: groupName,
        desc: desc,
        inviteMembers: inviteMembers,
        inviteReason: inviteReason,
        options: options,
      );
    }
    return EMClient.getInstance.groupManager.createGroup(
      groupName: groupName,
      desc: desc,
      inviteMembers: inviteMembers,
      inviteReason: inviteReason,
      options: options,
    );
  }

  Future<void> _destroyGroup(String groupId) {
    final destroyer = widget.groupDestroyer;
    if (destroyer != null) {
      return destroyer(groupId);
    }
    return EMClient.getInstance.groupManager.destroyGroup(groupId);
  }

  Future<void> _blockGroupMessages(String groupId) {
    final blocker = widget.groupMessageBlocker;
    if (blocker != null) {
      return blocker(groupId);
    }
    return EMClient.getInstance.groupManager.blockGroup(groupId);
  }

  Future<void> _unblockGroupMessages(String groupId) {
    final unblocker = widget.groupMessageUnblocker;
    if (unblocker != null) {
      return unblocker(groupId);
    }
    return EMClient.getInstance.groupManager.unblockGroup(groupId);
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textPrimary(isDark)),
      title: Text(
        _groupId.isNotEmpty ? '$_groupId(群)' : '群组测试',
        style: TextStyle(color: AppColors.textPrimary(isDark)),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.info),
          onPressed: () => Navigator.of(context).pushNamed('/server_config'),
        ),
      ],
    );
  }

  Widget _buildControlPanel(bool isDark, bool isWide) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CommonInputRow(
                controller: _groupIdController,
                hintText: '输入群组 ID',
                buttonText: _groupId.isNotEmpty ? 'Leave' : 'Join',
                onPressed: _handleJoinLeaveGroup,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Checkbox(
              value: _deliverOnlineOnly,
              onChanged: (value) {
                setState(() {
                  _deliverOnlineOnly = value ?? false;
                });
              },
            ),
            Text(
              '只发在线',
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
        _buildGroupManagementButtons(isDark),
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
      actionsBuilder: (_) => [LogViewActions.copyEntry()],
    );
  }

  Future<void> _handleJoinLeaveGroup() async {
    final inputId = _groupIdController.text.trim();
    if (inputId.isEmpty) return;

    if (_groupId.isNotEmpty && _groupId == inputId) {
      addLog('开始离开 $_groupId');
      try {
        await EMClient.getInstance.groupManager.leaveGroup(_groupId);
        addLog('退出 $_groupId 成功');
        setState(() {
          _groupId = '';
          _permissionType = null;
          _messageBlocked = null;
        });
      } catch (e) {
        addLog('退出 $_groupId 失败: ${e.toString()}');
      }
    } else {
      addLog('开始加入 $inputId');
      try {
        final group = await _fetchGroupInfo(inputId);
        if (group.isMemberOnly == true) {
          await _requestToJoinPublicGroup(
            inputId,
            reason: 'QA app request to join group',
          );
          addLog('已发送入群申请，GroupId: $inputId');
          return;
        }
        if (group.isMemberOnly != false) {
          addLog('加入 $inputId 失败：服务端未返回入群审批信息');
          return;
        }
        await _joinPublicGroup(inputId);
        setState(() => _groupId = inputId);
        _refreshGroupPermission();
        addLog('加入成功， GroupId: $inputId');
      } catch (e) {
        addLog('加入 $inputId 失败：${e.toString()}');
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
      addAppErrLog('发送文字失败: ${e.toString()}');
    }
  }

  Future<void> sendMessage(EMMessage msg) async {
    if (_groupId.isEmpty) {
      addSendLog('请先加入群组');
      return;
    }
    try {
      msg.deliverOnlineOnly = _deliverOnlineOnly;
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

  Future<void> _showGroupInfoDialog(GroupInfoEditType type) async {
    if (_groupId.isEmpty) {
      addSendLog('请先加入群组');
      return;
    }
    try {
      final group = await _fetchGroupInfo(_groupId);
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
        addSendLog('修改成功');
      }
    } catch (e) {
      addSendLog('操作失败: ${e.toString()}');
    }
  }

  Future<void> _showGroupDetails() async {
    if (_groupId.isEmpty) {
      addSendLog('请先加入群组');
      return;
    }
    try {
      final group = await _fetchGroupInfo(_groupId);
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
      addSendLog('获取详情失败: $e');
    }
  }

  void _showBottomSheet(Widget page) {
    if (_groupId.isEmpty) {
      addSendLog('请先加入群组');
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
    final group = await _fetchGroupInfo(_groupId);
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
          addLog('操作成功');
          return true;
        } catch (e) {
          addAppErrLog('报错: $e');
          return false;
        }
      },
    );
  }

  Future<void> _showCreateGroupDialog() async {
    final result = await showDialog<_CreateGroupFormData>(
      context: context,
      builder: (context) => const _CreateGroupDialog(),
    );
    if (result == null) return;
    if (result.groupName.isEmpty) {
      addLog('创建群组失败: 群组名称不能为空');
      return;
    }
    try {
      addLog('开始创建群组: ${result.groupName}');
      final group = await _createGroup(
        groupName: result.groupName,
        desc: result.description,
        inviteMembers: result.inviteMembers,
        inviteReason: result.reason,
        options: EMGroupOptions(
          style: result.style,
          maxCount: result.maxCount,
          inviteNeedConfirm: result.inviteNeedConfirm,
        ),
      );
      if (!mounted) return;
      setState(() {
        _groupId = group.groupId;
        _groupIdController.text = group.groupId;
        _permissionType = EMGroupPermissionType.Owner;
        _messageBlocked = group.messageBlocked;
      });
      addLog('创建群组成功，GroupId: ${group.groupId}');
    } catch (e) {
      addLog('创建群组失败: $e');
    }
  }

  Future<void> _destroyCurrentGroup() async {
    if (_groupId.isEmpty) {
      addLog('请先加入群组');
      return;
    }
    if (_permissionType != EMGroupPermissionType.Owner) {
      addLog('解散失败: 仅群主可以解散群组');
      return;
    }
    final targetGroupId = _groupId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('解散群组'),
        content: Text('确定要解散群组 $targetGroupId 吗？该操作会删除本地群信息和群会话。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定解散'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      addLog('开始解散群组: $targetGroupId');
      await _destroyGroup(targetGroupId);
      if (!mounted) return;
      setState(() {
        if (_groupId == targetGroupId) {
          _groupId = '';
          _groupIdController.clear();
          _permissionType = null;
          _messageBlocked = null;
        }
      });
      addLog('解散群组成功: $targetGroupId');
    } catch (e) {
      addLog('解散群组失败: $e');
    }
  }

  Future<void> _toggleGroupMessageBlock() async {
    if (_groupId.isEmpty) {
      addLog('请先加入群组');
      return;
    }
    if (_permissionType != EMGroupPermissionType.Member) {
      addLog('群主和管理员不能屏蔽群消息');
      return;
    }
    final shouldUnblock = _messageBlocked == true;
    try {
      if (shouldUnblock) {
        addLog('开始解除屏蔽群消息: $_groupId');
        await _unblockGroupMessages(_groupId);
      } else {
        addLog('开始屏蔽群消息: $_groupId');
        await _blockGroupMessages(_groupId);
      }
      await _refreshGroupPermission();
      addLog(shouldUnblock ? '解除屏蔽群消息成功' : '屏蔽群消息成功');
    } catch (e) {
      addLog(shouldUnblock ? '解除屏蔽群消息失败: $e' : '屏蔽群消息失败: $e');
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
            addAppErrLog('发送$label失败: $e');
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
          filePath: await getAssetFilePath('assets/image.jpg'),
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
          filePath: await getAssetFilePath('assets/video.mp4'),
          thumbnailLocalPath: await getAssetFilePath('assets/image.jpg'),
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
          filePath: await getAssetFilePath('assets/voice.mp3'),
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
          filePath: await getAssetFilePath('assets/voice.mp3'),
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
    final canDestroyGroup = _groupId.isNotEmpty &&
        _permissionType == EMGroupPermissionType.Owner;
    final canToggleMessageBlock = _groupId.isNotEmpty &&
        _permissionType == EMGroupPermissionType.Member;
    final isMessageBlocked = _messageBlocked == true;
    final items = [
      GridActionItem(
        icon: Icons.add_circle_outline,
        label: '创建',
        onTap: _showCreateGroupDialog,
      ),
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
        onTap: () => _showBottomSheet(GroupMembersPage(groupId: _groupId)),
      ),
      GridActionItem(
        icon: Icons.admin_panel_settings_outlined,
        label: '管理员',
        onTap: () => _showBottomSheet(GroupAdminsPage(groupId: _groupId)),
      ),
      GridActionItem(
        icon: Icons.verified_user_outlined,
        label: '白名单',
        onTap: () => _showBottomSheet(GroupWhiteListPage(groupId: _groupId)),
      ),
      GridActionItem(
        icon: Icons.mic_off_outlined,
        label: '禁言列表',
        onTap: () => _showBottomSheet(GroupMuteListPage(groupId: _groupId)),
      ),
      GridActionItem(
        icon: Icons.voice_over_off_outlined,
        label: '全部禁言',
        onTap: _showMuteAllMuteAlert,
      ),
      GridActionItem(
        icon: isMessageBlocked
            ? Icons.notifications_active_outlined
            : Icons.notifications_off_outlined,
        label: isMessageBlocked ? '解除屏蔽' : '屏蔽消息',
        onTap: canToggleMessageBlock ? _toggleGroupMessageBlock : null,
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
            addLog('设置成功');
          } catch (e) {
            addAppErrLog('失败: $e');
          }
        },
      ),
      GridActionItem(
        icon: Icons.swap_horiz_outlined,
        label: '转移',
        onTap: () => _showBottomSheet(GroupChangeOwnerPage(groupId: _groupId)),
      ),
      GridActionItem(
        icon: Icons.delete_forever_outlined,
        label: '解散',
        onTap: canDestroyGroup ? _destroyCurrentGroup : null,
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

class _CreateGroupFormData {
  const _CreateGroupFormData({
    required this.groupName,
    required this.description,
    required this.inviteMembers,
    required this.reason,
    required this.style,
    required this.inviteNeedConfirm,
    required this.maxCount,
  });

  final String groupName;
  final String description;
  final List<String> inviteMembers;
  final String reason;
  final EMGroupStyle style;
  final bool inviteNeedConfirm;
  final int maxCount;
}

class _CreateGroupDialog extends StatefulWidget {
  const _CreateGroupDialog();

  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _membersController = TextEditingController();
  final _reasonController = TextEditingController();
  final _maxCountController = TextEditingController(text: '200');
  EMGroupStyle _style = EMGroupStyle.PrivateMemberCanInvite;
  bool _inviteNeedConfirm = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _membersController.dispose();
    _reasonController.dispose();
    _maxCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('创建群组'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '群组名称'),
            ),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: '群组描述'),
            ),
            TextField(
              controller: _membersController,
              decoration: const InputDecoration(labelText: '邀请成员，英文逗号分隔'),
            ),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(labelText: '创建/邀请原因'),
            ),
            TextField(
              controller: _maxCountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '最大人数'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<EMGroupStyle>(
              initialValue: _style,
              decoration: const InputDecoration(labelText: '群组类型'),
              items: const [
                DropdownMenuItem(
                  value: EMGroupStyle.PrivateOnlyOwnerInvite,
                  child: Text('私有仅群主邀请'),
                ),
                DropdownMenuItem(
                  value: EMGroupStyle.PrivateMemberCanInvite,
                  child: Text('私有成员可邀请'),
                ),
                DropdownMenuItem(
                  value: EMGroupStyle.PublicJoinNeedApproval,
                  child: Text('公开入群需审批'),
                ),
                DropdownMenuItem(
                  value: EMGroupStyle.PublicOpenJoin,
                  child: Text('公开自由加入'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _style = value);
                }
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('需要确认'),
              value: _inviteNeedConfirm,
              onChanged: (value) {
                setState(() => _inviteNeedConfirm = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final members = _membersController.text
                .split(',')
                .map((member) => member.trim())
                .where((member) => member.isNotEmpty)
                .toList();
            Navigator.pop(
              context,
              _CreateGroupFormData(
                groupName: _nameController.text.trim(),
                description: _descController.text.trim(),
                inviteMembers: members,
                reason: _reasonController.text.trim(),
                style: _style,
                inviteNeedConfirm: _inviteNeedConfirm,
                maxCount: int.tryParse(_maxCountController.text.trim()) ?? 200,
              ),
            );
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}
