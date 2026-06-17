import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';

import '../common/widgets/common_gradient_background.dart';
import '../common/widgets/input_dialog.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';
import 'my_devices_page_mobile.dart';
import 'my_models.dart';
import 'my_user_profile_page_mobile.dart';
import 'push_settings_page_mobile.dart';
import 'user_info_lookup_page_mobile.dart';

typedef UpdatePushNicknameCallback = Future<void> Function(String nickname);

class MyPageMobile extends StatefulWidget {
  const MyPageMobile({super.key, this.updatePushNickname});

  final UpdatePushNicknameCallback? updatePushNickname;

  @override
  State<MyPageMobile> createState() => _MyPageMobileState();
}

class _MyPageMobileState extends State<MyPageMobile> {
  String _pushNickname = '未设置';
  MyUserProfile _profile = const MyUserProfile(
    nickname: 'QA用户',
    birthday: '2000-01-01',
    email: 'qa@example.com',
  );

  Future<void> _editPushNickname() async {
    final result = await showInputDialog(
      context: context,
      title: '设置推送昵称',
      fields: [
        InputFieldData(
          title: '推送昵称',
          placeholder: '请输入推送昵称',
          text: _pushNickname == '未设置' ? '' : _pushNickname,
        ),
      ],
    );
    if (!mounted || result == null || result.isEmpty) {
      return;
    }
    final nickname = result.first.text.trim();
    try {
      if (nickname.isNotEmpty) {
        await (widget.updatePushNickname ?? _updatePushNicknameFromSdk).call(
          nickname,
        );
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _pushNickname = nickname.isEmpty ? '未设置' : nickname;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('推送昵称已更新')));
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('推送昵称更新失败: $e')));
    }
  }

  Future<void> _updatePushNicknameFromSdk(String nickname) {
    return EMClient.getInstance.pushManager.updatePushNickname(nickname);
  }

  Future<void> _openUserProfilePage() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MyUserProfilePageMobile(
          initialProfile: _profile,
          onProfileSaved: (profile) {
            setState(() {
              _profile = profile;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppSettings().isDarkMode;

    return CommonGradientBackground(
      isDark: isDark,
      child: Scaffold(
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
            '我的',
            style: TextStyle(color: AppColors.textPrimary(isDark)),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _MyActionCell(
                icon: Icons.devices_outlined,
                title: '登录的其他设备',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MyDevicesPageMobile(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _MyActionCell(
                icon: Icons.notifications_active_outlined,
                title: '设置推送昵称',
                onTap: _editPushNickname,
              ),
              const SizedBox(height: 12),
              _MyActionCell(
                icon: Icons.tune_outlined,
                title: '推送设置',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PushSettingsPageMobile(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _MyActionCell(
                icon: Icons.badge_outlined,
                title: '设置用户信息',
                onTap: _openUserProfilePage,
              ),
              const SizedBox(height: 12),
              _MyActionCell(
                icon: Icons.manage_accounts_outlined,
                title: '查询用户属性',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const UserInfoLookupPageMobile(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyActionCell extends StatelessWidget {
  const _MyActionCell({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppSettings().isDarkMode;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder(isDark)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary(isDark).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary(isDark)),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary(isDark),
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary(isDark),
        ),
      ),
    );
  }
}
