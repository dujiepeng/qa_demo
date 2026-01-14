import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';
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

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final _settings = AppSettings();

  @override
  Widget build(BuildContext context) {
    final isDark = _settings.isDarkMode;

    return AnimatedBuilder(
      animation: _settings,
      builder: (context, _) {
        final List<Widget> pages;
        final List<BottomNavigationBarItem> items;

        if (_settings.isTestMode) {
          pages = [TestPage(isDark: isDark), MePage(isDark: isDark)];
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
            ConversationsPage(isDark: isDark),
            ContactsPage(isDark: isDark),
            GroupsPage(isDark: isDark),
            RoomsPage(isDark: isDark),
            MePage(isDark: isDark),
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

        return Scaffold(
          backgroundColor: AppColors.backgroundStart(isDark),
          body: IndexedStack(index: safeIndex, children: pages),
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
              currentIndex: safeIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppColors.backgroundEnd(isDark),
              selectedItemColor: AppColors.primary(isDark),
              unselectedItemColor: AppColors.textSecondary(isDark),
              showUnselectedLabels: true,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              items: items,
            ),
          ),
        );
      },
    );
  }
}
