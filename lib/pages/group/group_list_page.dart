import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/pages/group/group_invitation_store.dart';
import 'package:qa_flutter/pages/group/group_page.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_settings.dart';
import '../../common/widgets/common_gradient_background.dart';

/// 群组列表页面
class GroupListPage extends StatefulWidget {
  final Function(String groupId)? onItemTap;
  const GroupListPage({super.key, this.onItemTap});

  @override
  State<GroupListPage> createState() => _GroupListPageState();
}

class _GroupListPageState extends State<GroupListPage> {
  final _settings = AppSettings();
  final ScrollController _scrollController = ScrollController();
  final GroupInvitationStore _invitationStore = GroupInvitationStore.instance;
  List<EMGroup> _groups = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _pageNum = 0; // 群组分页从 0 开始
  int? _joinedGroupCount;
  bool _isFetchingJoinedGroupCount = false;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _fetchGroups();
    _scrollController.addListener(_scrollListener);
    _invitationStore.addListener(_onInvitationsChanged);

    EMClient.getInstance.groupManager.addEventHandler(
      'group_list',
      EMGroupEventHandler(
        onInvitationReceivedFromGroup: (groupId, groupName, inviter, reason) {
          if (!mounted) {
            return;
          }
          _invitationStore.record(
            GroupInvitation(
              groupId: groupId,
              groupName: groupName,
              inviter: inviter,
              reason: reason,
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('收到群组邀请: ${groupName ?? groupId}')),
          );
        },
        onRequestToJoinReceivedFromGroup:
            (groupId, groupName, applicant, reason) {
              if (!mounted) {
                return;
              }
              _invitationStore.recordJoinRequest(
                GroupJoinRequest(
                  groupId: groupId,
                  groupName: groupName,
                  applicant: applicant,
                  reason: reason,
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('收到入群申请: ${groupName ?? groupId}')),
              );
            },
        onAutoAcceptInvitationFromGroup: (groupId, inviter, inviteMessage) {
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('已自动接受 $inviter 的群组邀请')));
          _fetchGroups();
        },
        onInvitationAcceptedFromGroup: (groupId, invitee, reason) {
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$invitee 已接受群组邀请')));
        },
        onInvitationDeclinedFromGroup: (groupId, invitee, reason) {
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$invitee 已拒绝群组邀请')));
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _invitationStore.removeListener(_onInvitationsChanged);
    EMClient.getInstance.groupManager.removeEventHandler('group_list');
    super.dispose();
  }

