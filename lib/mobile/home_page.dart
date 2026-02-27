import 'package:chat_uikit_theme/chat_uikit_theme.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../common/utils/version_manager.dart';
import '../common/widgets/update_dialog.dart';
import '../common/utils/chat_event_widget.dart';
import '../common/widgets/responsive_layout.dart';
import 'me_page.dart';
import 'test_page.dart';
import '../pad/test_dashboard_pad.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with ChatUIKitThemeMixin {
  int _currentIndex = 0;

  // 缓存页面实例，避免每次 build 都重新创建
  late final Widget _mePage;
  late final Widget _testPage;

  @override
  void initState() {
    super.initState();
    // 初始化所有页面实例
    _mePage = const MePage();
    _testPage = const TestPage();

    VersionManager().addListener(_checkAndShowUpdateDialog);
  }

  @override
  void dispose() {
    VersionManager().removeListener(_checkAndShowUpdateDialog);
    super.dispose();
  }

  bool _hasShownUpdateDialog = false;

  void _checkAndShowUpdateDialog() {
    if (!mounted) return;

    // 如果有新版本，且还没弹过窗
    if (VersionManager().hasNewVersion && !_hasShownUpdateDialog) {
      _hasShownUpdateDialog = true;
      UpdateDialog.show(context);
    }
  }

  @override
  Widget themeBuilder(BuildContext context, ChatUIKitTheme theme) {
    // 监听设置变化
    final isDark = theme.color.isDark;

    final List<Widget> pages = [_testPage, _mePage];
    final List<BottomNavigationBarItem> items = const [
      BottomNavigationBarItem(
        icon: Icon(Icons.bug_report),
        activeIcon: Icon(Icons.bug_report),
        label: '测试',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: '我',
      ),
    ];

    // 索引越界保护
    int safeIndex = _currentIndex;
    if (safeIndex >= pages.length) {
      safeIndex = pages.length - 1;
    }

    final body = IndexedStack(index: safeIndex, children: pages);

    return ChatEventWidget(
      child: ResponsiveLayout(
        mobile: Scaffold(
          backgroundColor: AppColors.backgroundStart(isDark),
          body: body,
          bottomNavigationBar: _buildBottomNavigationBar(
            context,
            isDark,
            items,
            safeIndex,
          ),
        ),
        tablet: const TestDashboardPad(), // Pad 模式直接展示集成面板
      ),
    );
  }

  /// 构建手机端底部导航栏
  Widget _buildBottomNavigationBar(
    BuildContext context,
    bool isDark,
    List<BottomNavigationBarItem> items,
    int safeIndex,
  ) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Consumer<VersionManager>(
        builder: (context, vm, _) {
          return BottomNavigationBar(
            currentIndex: safeIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: isDark
                ? ChatUIKitTheme.instance.color.neutralColor1
                : ChatUIKitTheme.instance.color.neutralColor98,
            selectedItemColor: AppColors.primary(isDark),
            unselectedItemColor: AppColors.textSecondary(isDark),
            showUnselectedLabels: true,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            items: items.map((item) {
              if (item.label == '我' && vm.hasNewVersion) {
                return BottomNavigationBarItem(
                  icon: _buildBadgeIcon(item.icon),
                  activeIcon: _buildBadgeIcon(item.activeIcon),
                  label: item.label,
                );
              }
              return item;
            }).toList(),
          );
        },
      ),
    );
  }

  /// 为图标添加红点通知
  Widget _buildBadgeIcon(Widget icon) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
