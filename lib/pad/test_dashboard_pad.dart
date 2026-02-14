import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qa_flutter/uikit/lib/chat_uikit.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';
import '../test_pages/single/test_single_chat_list_page.dart';
import '../test_pages/single/test_single_chat_page.dart';
import '../test_pages/group/test_group_list_page.dart';
import '../test_pages/group/test_group_page.dart';
import '../test_pages/chatroom/test_chat_room_list_page.dart';
import '../test_pages/chatroom/test_chat_room_page.dart';
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

  // 局部详情页状态
  Widget? _detailPage;
  String _detailTitle = '';

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

  // 切换到详情页
  void _showDetail(Widget page, String title) {
    setState(() {
      _detailPage = page;
      _detailTitle = title;
    });
  }

  // 返回列表页
  void _hideDetail() {
    setState(() {
      _detailPage = null;
      _detailTitle = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final isDark = settings.isDarkMode;

    return Scaffold(
      body: Row(
        children: [
          // 左侧细页签 (NavigationRail)
          NavigationRail(
            selectedIndex: 0,
            onDestinationSelected: (index) {
              if (_detailPage != null) _hideDetail();
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
                // 顶层工具栏 (Master AppBar)
                _buildMasterAppBar(isDark),
                // 上半部分内容 (列表或详情)
                Expanded(
                  flex: 1,
                  child: _detailPage != null
                      ? _detailPage!
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            TestSingleChatListPage(
                              onItemTap: (id) => _showDetail(
                                TestSingleChatPage(
                                  userId: id,
                                  showAppBar: false,
                                ),
                                '单聊: $id',
                              ),
                            ),
                            TestGroupListPage(
                              onItemTap: (id) => _showDetail(
                                TestGroupPage(groupId: id, showAppBar: false),
                                '群组: $id',
                              ),
                            ),
                            TestChatRoomListPage(
                              onItemTap: (id) => _showDetail(
                                TestChatRoomPage(roomId: id, showAppBar: false),
                                '聊天室: $id',
                              ),
                            ),
                          ],
                        ),
                ),
                // 水平分割线
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.glassBorder(isDark),
                ),
                // 下半部分: 日志区域 (50%)
                Expanded(flex: 1, child: _buildLogPanel(context, isDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 构建顶层统一工具栏
  Widget _buildMasterAppBar(bool isDark) {
    return Material(
      color: isDark
          ? ChatUIKitTheme.instance.color.neutralColor1
          : ChatUIKitTheme.instance.color.neutralColor98,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.glassBorder(isDark),
              width: 0.5,
            ),
          ),
        ),
        child: _detailPage != null
            ? _buildDetailHeader(isDark)
            : _buildTabHeader(isDark),
      ),
    );
  }

  // 列表模式下的 Header (TabBar)
  Widget _buildTabHeader(bool isDark) {
    return TabBar(
      controller: _tabController,
      labelColor: AppColors.primary(isDark),
      unselectedLabelColor: AppColors.textSecondary(isDark),
      indicatorColor: AppColors.primary(isDark),
      indicatorSize: TabBarIndicatorSize.label,
      indicatorWeight: 3,
      dividerColor: Colors.transparent,
      tabs: const [
        Tab(
          height: 50,
          child: Text(
            '单聊',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        Tab(
          height: 50,
          child: Text(
            '群聊',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        Tab(
          height: 50,
          child: Text(
            '聊天室',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // 详情模式下的 Header (Back + Title + Actions)
  Widget _buildDetailHeader(bool isDark) {
    return Row(
      children: [
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: _hideDetail,
          color: AppColors.primary(isDark),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _detailTitle,
            style: TextStyle(
              color: AppColors.textPrimary(isDark),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // 统一提取功能按钮
        IconButton(
          icon: const Icon(Icons.info_outline, size: 22),
          onPressed: () => Navigator.of(context).pushNamed('/settings'),
          color: AppColors.textSecondary(isDark),
          tooltip: 'SDK配置',
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildLogPanel(BuildContext context, bool isDark) {
    final logService = context.watch<LogService>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.jumpTo(
          _logScrollController.position.maxScrollExtent,
        );
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
                    onPressed: () => logService.log('尝试复制日志...'),
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