  void _onInvitationsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _acceptInvitation(GroupInvitation invitation) async {
    try {
      await EMClient.getInstance.groupManager.acceptInvitation(
        invitation.groupId,
        invitation.inviter,
      );
      if (mounted) {
        _invitationStore.remove(invitation.groupId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已同意加入 ${invitation.displayName}')),
        );
        _fetchGroups();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('同意群组邀请失败: $e')));
      }
    }
  }

  Future<void> _declineInvitation(GroupInvitation invitation) async {
    try {
      await EMClient.getInstance.groupManager.declineInvitation(
        groupId: invitation.groupId,
        inviter: invitation.inviter,
        reason: 'declined from QA app',
      );
      if (mounted) {
        _invitationStore.remove(invitation.groupId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已拒绝加入 ${invitation.displayName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('拒绝群组邀请失败: $e')));
      }
    }
  }

  Future<void> _acceptJoinRequest(GroupJoinRequest request) async {
    try {
      await EMClient.getInstance.groupManager.acceptJoinApplication(
        request.groupId,
        request.applicant,
      );
      if (mounted) {
        _invitationStore.removeJoinRequest(request.groupId, request.applicant);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已同意 ${request.applicant} 加入 ${request.displayName}'),
          ),
        );
        _fetchGroups();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('同意入群申请失败: $e')));
      }
    }
  }

  Future<void> _declineJoinRequest(GroupJoinRequest request) async {
    try {
      await EMClient.getInstance.groupManager.declineJoinApplication(
        request.groupId,
        request.applicant,
        reason: 'declined from QA app',
      );
      if (mounted) {
        _invitationStore.removeJoinRequest(request.groupId, request.applicant);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已拒绝 ${request.applicant} 加入 ${request.displayName}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('拒绝入群申请失败: $e')));
      }
    }
  }

  /// 滚动监听，触发加载更多
  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isFetchingMore &&
        _hasMore) {
      _fetchMoreGroups();
    }
  }

  /// 获取群组列表（首次加载）
  Future<void> _fetchGroups() async {
    setState(() {
      _isLoading = true;
      _pageNum = 0;
      _hasMore = true;
    });

    try {
      final result = await EMClient.getInstance.groupManager
          .fetchJoinedGroupsFromServer(pageNum: _pageNum, pageSize: _pageSize);
      setState(() {
        _groups = result;
        _hasMore = result.length >= _pageSize;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('获取群组列表失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 加载更多群组
  Future<void> _fetchMoreGroups() async {
    if (_isFetchingMore || !_hasMore) return;

    setState(() {
      _isFetchingMore = true;
    });

    try {
      final nextP = _pageNum + 1;
      final result = await EMClient.getInstance.groupManager
          .fetchJoinedGroupsFromServer(pageNum: nextP, pageSize: _pageSize);

      setState(() {
        _groups.addAll(result);
        _pageNum = nextP;
        _hasMore = result.length >= _pageSize;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载更多失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingMore = false;
        });
      }
    }
  }

  /// 复制到剪贴板
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

  Future<void> _fetchJoinedGroupCount() async {
    setState(() {
      _isFetchingJoinedGroupCount = true;
    });

    try {
      final count = await EMClient.getInstance.groupManager
          .fetchJoinedGroupCount();
      if (mounted) {
        setState(() {
          _joinedGroupCount = count;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('查询已加入群组数量成功: $count')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('查询已加入群组数量失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingJoinedGroupCount = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final isDark = _settings.isDarkMode;
        final pendingInvitations = _invitationStore.invitations;
        final pendingJoinRequests = _invitationStore.joinRequests;
        return CommonGradientBackground(
          isDark: isDark,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(
                '群组列表',
                style: TextStyle(color: AppColors.textPrimary(isDark)),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: AppColors.textPrimary(isDark)),
              actions: [
                Tooltip(
                  message: '查询已加入群组数量',
                  child: TextButton.icon(
                    icon: _isFetchingJoinedGroupCount
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textPrimary(isDark),
                            ),
                          )
                        : Icon(
                            Icons.groups_2_outlined,
                            size: 18,
                            color: AppColors.textPrimary(isDark),
                          ),
                    label: Text(
                      '群组数量',
                      style: TextStyle(
                        color: AppColors.textPrimary(isDark),
                        fontSize: 14,
                      ),
                    ),
                    onPressed: _isFetchingJoinedGroupCount
                        ? null
                        : _fetchJoinedGroupCount,
                  ),
                ),
                TextButton(
                  child: Text(
                    'Join',
                    style: TextStyle(
                      color: AppColors.textPrimary(isDark),
                      fontSize: 14,
                    ),
                  ),
                  onPressed: () {
                    if (widget.onItemTap != null) {
                      widget.onItemTap!('');
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GroupPage(),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            body: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary(isDark),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchGroups,
                    child: _buildListContent(
                      isDark,
                      pendingInvitations,
                      pendingJoinRequests,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildListContent(
    bool isDark,
    List<GroupInvitation> pendingInvitations,
    List<GroupJoinRequest> pendingJoinRequests,
  ) {
    final showCount = _joinedGroupCount != null;
    if (pendingInvitations.isEmpty &&
        pendingJoinRequests.isEmpty &&
        _groups.isEmpty) {
      return ListView(
        children: [
          if (showCount) _buildJoinedGroupCountTile(isDark),
          SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Text(
                '暂无加入的群组',
                style: TextStyle(color: AppColors.textSecondary(isDark)),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount:
          (showCount ? 1 : 0) +
          pendingInvitations.length +
          pendingJoinRequests.length +
          _groups.length +
          (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (showCount) {
          if (index == 0) {
            return _buildJoinedGroupCountTile(isDark);
          }
          index -= 1;
        }
        if (index < pendingInvitations.length) {
          return _buildInvitationTile(pendingInvitations[index], isDark);
        }
        final requestIndex = index - pendingInvitations.length;
        if (requestIndex < pendingJoinRequests.length) {
          return _buildJoinRequestTile(
            pendingJoinRequests[requestIndex],
            isDark,
          );
        }
        final groupIndex = requestIndex - pendingJoinRequests.length;
        if (groupIndex < _groups.length) {
          final group = _groups[groupIndex];
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
                ],
              );

              if (value == 'copy_id') {
                _copyToClipboard(group.groupId);
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
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary(isDark).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.group_outlined,
                    color: AppColors.primary(isDark),
                  ),
                ),
                title: Text(
                  group.groupName ?? '未命名群组',
                  style: TextStyle(
                    color: AppColors.textPrimary(isDark),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'ID: ${group.groupId}',
                  style: TextStyle(
                    color: AppColors.textSecondary(isDark),
                    fontFamily: 'monospace',
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary(isDark),
                ),
                onTap: () {
                  if (widget.onItemTap != null) {
                    widget.onItemTap!(group.groupId);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupPage(groupId: group.groupId),
                      ),
                    );
                  }
                },
              ),
            ),
          );
        } else {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary(isDark),
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildJoinedGroupCountTile(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.inputBackground(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder(isDark)),
      ),
      child: Row(
        children: [
          Icon(Icons.numbers_outlined, color: AppColors.primary(isDark)),
          const SizedBox(width: 12),
          Text(
            '已加入群组数量: $_joinedGroupCount',
            style: TextStyle(
              color: AppColors.textPrimary(isDark),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationTile(GroupInvitation invitation, bool isDark) {
    final reason = invitation.reason?.trim();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.inputBackground(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary(isDark)),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary(isDark).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.group_add_outlined,
            color: AppColors.primary(isDark),
          ),
        ),
        title: Text(
          invitation.displayName,
          style: TextStyle(
            color: AppColors.textPrimary(isDark),
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '群组邀请',
              style: TextStyle(color: AppColors.textSecondary(isDark)),
            ),
            Text(
              '邀请人: ${invitation.inviter}',
              style: TextStyle(color: AppColors.textSecondary(isDark)),
            ),
            if (reason != null && reason.isNotEmpty)
              Text(
                '原因: $reason',
                style: TextStyle(color: AppColors.textSecondary(isDark)),
              ),
          ],
        ),
        trailing: Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: () => _declineInvitation(invitation),
              child: const Text('拒绝'),
            ),
            FilledButton(
              onPressed: () => _acceptInvitation(invitation),
              child: const Text('同意'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinRequestTile(GroupJoinRequest request, bool isDark) {
    final reason = request.reason?.trim();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.inputBackground(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary(isDark)),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary(isDark).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.how_to_reg_outlined,
            color: AppColors.primary(isDark),
          ),
        ),
        title: Text(
          request.displayName,
          style: TextStyle(
            color: AppColors.textPrimary(isDark),
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '入群申请',
              style: TextStyle(color: AppColors.textSecondary(isDark)),
            ),
            Text(
              '申请人: ${request.applicant}',
              style: TextStyle(color: AppColors.textSecondary(isDark)),
            ),
            if (reason != null && reason.isNotEmpty)
              Text(
                '原因: $reason',
                style: TextStyle(color: AppColors.textSecondary(isDark)),
              ),
          ],
        ),
        trailing: Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: () => _declineJoinRequest(request),
              child: const Text('拒绝'),
            ),
            FilledButton(
              onPressed: () => _acceptJoinRequest(request),
              child: const Text('同意'),
            ),
          ],
        ),
      ),
    );
  }
}
