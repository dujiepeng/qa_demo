import 'package:flutter/material.dart';
import 'package:qa_flutter/config/app_config.dart';

import 'package:qa_flutter/uikit/lib/chat_uikit.dart';
import '../common/utils/version_manager.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';
import '../common/widgets/update_dialog.dart';

class MePage extends StatefulWidget {
  final bool isDark;
  const MePage({super.key, this.isDark = true});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> with ChatUIKitThemeMixin {
  final _settings = AppSettings();

  @override
  Widget themeBuilder(BuildContext context, ChatUIKitTheme theme) {
    final isDark = theme.color.isDark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '我',
          style: TextStyle(color: AppColors.textPrimary(theme.color.isDark)),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundStart(theme.color.isDark),
              AppColors.backgroundEnd(theme.color.isDark),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.only(
            top: kToolbarHeight + 40,
            left: 20,
            right: 20,
            bottom: 20,
          ),
          children: [
            _buildSettingSectionTitle('偏好设置', theme.color.isDark),
            _buildSwitchItem(
              title: '深色模式',
              icon: Icons.dark_mode_outlined,
              value: theme.color.isDark,
              onChanged: (val) {
                setState(() {
                  ChatUIKitTheme.instance.setColor(
                    val ? ChatUIKitColor.dark() : ChatUIKitColor.light(),
                  );
                });
                _settings.isDarkMode = val;
                _settings.saveSettings();
              },
              isDark: theme.color.isDark,
            ),
            const SizedBox(height: 20),
            _buildSettingSectionTitle('高级设置', theme.color.isDark),
            Container(
              decoration: BoxDecoration(
                color: AppColors.inputBackground(isDark),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: AppColors.glassBorder(theme.color.isDark),
                ),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.admin_panel_settings_outlined,
                  color: AppColors.textSecondary(theme.color.isDark),
                ),
                title: Text(
                  '服务器配置',
                  style: TextStyle(
                    color: AppColors.textPrimary(theme.color.isDark),
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary(theme.color.isDark),
                ),
                onTap: () => Navigator.pushNamed(context, '/settings'),
              ),
            ),
            const SizedBox(height: 10),
            _buildSwitchItem(
              title: '测试模式',
              icon: Icons.bug_report_outlined,
              value: _settings.isTestMode,
              onChanged: (val) {
                setState(() => _settings.isTestMode = val);
                _settings.saveSettings();
              },
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.inputBackground(theme.color.isDark),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: AppColors.glassBorder(theme.color.isDark),
                ),
              ),
              child: ListenableBuilder(
                listenable: VersionManager(),
                builder: (context, _) {
                  return ListTile(
                    leading: Icon(
                      Icons.info_outline,
                      color: AppColors.textSecondary(theme.color.isDark),
                    ),
                    title: Text(
                      '当前版本',
                      style: TextStyle(
                        color: AppColors.textPrimary(theme.color.isDark),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (VersionManager().hasNewVersion)
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
                            color: AppColors.textSecondary(theme.color.isDark),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      if (VersionManager().hasNewVersion) {
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
                // 调用环信退出
                try {
                  await EMClient.getInstance.logout();
                } catch (_) {}
                // 清除内存登录状态
                _settings.isLoggedIn = false;
                await _settings.saveSettings();
                // 跳转回登录页面
                if (mounted) {
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
        ),
      ),
    );
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
