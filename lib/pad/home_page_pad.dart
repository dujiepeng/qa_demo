import 'package:chat_uikit_theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';
import '../common/widgets/common_dialogs.dart';
import '../common/widgets/log_panel/log_panel.dart';
import 'me_page_pad.dart';
import 'page_pad.dart';

class HomePagePad extends StatefulWidget {
  const HomePagePad({super.key});

  @override
  State<HomePagePad> createState() => _HomePagePadState();
}

class _HomePagePadState extends State<HomePagePad> with TickerProviderStateMixin {
  late TabController _tabController;

  // 日志高度
  double _logPanelHeight = 300.0;
  // 最小日志高度
  static const double _minLogHeight = 100.0;

  // 侧边栏索引: 0 - 测试, 1 - 设置
  int _navIndex = 0;

  // 局部详情页状态
  Widget? _detailPage;
  String _detailTitle = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      resizeToAvoidBottomInset: false,
      body: Row(
        children: [
          // 左侧细页签 (NavigationRail)
          NavigationRail(
            selectedIndex: _navIndex,
            onDestinationSelected: (index) {
              setState(() {
                _navIndex = index;
                // 切换大类页签时，自动退出详情页
                if (_detailPage != null) _hideDetail();
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
                RotatedBox(
                  quarterTurns: -1,
                  child: Text(
                    _navIndex == 0 ? '测试' : '设置',
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
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                label: Text('设置'),
              ),
            ],
          ),
          // 分割线
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: AppColors.glassBorder(isDark),
          ),
          // 右侧内容区域
          Expanded(
            child: _navIndex == 0
                ? _buildDashboard(isDark)
                : MePagePad(isDark: isDark),
          ),
        ],
      ),
    );
  }

  // 构建测试面板 (主逻辑)
  Widget _buildDashboard(bool isDark) {
    return Column(
      children: [
        // 顶层工具栏 (Master AppBar)
        _buildMasterAppBar(isDark),
        // 上半部分内容 (列表或详情)
        Expanded(
          child:
              _detailPage ??
              PagePad(tabController: _tabController, onShowDetail: _showDetail),
        ),

        // 可拖动的分割线手柄
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragUpdate: (details) {
            setState(() {
              // 向上拖动 delta 是负的，日志高度增加
              _logPanelHeight -= details.delta.dy;

              // 限制最大高度不能超过屏幕高度的 80%
              final maxHeight = MediaQuery.of(context).size.height * 0.8;
              if (_logPanelHeight < _minLogHeight) {
                _logPanelHeight = _minLogHeight;
              } else if (_logPanelHeight > maxHeight) {
                _logPanelHeight = maxHeight;
              }
            });
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeUpDown,
            child: Container(
              height: 10,
              width: double.infinity,
              color: Colors.transparent, // 点击热区
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.glassBorder(isDark),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ),

        // 下半部分: 日志区域
        SizedBox(
          height: _logPanelHeight,
          child: LogPanel(isDark: isDark),
        ),
      ],
    );
  }

  // 构建顶层统一工具栏 (仅用于测试面板)
  Widget _buildMasterAppBar(bool isDark) {
    return Material(
      color: isDark
          ? ChatUIKitTheme.instance.color.neutralColor1
          : ChatUIKitTheme.instance.color.neutralColor98,
      child: Container(
        height: 70,
        padding: const EdgeInsets.only(top: 20),
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
            '会话',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
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
          onPressed: () => Navigator.of(context).pushNamed('/server_config'),
          color: AppColors.textSecondary(isDark),
          tooltip: 'SDK配置',
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  void _showUserDetail(BuildContext context, bool isDark) async {
    CommonDialogs.showUserInfoDialog(context, isDark);
  }
}
