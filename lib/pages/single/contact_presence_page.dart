import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/pages/single/contact_api.dart';

import '../../common/widgets/input_dialog.dart';
import '../../common/widgets/common_gradient_background.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_settings.dart';

typedef PresenceActionCallback =
    Future<List<EMPresence>> Function(String userId);
typedef PresenceCancelCallback = Future<void> Function(String userId);
typedef ContactActionCallback = Future<void> Function(String userId);
typedef ContactRemarkActionCallback =
    Future<void> Function(String userId, String remark);

class ContactPresencePage extends StatefulWidget {
  final Future<List<EMContact>> Function()? loadContacts;
  final Future<List<String>> Function()? loadSubscribedMembers;
  final PresenceActionCallback? subscribePresence;
  final PresenceCancelCallback? unsubscribePresence;
  final PresenceActionCallback? queryPresence;
  final ContactActionCallback? addUserToBlockList;
  final ContactRemarkActionCallback? setContactRemark;
  final Stream<List<EMPresence>>? presenceUpdates;

  const ContactPresencePage({
    super.key,
    this.loadContacts,
    this.loadSubscribedMembers,
    this.subscribePresence,
    this.unsubscribePresence,
    this.queryPresence,
    this.addUserToBlockList,
    this.setContactRemark,
    this.presenceUpdates,
  });

  @override
  State<ContactPresencePage> createState() => _ContactPresencePageState();
}

@visibleForTesting
void debugResetContactPresenceCache() {
  _ContactPresencePageState._cachedSubscribedUsers.clear();
  _ContactPresencePageState._cachedPresenceDisplays.clear();
}

class _ContactPresencePageState extends State<ContactPresencePage> {
  static const _presenceHandlerId = 'contact_presence_page';
  static final Set<String> _cachedSubscribedUsers = {};
  static final Map<String, _PresenceDisplay> _cachedPresenceDisplays = {};

  final _settings = AppSettings();
  final ScrollController _scrollController = ScrollController();
  final Map<String, _PresenceDisplay> _presenceDisplays = {};
  final Set<String> _subscribedUsers = {};

