import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/pages/single/contact_api.dart';
import 'package:qa_flutter/pages/single/single_chat_page.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_settings.dart';
import '../../common/widgets/common_gradient_background.dart';

/// 好友列表页面
class SingleChatListPage extends StatefulWidget {
  final Function(String userId)? onItemTap;
  final Future<List<EMContact>> Function()? loadContacts;
  final Future<void> Function(String userId)? addUserToBlockList;
  final Future<List<String>> Function()? fetchAllContactIds;
  final Future<EMCursorResult<EMContact>> Function({
    String? cursor,
    int pageSize,
  })?
  fetchPagedContacts;
  final Future<List<String>> Function()? fetchAllContactsFromServerOld;
  final Future<List<String>> Function()? fetchBlockListFromServerOld;

  const SingleChatListPage({
    super.key,
    this.onItemTap,
    this.loadContacts,
    this.addUserToBlockList,
    this.fetchAllContactIds,
    this.fetchPagedContacts,
    this.fetchAllContactsFromServerOld,
    this.fetchBlockListFromServerOld,
  });

  @override
  State<SingleChatListPage> createState() => _SingleChatListPageState();
}

class _SingleChatListPageState extends State<SingleChatListPage> {
  final _settings = AppSettings();
  final ScrollController _scrollController = ScrollController();
  List<EMContact> _contacts = [];
  final List<String> _serverToolLogs = [];
  final List<_ContactInvitation> _pendingInvitations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
    EMClient.getInstance.contactManager.addEventHandler(
      'single_chat_list_page',
      EMContactEventHandler(
        onContactAdded: (username) {
          _fetchContacts();
        },
        onContactDeleted: (username) {
          _fetchContacts();
        },
        onContactInvited: (username, reason) {
          if (!mounted) {
            return;
          }
          setState(() {
            _pendingInvitations.removeWhere(
              (invitation) => invitation.userId == username,
            );
            _pendingInvitations.insert(
              0,
              _ContactInvitation(userId: username, reason: reason),
            );
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('收到好友申请: $username')));
        },
        onFriendRequestAccepted: (username) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('$username 已接受好友申请')));
            _fetchContacts();
          }
        },
        onFriendRequestDeclined: (username) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('$username 已拒绝好友申请')));
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _acceptInvitation(String username) async {
    try {
      await EMClient.getInstance.contactManager.acceptInvitation(username);
      if (mounted) {
        setState(() {
          _pendingInvitations.removeWhere(
            (invitation) => invitation.userId == username,
          );
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已同意 $username 的好友申请')));
        _fetchContacts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('同意好友申请失败: $e')));
      }
    }
  }

  Future<void> _declineInvitation(String username) async {
    try {
      await EMClient.getInstance.contactManager.declineInvitation(username);
      if (mounted) {
        setState(() {
          _pendingInvitations.removeWhere(
            (invitation) => invitation.userId == username,
          );
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已拒绝 $username 的好友申请')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('拒绝好友申请失败: $e')));
      }
    }
  }

  /// 获取好友列表
  Future<void> _fetchContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await (widget.loadContacts ?? fetchContactsFromSdk).call();
      setState(() {
        _contacts = result;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('获取好友列表失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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

  /// 添加好友
  Future<void> _addFriend() async {
    final isDark = _settings.isDarkMode;
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        title: Text(
          '添加好友',
          style: TextStyle(
            color: AppColors.textPrimary(isDark),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: AppColors.textPrimary(isDark)),
          decoration: InputDecoration(
            hintText: '请输入好友 ID',
            hintStyle: TextStyle(color: AppColors.textSecondary(isDark)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.glassBorder(isDark)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary(isDark)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: TextStyle(color: AppColors.textSecondary(isDark)),
            ),
          ),
          TextButton(
            onPressed: () {
              final input = controller.text.trim();
              if (input.isNotEmpty) {
                Navigator.pop(context, input);
              }
            },
            child: Text(
              '确定',
              style: TextStyle(color: AppColors.primary(isDark)),
            ),
          ),
        ],
      ),
    );

    // 处理输入结果
    if (result != null && result.isNotEmpty) {
      try {
        await EMClient.getInstance.contactManager.addContact(result);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('已发送好友申请至 $result')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('添加好友失败: ${e.toString()}')));
        }
      }
    }
  }

  Future<void> _deleteContact(String username) async {
    try {
      await EMClient.getInstance.contactManager.deleteContact(username);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已删除好友')));
        _fetchContacts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('删除好友失败: ${e.toString()}')));
      }
    }
  }

  Future<void> _addToBlackList(String username) async {
    try {
      await (widget.addUserToBlockList ?? addUserToBlockListFromSdk).call(
        username,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$username 已加入黑名单')));
        _fetchContacts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加入黑名单失败: ${e.toString()}')));
      }
    }
  }

  Future<void> _fetchServerContactTools() async {
    try {
      final contactIds =
          await (widget.fetchAllContactIds ??
                  EMClient.getInstance.contactManager.fetchAllContactIds)
              .call();
      if (!mounted) return;
      _appendServerToolLog(
        contactIds.isEmpty
            ? '服务端联系人ID为空'
            : '服务端联系人ID: ${contactIds.join(', ')}',
      );

      final pagedContacts =
          await (widget.fetchPagedContacts ??
                  EMClient.getInstance.contactManager.fetchContacts)
              .call(pageSize: 20);
      if (!mounted) return;
      _appendServerToolLog(
        pagedContacts.data.isEmpty
            ? '分页联系人为空'
            : '分页联系人: ${_formatContactSummary(pagedContacts.data)}',
      );

      final oldContactIds =
          await (widget.fetchAllContactsFromServerOld ??
                  () {
                    return EMClient.getInstance.contactManager
                        // ignore: deprecated_member_use
                        .getAllContactsFromServer();
                  })
              .call();
      if (!mounted) return;
      _appendServerToolLog(
        oldContactIds.isEmpty
            ? 'old联系人为空'
            : 'old联系人: ${oldContactIds.join(', ')}',
      );

      final oldBlockIds =
          await (widget.fetchBlockListFromServerOld ??
                  () {
                    return EMClient.getInstance.contactManager
                        // ignore: deprecated_member_use
                        .getBlockListFromServer();
                  })
              .call();
      if (!mounted) return;
      _appendServerToolLog(
        oldBlockIds.isEmpty ? 'old黑名单为空' : 'old黑名单: ${oldBlockIds.join(', ')}',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('服务端联系人工具失败: $e');
    }
  }

  String _formatContactSummary(List<EMContact> contacts) {
    return contacts
        .map((contact) {
          final remark = contact.remark.trim();
          return remark.isEmpty ? contact.userId : '${contact.userId}($remark)';
        })
        .join(', ');
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _appendServerToolLog(String text) {
    setState(() {
      _serverToolLogs.insert(0, text);
      if (_serverToolLogs.length > 8) {
        _serverToolLogs.removeLast();
      }
    });
    _showSnackBar(text);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final isDark = _settings.isDarkMode;
        return CommonGradientBackground(
          isDark: isDark,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(
                '好友列表',
                style: TextStyle(color: AppColors.textPrimary(isDark)),
              ),
              centerTitle: true,
              actions: [
                IconButton(onPressed: _addFriend, icon: const Icon(Icons.add)),
                TextButton(
                  onPressed: _fetchServerContactTools,
                  child: Text(
                    '服务端',
                    style: TextStyle(
                      color: AppColors.textPrimary(isDark),
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton(
                  child: Text(
                    '单聊',
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
                          builder: (context) => const SingleChatPage(),
                        ),
                      );
                    }
                  },
                ),
              ],
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: AppColors.textPrimary(isDark)),
            ),
            body: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary(isDark),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchContacts,
                    child: _contacts.isEmpty && _pendingInvitations.isEmpty
                        ? ListView(
                            children: [
                              ..._buildServerToolLogTiles(isDark),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height - 200,
                                child: Center(
                                  child: Text(
                                    '暂无好友',
                                    style: TextStyle(
                                      color: AppColors.textSecondary(isDark),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount:
                                _serverToolLogs.length +
                                _pendingInvitations.length +
                                _contacts.length,
                            itemBuilder: (context, index) {
                              if (index < _serverToolLogs.length) {
                                return _buildServerToolLogTile(
                                  _serverToolLogs[index],
                                  isDark,
                                );
                              }
                              index -= _serverToolLogs.length;
                              if (index < _pendingInvitations.length) {
                                final invitation = _pendingInvitations[index];
                                return _buildInvitationTile(invitation, isDark);
                              }
                              final contactIndex =
                                  index - _pendingInvitations.length;
                              final contact = _contacts[contactIndex];
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
                                      const PopupMenuItem(
                                        value: 'copy_id',
                                        child: Text('复制 ID'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'add_to_blacklist',
                                        child: Text('加入黑名单'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('删除'),
                                      ),
                                    ],
                                  );

                                  if (value == 'copy_id') {
                                    _copyToClipboard(contact.userId);
                                  } else if (value == 'add_to_blacklist') {
                                    _addToBlackList(contact.userId);
                                  } else if (value == 'delete') {
                                    _deleteContact(contact.userId);
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.inputBackground(isDark),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.glassBorder(isDark),
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary(
                                          isDark,
                                        ).withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.person_outline,
                                        color: AppColors.primary(isDark),
                                      ),
                                    ),
                                    title: Text(
                                      contact.userId,
                                      style: TextStyle(
                                        color: AppColors.textPrimary(isDark),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'ID: ${contact.userId}',
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
                                        widget.onItemTap!(contact.userId);
                                      } else {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                SingleChatPage(
                                                  userId: contact.userId,
                                                ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildInvitationTile(_ContactInvitation invitation, bool isDark) {
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
            Icons.person_add_alt_1_outlined,
            color: AppColors.primary(isDark),
          ),
        ),
        title: Text(
          invitation.userId,
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
              '好友申请',
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
              onPressed: () => _declineInvitation(invitation.userId),
              child: const Text('拒绝'),
            ),
            FilledButton(
              onPressed: () => _acceptInvitation(invitation.userId),
              child: const Text('同意'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildServerToolLogTiles(bool isDark) {
    return _serverToolLogs
        .map((log) => _buildServerToolLogTile(log, isDark))
        .toList();
  }

  Widget _buildServerToolLogTile(String log, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputBackground(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder(isDark)),
      ),
      child: Text(
        log,
        style: TextStyle(color: AppColors.textPrimary(isDark), fontSize: 13),
      ),
    );
  }
}

class _ContactInvitation {
  const _ContactInvitation({required this.userId, this.reason});

  final String userId;
  final String? reason;
}
