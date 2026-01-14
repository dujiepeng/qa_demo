import 'dart:io';
import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final _settings = AppSettings();

  @override
  Widget build(BuildContext context) {
    final isDark = _settings.isDarkMode;

    final List<Widget> pages = [
      _PlaceholderPage(
        title: '会话',
        icon: Icons.chat_bubble_outline,
        isDark: isDark,
      ),
      ContactsPage(isDark: isDark), // 替换为真实的联系人页面
      _PlaceholderPage(title: '群组', icon: Icons.group_outlined, isDark: isDark),
      _PlaceholderPage(
        title: '聊天室',
        icon: Icons.meeting_room_outlined,
        isDark: isDark,
      ),
      _buildSettingsTab(isDark),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundStart(isDark),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.backgroundEnd(isDark),
          selectedItemColor: AppColors.primary(isDark),
          unselectedItemColor: AppColors.textSecondary(isDark),
          showUnselectedLabels: true,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: '会话',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: '好友',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              activeIcon: Icon(Icons.group),
              label: '群组',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.meeting_room_outlined),
              activeIcon: Icon(Icons.meeting_room),
              label: '聊天室',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: '设置',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab(bool isDark) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '设置',
          style: TextStyle(color: AppColors.textPrimary(isDark)),
        ),
        centerTitle: true,
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
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSettingSectionTitle('偏好设置', isDark),
            _buildSwitchItem(
              title: '深色模式',
              icon: Icons.dark_mode_outlined,
              value: _settings.isDarkMode,
              onChanged: (val) {
                setState(() => _settings.isDarkMode = val);
                _settings.saveSettings();
              },
              isDark: isDark,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => exit(0),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                '退出应用',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.primary(isDark),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground(isDark),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.glassBorder(isDark)),
      ),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary(isDark), size: 20),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(color: AppColors.textPrimary(isDark))),
          ],
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary(isDark),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
      ),
    );
  }
}

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
      final contacts = await EMClient.getInstance.contactManager
          .fetchAllContacts();
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
                        // 使空状态也能触发下拉刷新
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

class _PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;

  const _PlaceholderPage({
    required this.title,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          style: TextStyle(color: AppColors.textPrimary(isDark)),
        ),
        centerTitle: true,
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 80,
                color: AppColors.primary(isDark).withOpacity(0.5),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary(isDark),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '正在开发中...',
                style: TextStyle(
                  color: AppColors.textSecondary(isDark).withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
