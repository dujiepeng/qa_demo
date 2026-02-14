import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qa_flutter/uikit/lib/chat_uikit.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';
import '../test_pages/single/test_single_chat_list_page.dart';
import '../test_pages/group/test_group_list_page.dart';
import '../test_pages/chatroom/test_chat_room_list_page.dart';
import '../common/utils/log_service.dart';

class TestDashboardPad extends StatefulWidget {
  const TestDashboardPad({super.key});

  @override
  State<TestDashboardPad> createState() => _TestDashboardPadState();
}

class _TestDashboardPadState extends State<TestDashboardPad>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _currentUserId = 'Unknown';
  final ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final user = await EMClient.getInstance.getCurrentUserId();
    if (mounted) {
      setState(() {
        _currentUserId = user ?? 'Not logged in';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final isDark = settings.isDarkMode;

    return Scaffold(
      body: Row(
        children: [
          // 左侧细页签 (NavigationRail) - 只保留“测试”
          NavigationRail(
            selectedIndex: 0,
            onDestinationSelected: (index) {
              // 只有一个页签，无需切换
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
            leading: Column(
              children: [
                const SizedBox(height: 20),
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
              ],
            ),
            trailing: Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => _showUserDetail(context, isDark),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary(
                        isDark,
                      ).withValues(alpha: 0.1),
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
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.bug_report_outlined),
                label: Text('测试'),
              ),
            ],
          ),
          // 分割线
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: AppColors.glassBorder(isDark),
          ),
          // 右侧内容区域: 上下平分
          Expanded(
            child: Column(
              children: [
                // 上半部分: Tab 页 (50%)
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primary(isDark),
                        unselectedLabelColor: AppColors.textSecondary(isDark),
                        indicatorColor: AppColors.primary(isDark),
                        tabs: const [
                          Tab(text: '单聊'),
                          Tab(text: '群聊'),
                          Tab(text: '聊天室'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: const [
                            TestSingleChatListPage(),
                            TestGroupListPage(),
                            TestChatRoomListPage(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // 水平分割线
                Divider(height: 1, thickness: 1, color: AppColors.glassBorder(isDark)),
                // 下半部分: 日志区域 (50%)
                Expanded(
                  flex: 1,
                  child: _buildLogPanel(context, isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogPanel(BuildContext context, bool isDark) {
    final logService = context.watch<LogService>();
    
    // 自动滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.jumpTo(_logScrollController.position.maxScrollExtent);
      }
    });

    return Container(
      color: isDark ? Colors.black87 : Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '操作日志',
                style: TextStyle(
                  color: AppColors.primary(isDark),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy_all, size: 18),
                    onPressed: () {
                      // 复制日志逻辑 (可后续完善)
                      logService.log('尝试复制日志...');
                    },
                    tooltip: '复制全部',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => logService.clear(),
                    tooltip: '清空日志',
                  ),
                ],
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              controller: _logScrollController,
              itemCount: logService.logs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    logService.logs[index],
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 12,
                      color: isDark ? Colors.greenAccent : Colors.black87,
                    ),
                  ),
                );
              },
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
