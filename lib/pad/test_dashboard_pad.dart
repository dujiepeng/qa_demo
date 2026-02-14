import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:provider/provider.dart';
import 'package:qa_flutter/uikit/lib/chat_uikit.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';
import '../common/utils/version_manager.dart';
import '../common/widgets/update_dialog.dart';
import '../test_pages/single/test_single_chat_list_page.dart';
import '../test_pages/group/test_group_list_page.dart';
import '../test_pages/chatroom/test_chat_room_list_page.dart';
import '../common/settings_page.dart';
import '../common/widgets/me_page_content.dart';

class _TabItem {
  final String label;
  final IconData icon;
  final Widget page;
  _TabItem({required this.label, required this.icon, required this.page});
}

class TestDashboardPad extends StatefulWidget {
  const TestDashboardPad({super.key});

  @override
  State<TestDashboardPad> createState() => _TestDashboardPadState();
}

class _TestDashboardPadState extends State<TestDashboardPad> {
  int _selectedIndex = 0;
  String _currentUserId = 'Unknown';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = await EMClient.getInstance.getCurrentUserId();
    if (mounted) {
      setState(() {
        _currentUserId = user ?? 'Not logged in';
      });
    }
  }

  List<_TabItem> _getTabs() {
    return [
      _TabItem(
        label: '单聊',
        icon: Icons.person_outline,
        page: const TestSingleChatListPage(),
      ),
      _TabItem(
        label: '群聊',
        icon: Icons.group_outlined,
        page: const TestGroupListPage(),
      ),
      _TabItem(
        label: '聊天室',
        icon: Icons.meeting_room_outlined,
        page: const TestChatRoomListPage(),
      ),
      _TabItem(
        label: '服务器',
        icon: Icons.dns_outlined,
        page: const SettingsPage(),
      ),
      _TabItem(
        label: '设置',
        icon: Icons.settings_outlined,
        page: const MePageContent(showAppBar: false),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final isDark = settings.isDarkMode;
    final tabs = _getTabs();

    return Scaffold(
      body: Row(
        children: [
          // 左侧细页签 (NavigationRail)
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: isDark
                ? ChatUIKitTheme.instance.color.neutralColor1
                : ChatUIKitTheme.instance.color.neutralColor98,
            selectedIconTheme: IconThemeData(color: AppColors.primary(isDark)),
            unselectedIconTheme: IconThemeData(
              color: AppColors.textSecondary(isDark),
            ),
            selectedLabelTextStyle: TextStyle(
              color: AppColors.primary(isDark),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelTextStyle: TextStyle(
              color: AppColors.textSecondary(isDark),
              fontSize: 12,
            ),
            leading: Column(
              children: [
                const SizedBox(height: 20),
                // 标题: 测试
                RotatedBox(
                  quarterTurns: -1,
                  child: Text(
                    '测试',
                    style: TextStyle(
                      color: AppColors.primary(isDark),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // 用户头像
                GestureDetector(
                  onTap: () => _showUserDetail(context, isDark),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        AppColors.primary(isDark).withValues(alpha: 0.1),
                    child: Icon(
                      Icons.person,
                      color: AppColors.primary(isDark),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
            trailing: Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 快速切换测试模式 (可选保留)
                  IconButton(
                    icon: Icon(
                      Icons.bug_report,
                      color: settings.isTestMode
                          ? AppColors.primary(isDark)
                          : AppColors.textSecondary(isDark),
                    ),
                    onPressed: () {
                      settings.isTestMode = !settings.isTestMode;
                      settings.saveSettings();
                    },
                  ),
                  // 主题切换
                  IconButton(
                    icon: Icon(
                      isDark ? Icons.light_mode : Icons.dark_mode,
                      color: AppColors.textSecondary(isDark),
                    ),
                    onPressed: () {
                      settings.isDarkMode = !isDark;
                      settings.saveSettings();
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            destinations: tabs.map((tab) {
              return NavigationRailDestination(
                icon: Icon(tab.icon),
                label: Text(tab.label),
              );
            }).toList(),
          ),
          // 分割线
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: AppColors.glassBorder(isDark),
          ),
          // 右侧主内容区域
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: tabs.map((tab) => tab.page).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetail(BuildContext context, bool isDark) async {
    final deviceId = await EMClient.getInstance.getCurrentDeviceId();
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('当前用户'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('用户 ID: $_currentUserId'),
            const SizedBox(height: 8),
            Text('设备 ID: $deviceId'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
