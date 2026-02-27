import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/pages/single/single_chat_page.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_settings.dart';
import '../../common/widgets/common_gradient_background.dart';

/// 好友列表页面
class SingleChatListPage extends StatefulWidget {
  final Function(String userId)? onItemTap;
  const SingleChatListPage({super.key, this.onItemTap});

  @override
  State<SingleChatListPage> createState() => _SingleChatListPageState();
}

class _SingleChatListPageState extends State<SingleChatListPage> {
  final _settings = AppSettings();
  final ScrollController _scrollController = ScrollController();
  List<EMContact> _contacts = [];
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
        onContactInvited: (username, reason) async {
          try {
            await EMClient.getInstance.contactManager.acceptInvitation(
              username,
            );
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('已接受好友申请')));
              _fetchContacts();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('接受好友申请失败: $e')));
            }
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

  /// 获取好友列表
  Future<void> _fetchContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await EMClient.getInstance.contactManager
          .fetchAllContacts();
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
                    child: _contacts.isEmpty
                        ? ListView(
                            children: [
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
                            itemCount: _contacts.length,
                            itemBuilder: (context, index) {
                              final contact = _contacts[index];
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
                                        value: 'delete',
                                        child: Text('删除'),
                                      ),
                                    ],
                                  );

                                  if (value == 'copy_id') {
                                    _copyToClipboard(contact.userId);
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
}
