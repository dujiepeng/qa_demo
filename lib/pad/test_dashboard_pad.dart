import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';
import '../common/utils/version_manager.dart';
import '../common/widgets/update_dialog.dart';

class TestDashboardPad extends StatefulWidget {
  const TestDashboardPad({super.key});

  @override
  State<TestDashboardPad> createState() => _TestDashboardPadState();
}

class _TestDashboardPadState extends State<TestDashboardPad> {
  String _currentUserId = 'Unknown';
  String _deviceId = 'Unknown';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = await EMClient.getInstance.getCurrentUserId();
    final device = await EMClient.getInstance.getCurrentDeviceId();
    if (mounted) {
      setState(() {
        _currentUserId = user ?? 'Not logged in';
        _deviceId = device;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final isDark = settings.isDarkMode;

    return Scaffold(
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
        child: Row(
          children: [
            // 左侧侧边栏: 用户信息与核心设置
            _buildSidebar(context, settings, isDark),
            // 垂直分割线
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppColors.glassBorder(isDark),
            ),
            // 右侧主区域: 测试功能网格
            Expanded(child: _buildMainContent(context, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    AppSettings settings,
    bool isDark,
  ) {
    return Container(
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserInfoSection(isDark),
          const SizedBox(height: 30),
          _buildSectionTitle('快速配置', isDark),
          _buildSidebarItem(
            title: '服务器配置',
            icon: Icons.admin_panel_settings_outlined,
            onTap: () => Navigator.pushNamed(context, '/settings'),
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildSidebarSwitch(
            title: '深色模式',
            icon: Icons.dark_mode_outlined,
            value: settings.isDarkMode,
            onChanged: (val) => settings.isDarkMode = val,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildSidebarSwitch(
            title: '测试模式',
            icon: Icons.bug_report_outlined,
            value: settings.isTestMode,
            onChanged: (val) => settings.isTestMode = val,
            isDark: isDark,
          ),
          const Spacer(),
          _buildVersionInfo(context, isDark),
          const SizedBox(height: 20),
          _buildLogoutButton(context, settings, isDark),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputBackground(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary(isDark),
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '当前用户',
                      style: TextStyle(
                        color: AppColors.textSecondary(isDark),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _currentUserId,
                      style: TextStyle(
                        color: AppColors.textPrimary(isDark),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            '设备 ID',
            style: TextStyle(
              color: AppColors.textSecondary(isDark),
              fontSize: 12,
            ),
          ),
          Text(
            _deviceId,
            style: TextStyle(
              color: AppColors.textPrimary(isDark),
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.primary(isDark),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.inputBackground(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder(isDark)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary(isDark), size: 20),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(color: AppColors.textPrimary(isDark))),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary(isDark),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarSwitch({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.inputBackground(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder(isDark)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary(isDark), size: 20),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(color: AppColors.textPrimary(isDark))),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionInfo(BuildContext context, bool isDark) {
    return Consumer<VersionManager>(
      builder: (context, vm, _) {
        return InkWell(
          onTap: vm.hasNewVersion ? () => UpdateDialog.show(context) : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.inputBackground(isDark),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder(isDark)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.textSecondary(isDark),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '版本',
                      style: TextStyle(
                        color: AppColors.textSecondary(isDark),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      AppConfig.appVersion,
                      style: TextStyle(
                        color: AppColors.textPrimary(isDark),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (vm.hasNewVersion)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton(
    BuildContext context,
    AppSettings settings,
    bool isDark,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          try {
            await EMClient.getInstance.logout();
          } catch (_) {}
          settings.isLoggedIn = false;
          await settings.saveSettings();
          if (context.mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        },
        icon: const Icon(Icons.logout),
        label: const Text('退出登录'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 60, 40, 20),
          child: Text(
            '测试面板',
            style: TextStyle(
              color: AppColors.textPrimary(isDark),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            // 复用 TestPage 的 GridView 逻辑，但在 Pad 上增加列数
            child: GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              children: [
                _buildGridItem(
                  title: '单聊',
                  icon: Icons.person_outlined,
                  onTap: () =>
                      Navigator.pushNamed(context, '/test_single_chat_list'),
                  isDark: isDark,
                ),
                _buildGridItem(
                  title: '群聊',
                  icon: Icons.group_outlined,
                  onTap: () => Navigator.pushNamed(context, '/test_group_list'),
                  isDark: isDark,
                ),
                _buildGridItem(
                  title: '聊天室',
                  icon: Icons.list_alt_outlined,
                  onTap: () =>
                      Navigator.pushNamed(context, '/test_chat_room_list'),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.inputBackground(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.glassBorder(isDark)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary(isDark).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary(isDark), size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
