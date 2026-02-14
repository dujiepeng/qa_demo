import 'package:qa_flutter/uikit/lib/chat_uikit.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';
import '../utils/version_manager.dart';
import '../widgets/update_dialog.dart';
import '../utils/chat_event_widget.dart';
import '../widgets/responsive_layout.dart';
import 'conversations_page.dart';
import 'contacts_page.dart';
import 'groups_page.dart';
import 'rooms_page.dart';
import 'me_page.dart';
import 'test_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with ChatUIKitThemeMixin {
  int _currentIndex = 0;
  final _settings = AppSettings();

  // 缓存页面实例，避免每次 build 都重新创建
  late final Widget _conversationsPage;
  late final Widget _contactsPage;
  late final Widget _groupsPage;
  late final Widget _roomsPage;
  late final Widget _mePage;
  late final Widget _testPage;

  @override
  void initState() {
    super.initState();
    // 初始化所有页面实例
    _conversationsPage = const ConversationsPage();
    _contactsPage = const ContactsPage();
    _groupsPage = const GroupsPage();
    _roomsPage = const RoomsPage();
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
    return AnimatedBuilder(
      animation: _settings,
      builder: (context, _) {
        final isDark = theme.color.isDark;
        final List<Widget> pages;
        final List<BottomNavigationBarItem> items;

        if (_settings.isTestMode) {
          pages = [_testPage, _mePage];
          items = const [
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
        } else {
          pages = [
            _conversationsPage,
            _contactsPage,
            _groupsPage,
            _roomsPage,
            _mePage,
          ];
          items = const [
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
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: '我',
            ),
          ];
        }

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
            tablet: Scaffold(
              backgroundColor: AppColors.backgroundStart(isDark),
              body: Row(
                children: [
                  _buildNavigationRail(context, isDark, items, safeIndex),
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(child: body),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建 Pad 侧边导航栏
  Widget _buildNavigationRail(
    BuildContext context,
    bool isDark,
    List<BottomNavigationBarItem> items,
    int safeIndex,
  ) {
    return NavigationRail(
      selectedIndex: safeIndex,
      onDestinationSelected: (index) => setState(() => _currentIndex = index),
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
      ),
      unselectedLabelTextStyle: TextStyle(
        color: AppColors.textSecondary(isDark),
        fontSize: 12,
      ),
      destinations: items.map((item) {
        // 为“我”按钮处理红点提示
        Widget icon = item.icon;
        Widget activeIcon = item.activeIcon ?? item.icon;

        if (item.label == '我' && VersionManager().hasNewVersion) {
          icon = _buildBadgeIcon(icon);
          activeIcon = _buildBadgeIcon(activeIcon);
        }

        return NavigationRailDestination(
          icon: icon,
          selectedIcon: activeIcon,
          label: Text(item.label ?? ''),
        );
      }).toList(),
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
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ListenableBuilder(
        listenable: VersionManager(),
        builder: (context, _) {
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
              if (item.label == '我' && VersionManager().hasNewVersion) {
                return BottomNavigationBarItem(
                  icon: _buildBadgeIcon(item.icon),
                  activeIcon: _buildBadgeIcon(item.activeIcon ?? item.icon),
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
