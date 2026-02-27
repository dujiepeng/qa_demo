import 'package:chat_uikit_theme/chat_uikit_theme.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../common/utils/version_manager.dart';
import '../common/utils/chat_event_widget.dart';
import 'me_page_mobile.dart';
import 'test_page_mobile.dart';

class HomePageMobile extends StatefulWidget {
  const HomePageMobile({super.key});

  @override
  State<HomePageMobile> createState() => _HomePageMobileState();
}

class _HomePageMobileState extends State<HomePageMobile> {
  int _currentIndex = 0;
  late final Widget _mePage;
  late final Widget _testPage;

  @override
  void initState() {
    super.initState();
    _mePage = const MePageMobile();
    _testPage = const TestPageMobile();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ChatUIKitTheme.instance.color.isDark;
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

    int safeIndex = _currentIndex;
    if (safeIndex >= pages.length) safeIndex = pages.length - 1;

    return ChatEventWidget(
      child: Scaffold(
        backgroundColor: AppColors.backgroundStart(isDark),
        body: IndexedStack(index: safeIndex, children: pages),
        bottomNavigationBar: _buildBottomNavigationBar(
          context,
          isDark,
          items,
          safeIndex,
        ),
      ),
    );
  }

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
