import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';
import '../common/widgets/common_gradient_background.dart';
import '../common/widgets/common_dialogs.dart';

class TestGridItem {
  final String title;
  final IconData? icon;
  final int badgeCount;
  final VoidCallback onTap;

  TestGridItem({
    required this.title,
    this.icon,
    this.badgeCount = 0,
    required this.onTap,
  });
}

class TestPage extends StatefulWidget {
  final bool isDark;
  const TestPage({super.key, this.isDark = true});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final _settings = AppSettings();
  late final List<TestGridItem> _testItems;

  @override
  void initState() {
    super.initState();
    _testItems = [
      TestGridItem(
        title: '单聊',
        icon: Icons.person_outlined,
        onTap: () => Navigator.pushNamed(context, '/test_single_chat_list'),
      ),
      TestGridItem(
        title: '群聊',
        icon: Icons.group_outlined,
        onTap: () => Navigator.pushNamed(context, '/test_group_list'),
      ),
      TestGridItem(
        title: '聊天室',
        icon: Icons.list_alt_outlined,
        onTap: () => Navigator.pushNamed(context, '/test_chat_room_list'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _settings.isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '测试',
          style: TextStyle(color: AppColors.textPrimary(isDark)),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => CommonDialogs.showUserInfoDialog(context, isDark),
          ),
        ],
      ),
      body: CommonGradientBackground(
        isDark: isDark,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
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
      ),
    );
  }

  Widget _buildGridItem(TestGridItem item, bool isDark) {
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
