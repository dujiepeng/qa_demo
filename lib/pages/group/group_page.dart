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
import '../../common/utils/message_forward_helper.dart';
import '../../common/widgets/log_page_launcher.dart';
import '../thread/chat_thread_page.dart';
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
typedef GroupAllMembersMuteUpdater = Future<void> Function(String groupId);
typedef GroupMessageSender = Future<EMMessage> Function(EMMessage message);
typedef GroupMembersLoader =
    Future<EMCursorResult<String>> Function(
      String groupId, {
      String cursor,
      int pageSize,
    });
typedef OldGroupNameUpdater =
    Future<void> Function(String groupId, String name);
typedef OldGroupDescriptionUpdater =
    Future<void> Function(String groupId, String desc);
typedef OldGroupInviter =
    Future<void> Function(
      String groupId,
      List<String> members, {
      String? reason,
    });
typedef GroupMessageReadAckSender =
    Future<void> Function(String msgId, String groupId, {String? content});
typedef PublicGroupsFetcher =
    Future<EMCursorResult<EMGroupInfo>> Function({
      int pageSize,
      String? cursor,
    });
typedef GroupMembershipChecker = Future<bool> Function(String groupId);
typedef GroupAcksFetcher =
    Future<EMCursorResult<EMGroupMessageAck>> Function(
      String msgId,
      String groupId, {
      String? startAckId,
      int pageSize,
    });
typedef GroupAnnouncementFetcher = Future<String?> Function(String groupId);
typedef GroupAvatarUpdater =
    Future<EMGroup> Function({
      required String groupId,
      required String avatarUrl,
    });
typedef GroupExtensionUpdater =
    Future<void> Function(String groupId, String extension);
typedef GroupSharedFileListFetcher =
    Future<List<EMGroupSharedFile>> Function(
      String groupId, {
      int pageSize,
      int pageNum,
    });
typedef GroupSharedFileUploader =
    Future<void> Function(String groupId, String filePath);
typedef GroupSharedFileUploadPathProvider = Future<String> Function();
typedef GroupSharedFileDownloader =
    Future<void> Function({
      required String groupId,
      required String fileId,
      required String savePath,
    });
typedef GroupSharedFileRemover =
    Future<void> Function(String groupId, String fileId);
typedef GroupMembersInfoFetcher =
    Future<EMCursorResult<GroupMemberInfo>> Function({
      required String groupId,
      String? cursor,
      int limit,
    });
typedef GroupMemberNameCardSetter =
    Future<void> Function({
      required String groupId,
      required String userId,
      required String nameCard,
    });

