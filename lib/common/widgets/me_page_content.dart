import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';
import '../common/utils/version_manager.dart';
import '../common/widgets/update_dialog.dart';

class MePageContent extends StatelessWidget {
  final bool showAppBar;
  const MePageContent({super.key, this.showAppBar = false});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final isDark = settings.isDarkMode;

    Widget body = ListView(
      padding: EdgeInsets.only(
        top: showAppBar ? 20 : 40,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      children: [
        _buildSettingSectionTitle('偏好设置', isDark),
        _buildSwitchItem(
          title: '深色模式',
          icon: Icons.dark_mode_outlined,
          value: isDark,
          onChanged: (val) {
            settings.isDarkMode = val;
            settings.saveSettings();
          },
          isDark: isDark,
        ),
        const SizedBox(height: 20),
        _buildSettingSectionTitle('高级设置', isDark),
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputBackground(isDark),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.glassBorder(isDark)),
          ),
          child: ListTile(
            leading: Icon(
              Icons.admin_panel_settings_outlined,
              color: AppColors.textSecondary(isDark),
            ),
            title: Text(
              '服务器配置',
              style: TextStyle(color: AppColors.textPrimary(isDark)),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary(isDark),
            ),
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
        ),
        const SizedBox(height: 10),
        _buildSwitchItem(
          title: '测试模式',
          icon: Icons.bug_report_outlined,
          value: settings.isTestMode,
          onChanged: (val) {
            settings.isTestMode = val;
            settings.saveSettings();
          },
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputBackground(isDark),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.glassBorder(isDark)),
          ),
          child: Consumer<VersionManager>(
            builder: (context, vm, _) {
              return ListTile(
                leading: Icon(
                  Icons.info_outline,
                  color: AppColors.textSecondary(isDark),
                ),
                title: Text(
                  '当前版本',
                  style: TextStyle(color: AppColors.textPrimary(isDark)),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (vm.hasNewVersion)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
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
                    Text(
                      AppConfig.appVersion,
                      style: TextStyle(
                        color: AppColors.textSecondary(isDark),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  if (vm.hasNewVersion) {
                    UpdateDialog.show(context);
                  }
                },
              );
            },
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.withValues(alpha: 0.8),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: const Text(
            '退出登录',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );

    if (showAppBar) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            '设置',
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
          child: body,
        ),
      );
    } else {
      return body;
    }
  }

  Widget _buildSettingSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
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

  Widget _buildSwitchItem({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground(isDark),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.glassBorder(isDark)),
      ),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary(isDark), size: 20),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(color: AppColors.textPrimary(isDark))),
          ],
        ),
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primary(isDark),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
      ),
    );
  }
}
