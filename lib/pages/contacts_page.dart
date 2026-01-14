import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import '../theme/app_colors.dart';

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
                child: _contacts.isEmpty
                    ? ListView(
                        // 确保空状态也能触发下拉刷新
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.3,
                          ),
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 80,
                                  color: AppColors.primary(
                                    widget.isDark,
                                  ).withOpacity(0.5),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  '暂无好友',
                                  style: TextStyle(
                                    color: AppColors.textPrimary(widget.isDark),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '下拉刷新或点击右上角添加好友',
                                  style: TextStyle(
                                    color: AppColors.textSecondary(
                                      widget.isDark,
                                    ).withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(10),
                        itemCount: _contacts.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final contact = _contacts[index];
                          final contactId = contact.userId;
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.inputBackground(widget.isDark),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: AppColors.glassBorder(widget.isDark),
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary(
                                  widget.isDark,
                                ).withOpacity(0.2),
                                child: Icon(
                                  Icons.person,
                                  color: AppColors.primary(widget.isDark),
                                ),
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
                        },
                      ),
              ),
      ),
    );
  }
}