List<String>? parseGroupReceiverList(String rawValue) {
  final list = rawValue
      .split(RegExp(r'[,，\n]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList();
  return list.isEmpty ? null : list;
}

EMMessage createGroupCommandMessage(String groupId) {
  return EMMessage.createCmdSendMessage(
    targetId: groupId,
    action: 'action1',
    chatType: ChatType.GroupChat,
  );
}

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
    this.groupAllMembersMuter,
    this.groupAllMembersUnmuter,
    this.messageSender,
    this.oldGroupNameUpdater,
    this.oldGroupDescriptionUpdater,
    this.oldGroupInviter,
    this.publicGroupsFetcher,
    this.groupAllowListMembershipChecker,
    this.groupMuteListMembershipChecker,
    this.groupMessageReadAckSender,
    this.groupAcksFetcher,
    this.groupAnnouncementFetcher,
    this.groupAvatarUpdater,
    this.groupExtensionUpdater,
    this.groupSharedFileListFetcher,
    this.groupSharedFileUploader,
    this.groupSharedFileUploadPathProvider,
    this.groupSharedFileDownloader,
    this.groupSharedFileRemover,
    this.groupMembersLoader,
    this.groupMembersInfoFetcher,
    this.groupMemberNameCardSetter,
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
  final GroupAllMembersMuteUpdater? groupAllMembersMuter;
  final GroupAllMembersMuteUpdater? groupAllMembersUnmuter;
  final GroupMessageSender? messageSender;
  final OldGroupNameUpdater? oldGroupNameUpdater;
  final OldGroupDescriptionUpdater? oldGroupDescriptionUpdater;
  final OldGroupInviter? oldGroupInviter;
  final PublicGroupsFetcher? publicGroupsFetcher;
  final GroupMembershipChecker? groupAllowListMembershipChecker;
  final GroupMembershipChecker? groupMuteListMembershipChecker;
  final GroupMessageReadAckSender? groupMessageReadAckSender;
  final GroupAcksFetcher? groupAcksFetcher;
  final GroupAnnouncementFetcher? groupAnnouncementFetcher;
  final GroupAvatarUpdater? groupAvatarUpdater;
  final GroupExtensionUpdater? groupExtensionUpdater;
  final GroupSharedFileListFetcher? groupSharedFileListFetcher;
  final GroupSharedFileUploader? groupSharedFileUploader;
  final GroupSharedFileUploadPathProvider? groupSharedFileUploadPathProvider;
  final GroupSharedFileDownloader? groupSharedFileDownloader;
  final GroupSharedFileRemover? groupSharedFileRemover;
  final GroupMembersLoader? groupMembersLoader;
  final GroupMembersInfoFetcher? groupMembersInfoFetcher;
  final GroupMemberNameCardSetter? groupMemberNameCardSetter;
  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> with BaseMixin {
  final _eventKey = 'group_test';
  final _settings = AppSettings();
  final _groupIdController = TextEditingController();
  final _messageController = TextEditingController();
  final _receiverListController = TextEditingController();
  final _logController = LogController();
  final _repeatCountController = TextEditingController(text: '1');
  final List<EMGroupSharedFile> _sharedFiles = [];
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
    _receiverListController.dispose();
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
        onGroupMessageRead: (acks) {
          for (final ack in acks) {
            addReceiveLog(
              '收到群消息已读回执: msgId=${ack.messageId}, from=${ack.from}, count=${ack.readCount}, content=${ack.content}',
            );
          }
        },
        onReadAckForGroupMessageUpdated: () {
          addReceiveLog('群消息已读状态更新');
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

  Future<void> _muteAllGroupMembers(String groupId) {
    final muter = widget.groupAllMembersMuter;
    if (muter != null) {
      return muter(groupId);
    }
    return EMClient.getInstance.groupManager.muteAllMembers(groupId);
  }

  Future<void> _unmuteAllGroupMembers(String groupId) {
    final unmuter = widget.groupAllMembersUnmuter;
    if (unmuter != null) {
      return unmuter(groupId);
    }
    return EMClient.getInstance.groupManager.unMuteAllMembers(groupId);
  }

  Future<void> _changeGroupNameOld(String groupId, String name) {
    final updater = widget.oldGroupNameUpdater;
    if (updater != null) {
      return updater(groupId, name);
    }
    // ignore: deprecated_member_use
    return EMClient.getInstance.groupManager.changeGroupName(groupId, name);
  }

  Future<void> _changeGroupDescriptionOld(String groupId, String desc) {
    final updater = widget.oldGroupDescriptionUpdater;
    if (updater != null) {
      return updater(groupId, desc);
    }
    // ignore: deprecated_member_use
    return EMClient.getInstance.groupManager.changeGroupDescription(
      groupId,
      desc,
    );
  }

  Future<void> _inviteGroupMembersOld(
    String groupId,
    List<String> members, {
    String? reason,
  }) {
    final inviter = widget.oldGroupInviter;
    if (inviter != null) {
      return inviter(groupId, members, reason: reason);
    }
    // ignore: deprecated_member_use
    return EMClient.getInstance.groupManager.inviterUser(
      groupId,
      members,
      reason: reason,
    );
  }

  Future<EMCursorResult<EMGroupInfo>> _fetchPublicGroups({
    int pageSize = 20,
    String? cursor,
  }) {
    final fetcher = widget.publicGroupsFetcher;
    if (fetcher != null) {
      return fetcher(pageSize: pageSize, cursor: cursor);
    }
    return EMClient.getInstance.groupManager.fetchPublicGroupsFromServer(
      pageSize: pageSize,
      cursor: cursor,
    );
  }

  Future<bool> _isMemberInAllowListFromServer(String groupId) {
    final checker = widget.groupAllowListMembershipChecker;
    if (checker != null) {
      return checker(groupId);
    }
    return EMClient.getInstance.groupManager.isMemberInAllowListFromServer(
      groupId,
    );
  }

  Future<bool> _isMemberInGroupMuteList(String groupId) {
    final checker = widget.groupMuteListMembershipChecker;
    if (checker != null) {
      return checker(groupId);
    }
    return EMClient.getInstance.groupManager.isMemberInGroupMuteList(groupId);
  }

  Future<String?> _fetchGroupAnnouncement(String groupId) {
    final fetcher = widget.groupAnnouncementFetcher;
    if (fetcher != null) {
      return fetcher(groupId);
    }
    return EMClient.getInstance.groupManager.fetchAnnouncementFromServer(
      groupId,
    );
  }

  Future<EMGroup> _updateGroupAvatar(String groupId, String avatarUrl) {
    final updater = widget.groupAvatarUpdater;
    if (updater != null) {
      return updater(groupId: groupId, avatarUrl: avatarUrl);
    }
    return EMClient.getInstance.groupManager.updateGroupAvatar(
      groupId: groupId,
      avatarUrl: avatarUrl,
    );
  }

  Future<void> _updateGroupExtension(String groupId, String extension) {
    final updater = widget.groupExtensionUpdater;
    if (updater != null) {
      return updater(groupId, extension);
    }
    return EMClient.getInstance.groupManager.updateGroupExtension(
      groupId,
      extension,
    );
  }

  Future<List<EMGroupSharedFile>> _fetchGroupSharedFiles(
    String groupId, {
    int pageSize = 200,
    int pageNum = 1,
  }) {
    final fetcher = widget.groupSharedFileListFetcher;
    if (fetcher != null) {
      return fetcher(groupId, pageSize: pageSize, pageNum: pageNum);
    }
    return EMClient.getInstance.groupManager.fetchGroupFileListFromServer(
      groupId,
      pageSize: pageSize,
      pageNum: pageNum,
    );
  }

  Future<void> _uploadGroupSharedFile(String groupId, String filePath) {
    final uploader = widget.groupSharedFileUploader;
    if (uploader != null) {
      return uploader(groupId, filePath);
    }
    return EMClient.getInstance.groupManager.uploadGroupSharedFile(
      groupId,
      filePath,
    );
  }

  Future<String> _defaultGroupSharedFileUploadPath() {
    final provider = widget.groupSharedFileUploadPathProvider;
    if (provider != null) {
      return provider();
    }
    return getAssetFilePath('assets/voice.mp3');
  }

  Future<void> _downloadGroupSharedFile({
    required String groupId,
    required String fileId,
    required String savePath,
  }) {
    final downloader = widget.groupSharedFileDownloader;
    if (downloader != null) {
      return downloader(groupId: groupId, fileId: fileId, savePath: savePath);
    }
    return EMClient.getInstance.groupManager.downloadGroupSharedFile(
      groupId: groupId,
      fileId: fileId,
      savePath: savePath,
    );
  }

  Future<void> _removeGroupSharedFile(String groupId, String fileId) {
    final remover = widget.groupSharedFileRemover;
    if (remover != null) {
      return remover(groupId, fileId);
    }
    return EMClient.getInstance.groupManager.removeGroupSharedFile(
      groupId,
      fileId,
    );
  }

  EMGroupSharedFile? _firstAvailableSharedFile() {
    for (final file in _sharedFiles) {
      final fileId = file.fileId;
      if (fileId != null && fileId.isNotEmpty) {
        return file;
      }
    }
    return null;
  }

  Future<EMCursorResult<GroupMemberInfo>> _fetchGroupMembersInfo({
    required String groupId,
    String? cursor,
    int limit = 20,
  }) {
    final fetcher = widget.groupMembersInfoFetcher;
    if (fetcher != null) {
      return fetcher(groupId: groupId, cursor: cursor, limit: limit);
    }
    return EMClient.getInstance.groupManager.fetchGroupMembersInfo(
      groupId: groupId,
      cursor: cursor,
      limit: limit,
    );
  }

  Future<EMCursorResult<String>> _loadGroupMembersPage(
    String groupId, {
    String cursor = '',
    int pageSize = 50,
  }) {
    final loader = widget.groupMembersLoader;
    if (loader != null) {
      return loader(groupId, cursor: cursor, pageSize: pageSize);
    }
    return EMClient.getInstance.groupManager.fetchMemberListFromServer(
      groupId,
      pageSize: pageSize,
      cursor: cursor,
    );
  }

  Future<void> _setGroupMemberNameCard({
    required String groupId,
    required String userId,
    required String nameCard,
  }) {
    final setter = widget.groupMemberNameCardSetter;
    if (setter != null) {
      return setter(groupId: groupId, userId: userId, nameCard: nameCard);
    }
    return EMClient.getInstance.groupManager.setMemberAttributes(
      groupId: groupId,
      userId: userId,
      attributes: {'namecard': nameCard},
    );
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
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _receiverListController,
                style: TextStyle(
                  color: AppColors.textPrimary(isDark),
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: '定向接收人，英文逗号分隔，最多 20 个',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary(isDark),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: AppColors.inputBackground(isDark),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.glassBorder(isDark),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.glassBorder(isDark),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary(isDark)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _groupId.isEmpty ? null : _pickTargetedReceivers,
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
      actionsBuilder: (entry) => [
        LogViewActions.copyEntry(),
        if (entry.attachment is EMMessage &&
            (entry.attachment as EMMessage).chatType == ChatType.GroupChat) ...[
          LogAction(
            id: 'forward',
            title: '转发',
            icon: Icons.forward_outlined,
            onSelected: (entry) async {
              return _forwardMessage(entry.attachment as EMMessage);
            },
          ),
          LogAction(
            id: 'create_thread',
            title: '创建子区',
            icon: Icons.forum_outlined,
            isVisible: (entry) {
              final message = entry.attachment;
              return message is EMMessage &&
                  _groupId.isNotEmpty &&
                  message.msgId.isNotEmpty;
            },
            onSelected: (entry) async {
              final message = entry.attachment as EMMessage;
              _showBottomSheet(
                ChatThreadPage(
                  parentGroupId: _groupId,
                  parentMessageId: message.msgId,
                  showAppBar: false,
                ),
              );
              return null;
            },
          ),
          LogAction(
            id: 'send_group_ack',
            title: '发送群回执',
            icon: Icons.done_all_outlined,
            isVisible: (entry) {
              final message = entry.attachment;
              return message is EMMessage &&
                  message.direction == MessageDirection.RECEIVE;
            },
            onSelected: (entry) async {
              await _sendGroupMessageReadAck(entry.attachment as EMMessage);
              return null;
            },
          ),
          LogAction(
            id: 'fetch_group_acks',
            title: '回执详情',
            icon: Icons.receipt_long_outlined,
            onSelected: (entry) async {
              await _fetchGroupMessageAcks(entry.attachment as EMMessage);
              return null;
            },
          ),
        ],
      ],
    );
  }

  Future<LogActionResult?> _forwardMessage(EMMessage message) async {
    final result = await showInputDialog(
      context: context,
      title: '转发消息',
      fields: [
        InputFieldData(
          title: '目标 ID',
          placeholder: '用户 / 群组 / 聊天室 ID',
          text: '',
        ),
        InputFieldData(
          title: '类型',
          placeholder: forwardChatTypeHint(),
          text: 'group',
        ),
      ],
    );
    if (result == null || result.length < 2) {
      return null;
    }
    try {
      final forwarded = createForwardMessage(
        source: message,
        targetId: result[0].text,
        chatType: parseForwardChatType(result[1].text),
      );
      await (widget.messageSender ??
              EMClient.getInstance.chatManager.sendMessage)
          .call(forwarded);
      addSendLog(
        '转发消息: ${forwarded.toJson()}',
        attachment: forwarded,
        tag: 'message',
      );
      return const LogActionResult(
        overlayLabel: '已转发',
        overlayStyle: LogOverlayStyle.success,
      );
    } catch (e) {
      return LogActionResult(
        overlayLabel: '转发失败: $e',
        overlayStyle: LogOverlayStyle.error,
      );
    }
  }

  Future<void> _sendCombineForwardMessage({
    required String defaultTargetId,
    required ChatType defaultChatType,
  }) async {
    final localMessageIds = successfulLocalMessageIdsForCombineForward(
      entries: logController.entities,
      chatType: ChatType.GroupChat,
      conversationId: _groupId,
    );
    final result = await showInputDialog(
      context: context,
      title: '合并转发',
      fields: [
        InputFieldData(
          title: '目标 ID',
          placeholder: '用户 / 群组 / 聊天室 ID',
          text: defaultTargetId,
        ),
        InputFieldData(
          title: '类型',
          placeholder: forwardChatTypeHint(),
          text: defaultChatType == ChatType.GroupChat
              ? 'group'
              : defaultChatType == ChatType.ChatRoom
              ? 'room'
              : 'chat',
        ),
        InputFieldData(
          title: '消息 ID 列表',
          placeholder: '本地存在且发送成功的 msgId，多个用逗号或换行分隔',
          text: localMessageIds.join('\n'),
          multiline: true,
        ),
        InputFieldData(title: '标题', placeholder: '合并消息标题', text: '聊天记录'),
        InputFieldData(
          title: '摘要',
          placeholder: '合并消息摘要',
          text: '',
          multiline: true,
        ),
        InputFieldData(
          title: '兼容文本',
          placeholder: '旧版本不支持合并消息时展示',
          text: '当前版本不支持合并消息',
        ),
      ],
    );
    if (result == null || result.length < 6) {
      return;
    }
    try {
      final message = createCombineForwardMessage(
        targetId: result[0].text,
        chatType: parseForwardChatType(result[1].text),
        msgIds: parseForwardMessageIds(result[2].text),
        title: result[3].text,
        summary: result[4].text,
        compatibleText: result[5].text,
      );
      await sendMessage(message);
      addSendLog(
        '合并转发消息: ${message.toJson()}',
        attachment: message,
        tag: 'message',
      );
    } catch (e) {
      addSendLog('合并转发失败: $e');
    }
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
      final receiverList = parseGroupReceiverList(_receiverListController.text);
      if (receiverList != null && receiverList.length > 20) {
        addSendLog('定向消息接收人最多 20 个');
        return;
      }
      msg.deliverOnlineOnly = _deliverOnlineOnly;
      msg.needGroupAck = true;
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
      await (widget.messageSender ??
              EMClient.getInstance.chatManager.sendMessage)
          .call(msg);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _pickTargetedReceivers() async {
    if (_groupId.isEmpty) return;
    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GroupReceiverPicker(
        groupId: _groupId,
        initialSelectedMembers:
            parseGroupReceiverList(_receiverListController.text) ??
            const <String>[],
        membersLoader: _loadGroupMembersPage,
        isDark: _settings.isDarkMode,
      ),
    );
    if (selected == null) return;
    setState(() {
      _receiverListController.text = selected.join(', ');
    });
  }

  Future<void> _sendGroupMessageReadAck(EMMessage message) async {
    final msgId = message.msgId;
    final groupId = message.conversationId ?? _groupId;
    if (msgId.isEmpty || groupId.isEmpty) {
      addSendLog('发送群消息已读回执失败: 缺少 msgId 或 groupId');
      return;
    }
    try {
      await (widget.groupMessageReadAckSender ??
              EMClient.getInstance.chatManager.sendGroupMessageReadAck)
          .call(msgId, groupId, content: 'qa_group_read_ack');
      addSendLog('发送群消息已读回执成功: msgId=$msgId');
    } catch (e) {
      addAppErrLog('发送群消息已读回执失败: $e');
    }
  }

  Future<void> _fetchGroupMessageAcks(EMMessage message) async {
    final msgId = message.msgId;
    final groupId = message.conversationId ?? _groupId;
    if (msgId.isEmpty || groupId.isEmpty) {
      addSendLog('查询群消息回执详情失败: 缺少 msgId 或 groupId');
      return;
    }
    try {
      final result =
          await (widget.groupAcksFetcher ??
                  EMClient.getInstance.chatManager.fetchGroupAcks)
              .call(msgId, groupId, pageSize: 20);
      if (result.data.isEmpty) {
        addReceiveLog('群消息回执详情为空: msgId=$msgId');
        return;
      }
      for (final ack in result.data) {
        addReceiveLog(
          '群消息回执详情: msgId=${ack.messageId}, from=${ack.from}, count=${ack.readCount}, content=${ack.content}',
        );
      }
    } catch (e) {
      addAppErrLog('查询群消息回执详情失败: $e');
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

  Future<void> _showOldGroupInfoDialog({required bool isName}) async {
    if (_groupId.isEmpty) {
      addSendLog('请先加入群组');
      return;
    }
    final result = await showInputDialog(
      context: context,
      title: isName ? '修改群组名称(old)' : '修改群组描述(old)',
      fields: [
        InputFieldData(
          title: isName ? '群组名称(old)' : '群组描述(old)',
          placeholder: isName ? '请输入群组名称' : '请输入群组描述',
          text: '',
          multiline: !isName,
        ),
      ],
    );
    if (result == null) return;
    final value = result[0].text.trim();
    if (value.isEmpty) {
      addSendLog(
        isName
            ? 'old changeGroupName 失败: 名称不能为空'
            : 'old changeGroupDescription 失败: 描述不能为空',
      );
      return;
    }
    try {
      if (isName) {
        await _changeGroupNameOld(_groupId, value);
        addSendLog('old changeGroupName 成功: $value');
      } else {
        await _changeGroupDescriptionOld(_groupId, value);
        addSendLog('old changeGroupDescription 成功: $value');
      }
    } catch (e) {
      addAppErrLog(
        isName
            ? 'old changeGroupName 失败: $e'
            : 'old changeGroupDescription 失败: $e',
      );
    }
  }

  Future<void> _fetchAnnouncementFromServer() async {
    if (_groupId.isEmpty) {
      addSendLog('请先加入群组');
      return;
    }
    try {
      final announcement = await _fetchGroupAnnouncement(_groupId);
      addReceiveLog(
        announcement == null || announcement.isEmpty
            ? '群公告为空'
            : '群公告: $announcement',
      );
    } catch (e) {
      addAppErrLog('获取群公告失败: $e');
    }
  }

  Future<void> _fetchPublicGroupsFromServer() async {
    try {
      final result = await _fetchPublicGroups(pageSize: 20);
      if (result.data.isEmpty) {
        addReceiveLog('公开群列表为空');
        return;
      }
      for (final group in result.data) {
        addReceiveLog(
          '公开群: groupId=${group.groupId}, name=${group.name}, cursor=${result.cursor ?? ''}',
          attachment: group,
        );
      }
    } catch (e) {
      addAppErrLog('获取公开群列表失败: $e');
    }
  }

  Future<void> _showOldGroupInviteDialog() async {
    if (_groupId.isEmpty) {
      addSendLog('请先加入群组');
      return;
    }
    final result = await showInputDialog(
      context: context,
      title: '邀请成员入群(old)',
      fields: [
        InputFieldData(
          title: '成员 ID 列表',
          placeholder: '多个成员 ID 用逗号、空格或换行分隔',
          text: '',
          multiline: true,
        ),
        InputFieldData(title: '邀请原因', placeholder: '可选', text: ''),
      ],
    );
    if (result == null) return;
    final members = parseGroupReceiverList(result[0].text);
    if (members == null) {
      addSendLog('old inviterUser 失败: 成员 ID 不能为空');
      return;
    }
    final reason = result[1].text.trim();
    try {
      await _inviteGroupMembersOld(
        _groupId,
        members,
        reason: reason.isEmpty ? null : reason,
      );
      addSendLog('old inviterUser 成功: members=${members.join(',')}');
    } catch (e) {
      addAppErrLog('old inviterUser 失败: $e');
    }
  }

  Future<void> _queryAllowListMembership() async {
    if (_groupId.isEmpty) {
      addSendLog('请先加入群组');
      return;
    }
    try {
      final inAllowList = await _isMemberInAllowListFromServer(_groupId);
      addReceiveLog('当前用户在群白名单中: $inAllowList');
    } catch (e) {
      addAppErrLog('查询当前用户群白名单状态失败: $e');
    }
  }

  Future<void> _queryMuteListMembership() async {
    if (_groupId.isEmpty) {
      addSendLog('请先加入群组');
      return;
    }
    try {
      final inMuteList = await _isMemberInGroupMuteList(_groupId);
      addReceiveLog('当前用户在群禁言列表中: $inMuteList');
    } catch (e) {
      addAppErrLog('查询当前用户群禁言状态失败: $e');
    }
  }

  Future<void> _showGroupAvatarDialog() async {
    if (_groupId.isEmpty) {
      addSendLog('请先加入群组');
      return;
    }
    final result = await showInputDialog(
      context: context,
      title: '修改群头像',
      fields: [
        InputFieldData(
          title: '群头像 URL',
          placeholder: '请输入服务端可访问的头像 URL',
          text: '',
        ),
      ],
    );
    if (result == null) return;
    final avatarUrl = result[0].text.trim();
    if (avatarUrl.isEmpty) {
      addSendLog('修改群头像失败: 头像 URL 不能为空');
      return;
    }
    try {
      final group = await _updateGroupAvatar(_groupId, avatarUrl);
      addSendLog('修改群头像成功: ${group.toJson()}');
    } catch (e) {
      addAppErrLog('修改群头像失败: $e');
    }
  }

  Future<void> _showGroupExtensionDialog() async {
    if (_groupId.isEmpty) {
      addSendLog('请先加入群组');
      return;
    }
    final result = await showInputDialog(
      context: context,
      title: '更新群扩展',
      fields: [
        InputFieldData(
          title: '群扩展字段',
          placeholder: '请输入群扩展字符串',
          text: '',
          multiline: true,
        ),
      ],
    );
    if (result == null) return;
    final extension = result[0].text;
    if (extension.trim().isEmpty) {
      addSendLog('更新群扩展失败: 群扩展字段不能为空');
      return;
    }
    try {
      await _updateGroupExtension(_groupId, extension);
      addSendLog('更新群扩展成功: $extension');
    } catch (e) {
      addAppErrLog('更新群扩展失败: $e');
    }
  }

  Future<void> _fetchSharedFilesFromServer() async {
    if (_groupId.isEmpty) {
      addSendLog('请先加入群组');
      return;
    }
    try {
      final files = await _fetchGroupSharedFiles(_groupId);
      _sharedFiles
        ..clear()
        ..addAll(files);
      if (files.isEmpty) {
        addReceiveLog('群共享文件列表为空');
        return;
      }
      for (final file in files) {
        addReceiveLog(
          '群共享文件: fileId=${file.fileId}, name=${file.fileName}, owner=${file.fileOwner}, size=${file.fileSize}, createTime=${file.createTime}',
          attachment: file,
        );
      }
    } catch (e) {
      addAppErrLog('获取群共享文件列表失败: $e');
    }
  }

  Future<void> _showUploadSharedFileDialog() async {
    if (_groupId.isEmpty) {
      addSendLog('请先加入群组');
      return;
    }
    String defaultPath;
    try {
      defaultPath = await _defaultGroupSharedFileUploadPath();
    } catch (e) {
      addAppErrLog('准备群共享文件路径失败: $e');
      return;
    }
    if (!mounted) return;
    final result = await showInputDialog(
      context: context,
      title: '上传群共享文件',
      fields: [
        InputFieldData(
          title: '本地文件路径',
          placeholder: '请输入要上传的本地文件路径',
          text: defaultPath,
        ),
      ],
    );
    if (result == null) return;
    final filePath = result[0].text.trim();
    if (filePath.isEmpty) {
      addSendLog('上传群共享文件失败: 文件路径不能为空');
      return;
    }
    try {
      await _uploadGroupSharedFile(_groupId, filePath);
      addSendLog('上传群共享文件成功: $filePath');
    } catch (e) {
      addAppErrLog('上传群共享文件失败: $e');
    }
  }

  Future<void> _showDownloadSharedFileDialog() async {
    if (_groupId.isEmpty) {
      addSendLog('请先加入群组');
      return;
    }
    final defaultFile = _firstAvailableSharedFile();
    final defaultFileId = defaultFile?.fileId ?? '';
    final defaultFileName = defaultFile?.fileName?.trim() ?? '';
    final defaultSavePath = defaultFileName.isEmpty
        ? ''
        : '/tmp/$defaultFileName';
    final result = await showInputDialog(
      context: context,
      title: '下载群共享文件',
      fields: [
        InputFieldData(
          title: '共享文件 ID',
          placeholder: '请输入 fileId',
          text: defaultFileId,
        ),
        InputFieldData(
          title: '保存路径',
          placeholder: '请输入本地保存路径',
          text: defaultSavePath,
        ),
      ],
    );
    if (result == null) return;
    final fileId = result[0].text.trim();
    final savePath = result[1].text.trim();
    if (fileId.isEmpty || savePath.isEmpty) {
      addSendLog('下载群共享文件失败: fileId 和保存路径不能为空');
      return;
    }
    try {
      await _downloadGroupSharedFile(
        groupId: _groupId,
        fileId: fileId,
        savePath: savePath,
      );
      addSendLog('下载群共享文件成功: fileId=$fileId, savePath=$savePath');
    } catch (e) {
      addAppErrLog('下载群共享文件失败: $e');
    }
  }

  Future<void> _showRemoveSharedFileDialog() async {
    if (_groupId.isEmpty) {
      addSendLog('请先加入群组');
      return;
    }
    final defaultFileId = _firstAvailableSharedFile()?.fileId ?? '';
    final result = await showInputDialog(
      context: context,
      title: '删除群共享文件',
      fields: [
        InputFieldData(
          title: '共享文件 ID',
          placeholder: '请输入 fileId',
          text: defaultFileId,
        ),
      ],
    );
    if (result == null) return;
    final fileId = result[0].text.trim();
    if (fileId.isEmpty) {
      addSendLog('删除群共享文件失败: fileId 不能为空');
      return;
    }
    try {
      await _removeGroupSharedFile(_groupId, fileId);
      addSendLog('删除群共享文件成功: fileId=$fileId');
    } catch (e) {
      addAppErrLog('删除群共享文件失败: $e');
    }
  }

  Future<void> _showGroupMemberNameCardDialog() async {
    if (_groupId.isEmpty) {
      addSendLog('请先加入群组');
      return;
    }
    final result = await showInputDialog(
      context: context,
      title: '群成员名片',
      fields: [
        InputFieldData(title: '成员 ID', placeholder: '请输入成员用户 ID', text: ''),
        InputFieldData(title: '名片', placeholder: '请输入 namecard 属性值', text: ''),
      ],
    );
    if (result == null) return;
    final userId = result[0].text.trim();
    final nameCard = result[1].text.trim();
    if (userId.isEmpty) {
      addSendLog('群成员名片失败: 成员 ID 不能为空');
      return;
    }
    try {
      final membersInfo = await _fetchGroupMembersInfo(
        groupId: _groupId,
        limit: 20,
      );
      final matched = membersInfo.data.where((info) => info.userId == userId);
      if (matched.isEmpty) {
        addReceiveLog('群成员信息为空: userId=$userId');
      } else {
        for (final info in matched) {
          addReceiveLog(
            '群成员信息: userId=${info.userId}, joinedTs=${info.joinedTs}, role=${info.role}',
          );
        }
      }
      if (nameCard.isEmpty) {
        addSendLog('设置群成员名片跳过: 名片为空');
        return;
      }
      await _setGroupMemberNameCard(
        groupId: _groupId,
        userId: userId,
        nameCard: nameCard,
      );
      addSendLog('设置群成员名片成功: userId=$userId, namecard=$nameCard');
    } catch (e) {
      addAppErrLog('群成员名片失败: $e');
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
            await _muteAllGroupMembers(_groupId);
          } else {
            await _unmuteAllGroupMembers(_groupId);
          }
          addLog(value ? '开启群组全部禁言成功: $_groupId' : '关闭群组全部禁言成功: $_groupId');
          return true;
        } catch (e) {
          addAppErrLog(value ? '开启群组全部禁言失败: $e' : '关闭群组全部禁言失败: $e');
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
      buildItem(
        Icons.terminal_outlined,
        '命令',
        () async => createGroupCommandMessage(_groupId),
      ),
      GridActionItem(
        icon: Icons.merge_type_outlined,
        label: '合并转发',
        onTap: () => _sendCombineForwardMessage(
          defaultTargetId: _groupId,
          defaultChatType: ChatType.GroupChat,
        ),
      ),
    ];
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: GridActionMenu(items: items, isDark: isDark, columns: 7),
    );
  }

  Widget _buildGroupManagementButtons(bool isDark) {
    final canDestroyGroup =
        _groupId.isNotEmpty && _permissionType == EMGroupPermissionType.Owner;
    final canToggleMessageBlock =
        _groupId.isNotEmpty && _permissionType == EMGroupPermissionType.Member;
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
        icon: Icons.public_outlined,
        label: '公开群',
        onTap: _fetchPublicGroupsFromServer,
      ),
      GridActionItem(
        icon: Icons.drive_file_rename_outline,
        label: '名称',
        onTap: () => _showGroupInfoDialog(GroupInfoEditType.name),
      ),
      GridActionItem(
        icon: Icons.edit_note_outlined,
        label: '旧名称',
        onTap: () => _showOldGroupInfoDialog(isName: true),
      ),
      GridActionItem(
        icon: Icons.subject,
        label: '描述',
        onTap: () => _showGroupInfoDialog(GroupInfoEditType.description),
      ),
      GridActionItem(
        icon: Icons.notes_outlined,
        label: '旧描述',
        onTap: () => _showOldGroupInfoDialog(isName: false),
      ),
      GridActionItem(
        icon: Icons.person_add_alt_1_outlined,
        label: '旧邀请',
        onTap: _showOldGroupInviteDialog,
      ),
      GridActionItem(
        icon: Icons.image_outlined,
        label: '头像',
        onTap: _showGroupAvatarDialog,
      ),
      GridActionItem(
        icon: Icons.campaign_outlined,
        label: '公告',
        onTap: () => _showGroupInfoDialog(GroupInfoEditType.announcement),
      ),
      GridActionItem(
        icon: Icons.article_outlined,
        label: '取公告',
        onTap: _fetchAnnouncementFromServer,
      ),
      GridActionItem(
        icon: Icons.extension_outlined,
        label: '群扩展',
        onTap: _showGroupExtensionDialog,
      ),
      GridActionItem(
        icon: Icons.folder_copy_outlined,
        label: '文件列表',
        onTap: _fetchSharedFilesFromServer,
      ),
      GridActionItem(
        icon: Icons.upload_file_outlined,
        label: '上传文件',
        onTap: _showUploadSharedFileDialog,
      ),
      GridActionItem(
        icon: Icons.download_outlined,
        label: '下载文件',
        onTap: _showDownloadSharedFileDialog,
      ),
      GridActionItem(
        icon: Icons.delete_sweep_outlined,
        label: '删文件',
        onTap: _showRemoveSharedFileDialog,
      ),
      GridActionItem(
        icon: Icons.group_outlined,
        label: '成员',
        onTap: () => _showBottomSheet(GroupMembersPage(groupId: _groupId)),
      ),
      GridActionItem(
        icon: Icons.badge_outlined,
        label: '成员名片',
        onTap: _showGroupMemberNameCardDialog,
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
        icon: Icons.fact_check_outlined,
        label: '查白名单',
        onTap: _queryAllowListMembership,
      ),
      GridActionItem(
        icon: Icons.mic_off_outlined,
        label: '禁言列表',
        onTap: () => _showBottomSheet(GroupMuteListPage(groupId: _groupId)),
      ),
      GridActionItem(
        icon: Icons.record_voice_over_outlined,
        label: '查禁言',
        onTap: _queryMuteListMembership,
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

class _GroupReceiverPicker extends StatefulWidget {
  const _GroupReceiverPicker({
    required this.groupId,
    required this.initialSelectedMembers,
    required this.membersLoader,
    required this.isDark,
  });

  final String groupId;
  final List<String> initialSelectedMembers;
  final GroupMembersLoader membersLoader;
  final bool isDark;

  @override
  State<_GroupReceiverPicker> createState() => _GroupReceiverPickerState();
}

class _GroupReceiverPickerState extends State<_GroupReceiverPicker> {
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
        widget.groupId,
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
        widget.groupId,
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
