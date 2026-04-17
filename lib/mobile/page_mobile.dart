import 'package:flutter/material.dart';
import 'package:qa_flutter/pages/single/black_list_page.dart';
import 'package:qa_flutter/pages/single/contact_presence_page.dart';
import '../common/widgets/common_gradient_background.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';
import '../common/widgets/common_dialogs.dart';

class GridItem {
  final String title;
  final IconData? icon;
  final int badgeCount;
  final VoidCallback onTap;

  GridItem({
    required this.title,
    this.icon,
    this.badgeCount = 0,
    required this.onTap,
  });
}

class PageMobile extends StatefulWidget {
  final bool isDark;
  final int offlineMessageCount;
  const PageMobile({
    super.key,
    this.isDark = true,
    this.offlineMessageCount = 0,
  });

  @override
  State<PageMobile> createState() => _PageMobileState();
}

class _PageMobileState extends State<PageMobile> {
  final _settings = AppSettings();
  late final List<GridItem> _testItems;

  @override
  void initState() {
    super.initState();
    _testItems = [
      GridItem(
        title: '会话',
        icon: Icons.chat_outlined,
        onTap: () => Navigator.pushNamed(context, '/conversation_list'),
      ),
      GridItem(
        title: '单聊',
        icon: Icons.person_outlined,
        onTap: () => Navigator.pushNamed(context, '/single_chat_list'),
      ),
      GridItem(
        title: '联系人',
        icon: Icons.contacts_outlined,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ContactPresencePage()),
          );
        },
      ),
      GridItem(
        title: '群聊',
        icon: Icons.group_outlined,
        onTap: () => Navigator.pushNamed(context, '/group_list'),
      ),
      GridItem(
        title: '聊天室',
        icon: Icons.list_alt_outlined,
        onTap: () => Navigator.pushNamed(context, '/room_list'),
      ),
      GridItem(
        title: '黑名单',
        icon: Icons.block_outlined,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BlackListPage()),
          );
        },
      ),
      GridItem(
        title: '我的',
        icon: Icons.account_circle_outlined,
        onTap: () => Navigator.pushNamed(context, '/my_page'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _settings.isDarkMode;

    return CommonGradientBackground(
      isDark: isDark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            '功能列表',
            style: TextStyle(color: AppColors.textPrimary(isDark)),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () =>
                  CommonDialogs.showUserInfoDialog(context, isDark),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.pushNamed(context, '/me_page'),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground(isDark),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder(isDark)),
                ),
                child: Text(
                  '离线消息: ${widget.offlineMessageCount}',
                  style: TextStyle(
                    color: AppColors.textPrimary(isDark),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: _testItems.length,
                  itemBuilder: (context, index) =>
                      _buildGridItem(_testItems[index], isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(GridItem item, bool isDark) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(15),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.inputBackground(isDark),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.glassBorder(isDark)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary(isDark).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: item.icon != null
                        ? Icon(
                            item.icon,
                            color: AppColors.primary(isDark),
                            size: 28,
                          )
                        : Text(
                            item.title.isNotEmpty ? item.title[0] : '?',
                            style: TextStyle(
                              color: AppColors.primary(isDark),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  style: TextStyle(
                    color: AppColors.textPrimary(isDark),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (item.badgeCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                child: Center(
                  child: Text(
                    '${item.badgeCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
