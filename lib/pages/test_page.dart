import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';

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
  const TestPage({super.key, required this.isDark});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final _settings = AppSettings();

  final List<TestGridItem> _testItems = [
    TestGridItem(
      title: '接口测试',
      icon: Icons.api_outlined,
      badgeCount: 2,
      onTap: () {},
    ),
    TestGridItem(title: '性能监控', icon: Icons.speed_outlined, onTap: () {}),
    TestGridItem(title: '日志查看', icon: Icons.assignment_outlined, onTap: () {}),
    TestGridItem(title: 'UI 实验室', badgeCount: 1, onTap: () {}),
    TestGridItem(title: '网络监听', icon: Icons.network_check, onTap: () {}),
    TestGridItem(title: '数据库', icon: Icons.storage_outlined, onTap: () {}),
    TestGridItem(title: '极客模式', onTap: () {}),
  ];

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
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundStart(isDark),
              AppColors.backgroundEnd(isDark),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            top: kToolbarHeight + 40,
            left: 10,
            right: 10,
          ),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.9,
            ),
            itemCount: _testItems.length,
            itemBuilder: (context, index) {
              return _buildGridItem(_testItems[index], isDark);
            },
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
                    color: AppColors.primary(isDark).withOpacity(0.1),
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
              top: -5,
              right: -5,
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
