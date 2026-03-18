import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_settings.dart';
import '../utils/version_manager.dart';
import 'update_dialog.dart';
import 'common_gradient_background.dart';

class MePageContent extends StatelessWidget {
  final bool showAppBar;
  const MePageContent({super.key, this.showAppBar = false});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final isDark = settings.isDarkMode;

    Widget body = ListView(
      padding: EdgeInsets.only(
        top:
            MediaQuery.of(context).padding.top +
            (showAppBar ? kToolbarHeight + 20 : 40),
        left: 20,
        right: 20,
        bottom: 20,
      ),
      children: [

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
            onTap: () => Navigator.pushNamed(context, '/server_config'),
          ),
        ),
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

    Widget content = CommonGradientBackground(isDark: isDark, child: body);

    if (showAppBar) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            color: AppColors.textPrimary(isDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            '设置',
            style: TextStyle(color: AppColors.textPrimary(isDark)),
          ),
          centerTitle: true,
        ),
        body: content,
      );
    } else {
      return Scaffold(backgroundColor: Colors.transparent, body: content);
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
}
