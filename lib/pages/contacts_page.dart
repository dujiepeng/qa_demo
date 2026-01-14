import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import '../theme/app_colors.dart';
import '../utils/chat_event_manager.dart';

class ContactsPage extends StatefulWidget {
  final bool isDark;
  const ContactsPage({super.key, required this.isDark});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<EMContact> _contacts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('ContactsPage: Fetching contacts...');
      final contacts = await EMClient.getInstance.contactManager
          .fetchAllContacts();
      debugPrint('ContactsPage: Fetched ${contacts.length} contacts.');
      setState(() {
        _contacts = contacts;
      });
    } catch (e) {
      debugPrint('ContactsPage Error: _fetchContacts error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('获取好友列表失败: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddContactDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundEnd(widget.isDark),
        title: Text(
          '添加好友',
          style: TextStyle(color: AppColors.textPrimary(widget.isDark)),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: AppColors.textPrimary(widget.isDark)),
          decoration: InputDecoration(
            hintText: '请输入对方 UID',
            hintStyle: TextStyle(
              color: widget.isDark ? Colors.white38 : Colors.black38,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary(widget.isDark)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: TextStyle(color: AppColors.textSecondary(widget.isDark)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final userId = controller.text.trim();
              if (userId.isEmpty) return;

              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);

              try {
                await EMClient.getInstance.contactManager.addContact(userId);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('已发送好友请求给: $userId'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                // 打印错误到控制台
                debugPrint(
                  'ContactsPage Error: _showAddContactDialog addContact error: $e',
                );
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('添加失败: $e'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary(widget.isDark),
            ),
            child: const Text('发送', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      'ContactsPage: Building UI. _contacts.length = ${_contacts.length}, _isLoading = $_isLoading',
    );
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '好友',
          style: TextStyle(color: AppColors.textPrimary(widget.isDark)),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddContactDialog(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundStart(widget.isDark),
              AppColors.backgroundEnd(widget.isDark),
            ],
          ),
        ),
        child: _isLoading && _contacts.isEmpty
            ? Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary(widget.isDark),
                ),
              )
            : RefreshIndicator(
                onRefresh: _fetchContacts,
                color: AppColors.primary(widget.isDark),
                child: ListView.separated(
                  padding: const EdgeInsets.all(10),
                  physics: const AlwaysScrollableScrollPhysics(),
                  // 列表项总数 = 好友数 + 1 (顶部固定项)
                  itemCount: _contacts.length + 1,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    // 第一项固定为“好友申请”
                    if (index == 0) {
                      return _buildInvitationEntry(context);
                    }

                    // 后续为好友项
                    final contact = _contacts[index - 1];
                    final contactId = contact.userId;
                    return _buildContactItem(contactId);
                  },
                ),
              ),
      ),
    );
  }

  // 构建好友申请入口
  Widget _buildInvitationEntry(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground(widget.isDark),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.glassBorder(widget.isDark)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary(widget.isDark).withOpacity(0.2),
          child: Icon(
            Icons.person_add,
            color: AppColors.primary(widget.isDark),
          ),
        ),
        title: Text(
          '好友申请',
          style: TextStyle(
            color: AppColors.textPrimary(widget.isDark),
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: ValueListenableBuilder<int>(
          valueListenable: ChatEventManager.getInstance().friendRequestCount,
          builder: (context, count, child) {
            if (count == 0) {
              return Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary(widget.isDark),
              );
            }
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary(widget.isDark),
                ),
              ],
            );
          },
        ),
        onTap: () {
          // 跳转至申请列表详情页
        },
      ),
    );
  }

  // 构建普通好友项
  Widget _buildContactItem(String contactId) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground(widget.isDark),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.glassBorder(widget.isDark)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary(widget.isDark).withOpacity(0.2),
          child: Icon(Icons.person, color: AppColors.primary(widget.isDark)),
        ),
        title: Text(
          contactId,
          style: TextStyle(
            color: AppColors.textPrimary(widget.isDark),
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary(widget.isDark),
        ),
        onTap: () {
          // 后续可以进入聊天页
        },
      ),
    );
  }
}