  StreamSubscription<List<EMPresence>>? _presenceSubscription;
  List<EMContact> _contacts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _subscribedUsers.addAll(_cachedSubscribedUsers);
    _presenceDisplays.addAll(_cachedPresenceDisplays);
    _attachPresenceUpdates();
    _initializePage();
  }

  @override
  void dispose() {
    _presenceSubscription?.cancel();
    if (widget.presenceUpdates == null) {
      EMClient.getInstance.presenceManager.removeEventHandler(
        _presenceHandlerId,
      );
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _attachPresenceUpdates() {
    if (widget.presenceUpdates != null) {
      _presenceSubscription = widget.presenceUpdates!.listen(
        _applyPresenceList,
      );
      return;
    }

    EMClient.getInstance.presenceManager.addEventHandler(
      _presenceHandlerId,
      EMPresenceEventHandler(onPresenceStatusChanged: _applyPresenceList),
    );
  }

  Future<void> _initializePage() async {
    await Future.wait([_fetchContacts(), _fetchSubscribedMembers()]);
  }

  Future<void> _fetchContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await (widget.loadContacts ?? fetchContactsFromSdk).call();
      if (!mounted) {
        return;
      }
      setState(() {
        _contacts = result;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('获取联系人失败: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchSubscribedMembers() async {
    try {
      final result =
          await (widget.loadSubscribedMembers ?? fetchSubscribedMembersFromSdk)
              .call();
      if (!mounted) {
        return;
      }
      final subscribedMembers = result
          .map((member) => member.trim())
          .where((member) => member.isNotEmpty)
          .toList();
      _cachedSubscribedUsers.addAll(subscribedMembers);
      setState(() {
        _subscribedUsers
          ..addAll(_cachedSubscribedUsers)
          ..addAll(subscribedMembers);
      });
      await _restoreSubscribedPresence(_subscribedUsers.toList());
    } catch (_) {}
  }

  Future<void> _restoreSubscribedPresence(List<String> members) async {
    final subscribedMembers = members
        .map((member) => member.trim())
        .where((member) => member.isNotEmpty)
        .toList();
    if (subscribedMembers.isEmpty) {
      return;
    }

    try {
      if (widget.queryPresence != null) {
        for (final member in subscribedMembers) {
          final result = await widget.queryPresence!.call(member);
          if (!mounted) {
            return;
          }
          _applyPresenceList(result);
        }
      } else {
        final result = await queryPresenceForMembersFromSdk(subscribedMembers);
        if (!mounted) {
          return;
        }
        _applyPresenceList(result);
      }
    } catch (_) {}
  }

  void _applyPresenceList(
    List<EMPresence> list, {
    bool forceRefresh = false,
  }) {
    if (!mounted) {
      return;
    }

    setState(() {
      for (final presence in list) {
        final currentDisplay = _presenceDisplays[presence.publisher];
        if (!forceRefresh &&
            currentDisplay != null &&
            presence.lastTime > 0 &&
            currentDisplay.lastTime > presence.lastTime) {
          continue;
        }
        final display = _buildPresenceDisplay(presence);
        _presenceDisplays[presence.publisher] = display;
        if (_subscribedUsers.contains(presence.publisher) ||
            _cachedSubscribedUsers.contains(presence.publisher)) {
          _cachedPresenceDisplays[presence.publisher] = display;
        }
      }
    });
  }

  _PresenceDisplay _buildPresenceDisplay(EMPresence presence) {
    final details = presence.statusDetails;
    final hasOnlineDevice = details != null && details.isNotEmpty;
    final isOnline =
        hasOnlineDevice && details.values.any((status) => status > 0);
    final customStatus = presence.statusDescription.trim();
    return _PresenceDisplay(
      onlineLabel: isOnline ? '在线' : '离线',
      customLabel: customStatus.isEmpty ? null : customStatus,
      lastTime: presence.lastTime,
    );
  }

  Widget _buildPresenceSubtitle(bool isDark, String userId) {
    final display = _presenceDisplays[userId];
    if (display == null) {
      return Text(
        '未获取 Presence 状态',
        style: TextStyle(color: AppColors.textSecondary(isDark)),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _buildStatusLabel(
          isDark: isDark,
          text: display.onlineLabel,
          backgroundColor: display.onlineLabel == '在线'
              ? const Color(0xFF16A34A)
              : const Color(0xFF64748B),
        ),
        if (display.customLabel != null)
          _buildStatusLabel(
            isDark: isDark,
            text: display.customLabel!,
            backgroundColor: AppColors.primary(isDark),
          ),
      ],
    );
  }

  Widget _buildStatusLabel({
    required bool isDark,
    required String text,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: backgroundColor.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: backgroundColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已复制: $text'),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  Future<void> _subscribe(String userId) async {
    try {
      final result =
          await (widget.subscribePresence ?? subscribePresenceFromSdk).call(
            userId,
          );
      if (!mounted) {
        return;
      }
      _cachedSubscribedUsers.add(userId);
      setState(() {
        _subscribedUsers.add(userId);
      });
      _applyPresenceList(result, forceRefresh: true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已订阅 $userId 的 Presence')));
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('订阅 Presence 失败: $e')));
    }
  }

  Future<void> _unsubscribe(String userId) async {
    try {
      await (widget.unsubscribePresence ?? unsubscribePresenceFromSdk).call(
        userId,
      );
      if (!mounted) {
        return;
      }
      _cachedSubscribedUsers.remove(userId);
      _cachedPresenceDisplays.remove(userId);
      setState(() {
        _subscribedUsers.remove(userId);
        _presenceDisplays.remove(userId);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已取消订阅 $userId')));
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('取消订阅失败: $e')));
    }
  }

  Future<void> _queryPresence(String userId) async {
    try {
      final result = await (widget.queryPresence ?? queryPresenceFromSdk).call(
        userId,
      );
      if (!mounted) {
        return;
      }
      _applyPresenceList(result, forceRefresh: true);
      final display = _presenceDisplays[userId] ??
          result
              .where((presence) => presence.publisher == userId)
              .map(_buildPresenceDisplay)
              .firstOrNull;
      final statusText = display?.onlineLabel ?? '未知';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已查询 $userId 的在线状态：$statusText')));
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('查询状态失败: $e')));
    }
  }

  Future<void> _addToBlackList(String userId) async {
    try {
      await (widget.addUserToBlockList ?? addUserToBlockListFromSdk).call(
        userId,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$userId 已加入黑名单')));
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('加入黑名单失败: $e')));
    }
  }

  Future<void> _setRemark(EMContact contact) async {
    final result = await showInputDialog(
      context: context,
      title: '设置备注',
      fields: [
        InputFieldData(title: '备注', placeholder: '请输入备注', text: contact.remark),
      ],
    );
    if (!mounted || result == null || result.isEmpty) {
      return;
    }

    final remark = result.first.text.trim();
    try {
      await (widget.setContactRemark ?? _setContactRemarkFromSdk)(
        contact.userId,
        remark,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('设置备注成功')));
      await _fetchContacts();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('设置备注失败: $e')));
    }
  }

  Future<void> _setContactRemarkFromSdk(String userId, String remark) {
    return setContactRemarkFromSdk(userId: userId, remark: remark);
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
                '联系人',
                style: TextStyle(color: AppColors.textPrimary(isDark)),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  tooltip: '刷新',
                  onPressed: _initializePage,
                  icon: const Icon(Icons.refresh),
                ),
              ],
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: AppColors.textPrimary(isDark)),
            ),
            body: Column(
              children: [
                _buildInteractionHint(isDark),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary(isDark),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _initializePage,
                          child: _contacts.isEmpty
                              ? ListView(
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height -
                                          280,
                                      child: Center(
                                        child: Text(
                                          '暂无联系人',
                                          style: TextStyle(
                                            color: AppColors.textSecondary(
                                              isDark,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: _contacts.length,
                                  itemBuilder: (context, index) {
                                    final contact = _contacts[index];
                                    final userId = contact.userId;
                                    final isSubscribed = _subscribedUsers
                                        .contains(userId);
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
                                              value: 'set_remark',
                                              child: Text('设置备注'),
                                            ),
                                            const PopupMenuItem(
                                              value: 'unsubscribe',
                                              child: Text('取消订阅 Presence'),
                                            ),
                                            const PopupMenuItem(
                                              value: 'subscribe',
                                              child: Text('订阅 Presence'),
                                            ),
                                            const PopupMenuItem(
                                              value: 'query',
                                              child: Text('查询状态'),
                                            ),
                                            const PopupMenuItem(
                                              value: 'add_to_blacklist',
                                              child: Text('加入黑名单'),
                                            ),
                                          ],
                                        );

                                        if (value == 'copy_id') {
                                          _copyToClipboard(userId);
                                        } else if (value == 'set_remark') {
                                          _setRemark(contact);
                                        } else if (value == 'subscribe') {
                                          _subscribe(userId);
                                        } else if (value == 'unsubscribe') {
                                          _unsubscribe(userId);
                                        } else if (value == 'query') {
                                          _queryPresence(userId);
                                        } else if (value ==
                                            'add_to_blacklist') {
                                          _addToBlackList(userId);
                                        }
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.inputBackground(
                                            isDark,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: AppColors.glassBorder(
                                              isDark,
                                            ),
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
                                              Icons.contacts_outlined,
                                              color: AppColors.primary(isDark),
                                            ),
                                          ),
                                          title: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  contact.remark.trim().isEmpty
                                                      ? userId
                                                      : '$userId(${contact.remark.trim()})',
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.textPrimary(
                                                          isDark,
                                                        ),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              if (isSubscribed)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary(
                                                      isDark,
                                                    ).withValues(alpha: 0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'Presence 已订阅',
                                                    style: TextStyle(
                                                      color: AppColors.primary(
                                                        isDark,
                                                      ),
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          subtitle: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 6,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _buildPresenceSubtitle(
                                                  isDark,
                                                  userId,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInteractionHint(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary(isDark).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder(isDark)),
      ),
      child: Text(
        '长按联系人可设置备注、订阅、取消订阅或查询 Presence',
        style: TextStyle(
          color: AppColors.textSecondary(isDark),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _PresenceDisplay {
  final String onlineLabel;
  final String? customLabel;
  final int lastTime;

  const _PresenceDisplay({
    required this.onlineLabel,
    required this.customLabel,
    required this.lastTime,
  });
}
