import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';

import '../common/widgets/common_gradient_background.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';
import 'my_models.dart';

typedef FetchOwnInfoCallback = Future<EMUserInfo?> Function();
typedef UpdateOwnInfoCallback =
    Future<EMUserInfo> Function({
      String? nickname,
      String? avatarUrl,
      String? birth,
      String? mail,
      String? phone,
      int? gender,
      String? sign,
      String? ext,
    });

class MyUserProfilePageMobile extends StatefulWidget {
  const MyUserProfilePageMobile({
    super.key,
    required this.initialProfile,
    this.onProfileSaved,
    this.fetchOwnInfo,
    this.updateOwnInfo,
  });

  final MyUserProfile initialProfile;
  final ValueChanged<MyUserProfile>? onProfileSaved;
  final FetchOwnInfoCallback? fetchOwnInfo;
  final UpdateOwnInfoCallback? updateOwnInfo;

  @override
  State<MyUserProfilePageMobile> createState() =>
      _MyUserProfilePageMobileState();
}

class _MyUserProfilePageMobileState extends State<MyUserProfilePageMobile> {
  final _nicknameController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _genderController = TextEditingController();
  final _signController = TextEditingController();
  final _extController = TextEditingController();

  late MyUserProfile _profile;
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    _syncControllers();
    _loadOwnInfo();
  }

  Future<void> _loadOwnInfo() async {
    try {
      final userInfo = await (widget.fetchOwnInfo ?? _defaultFetchOwnInfo)
          .call();
      if (!mounted) {
        return;
      }
      if (userInfo != null) {
        _profile = _mapUserInfo(userInfo);
        _syncControllers();
      }
    } catch (e) {
      debugPrint('Failed to fetch own user info: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<EMUserInfo?> _defaultFetchOwnInfo() {
    return EMClient.getInstance.userInfoManager.fetchOwnInfo();
  }

  MyUserProfile _mapUserInfo(EMUserInfo userInfo) {
    return MyUserProfile(
      nickname: userInfo.nickName?.trim().isNotEmpty == true
          ? userInfo.nickName!.trim()
          : '未设置',
      avatarUrl: userInfo.avatarUrl?.trim() ?? '',
      birthday: userInfo.birth?.trim() ?? '',
      email: userInfo.mail?.trim() ?? '',
      phone: userInfo.phone?.trim() ?? '',
      gender: userInfo.gender,
      sign: userInfo.sign?.trim() ?? '',
      ext: userInfo.ext?.trim() ?? '',
    );
  }

  MyUserProfile _mergeUserInfo(
    EMUserInfo userInfo, {
    required MyUserProfile fallback,
  }) {
    final nickname = userInfo.nickName?.trim();
    final avatarUrl = userInfo.avatarUrl?.trim();
    final birth = userInfo.birth?.trim();
    final mail = userInfo.mail?.trim();
    final phone = userInfo.phone?.trim();
    final sign = userInfo.sign?.trim();
    final ext = userInfo.ext?.trim();
    return MyUserProfile(
      nickname: nickname?.isNotEmpty == true ? nickname! : fallback.nickname,
      avatarUrl: avatarUrl?.isNotEmpty == true
          ? avatarUrl!
          : fallback.avatarUrl,
      birthday: birth?.isNotEmpty == true ? birth! : fallback.birthday,
      email: mail?.isNotEmpty == true ? mail! : fallback.email,
      phone: phone?.isNotEmpty == true ? phone! : fallback.phone,
      gender: userInfo.gender == 0 ? fallback.gender : userInfo.gender,
      sign: sign?.isNotEmpty == true ? sign! : fallback.sign,
      ext: ext?.isNotEmpty == true ? ext! : fallback.ext,
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _avatarUrlController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _genderController.dispose();
    _signController.dispose();
    _extController.dispose();
    super.dispose();
  }

  void _syncControllers() {
    _nicknameController.text = _profile.nickname;
    _avatarUrlController.text = _profile.avatarUrl;
    _ageController.text = _profile.birthday;
    _emailController.text = _profile.email;
    _phoneController.text = _profile.phone;
    _genderController.text = _profile.gender.toString();
    _signController.text = _profile.sign;
    _extController.text = _profile.ext;
  }

  Future<EMUserInfo> _defaultUpdateOwnInfo({
    String? nickname,
    String? avatarUrl,
    String? birth,
    String? mail,
    String? phone,
    int? gender,
    String? sign,
    String? ext,
  }) {
    return EMClient.getInstance.userInfoManager.updateUserInfo(
      nickname: nickname,
      avatarUrl: avatarUrl,
      birth: birth,
      mail: mail,
      phone: phone,
      gender: gender,
      sign: sign,
      ext: ext,
    );
  }

  Future<void> _toggleEditOrSave() async {
    if (!_isEditing) {
      setState(() {
        _isEditing = true;
      });
      return;
    }

    final birthday = _ageController.text.trim();
    final email = _emailController.text.trim();
    final gender = int.tryParse(_genderController.text.trim());
    if (gender == null || gender < 0 || gender > 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('性别只能填写 0、1 或 2')));
      return;
    }
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (email.isEmpty || !emailPattern.hasMatch(email)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('邮箱格式不正确')));
      return;
    }

    final nextProfile = MyUserProfile(
      nickname: _nicknameController.text.trim(),
      avatarUrl: _avatarUrlController.text.trim(),
      birthday: birthday,
      email: email,
      phone: _phoneController.text.trim(),
      gender: gender,
      sign: _signController.text.trim(),
      ext: _extController.text.trim(),
    );
    setState(() {
      _isSaving = true;
    });

    try {
      final updatedUserInfo =
          await (widget.updateOwnInfo ?? _defaultUpdateOwnInfo).call(
            nickname: nextProfile.nickname,
            avatarUrl: nextProfile.avatarUrl,
            birth: nextProfile.birthday,
            mail: nextProfile.email,
            phone: nextProfile.phone,
            gender: nextProfile.gender,
            sign: nextProfile.sign,
            ext: nextProfile.ext,
          );
      if (!mounted) {
        return;
      }

      var savedProfile = _mergeUserInfo(updatedUserInfo, fallback: nextProfile);
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = savedProfile;
        _isEditing = false;
        _isSaving = false;
        _syncControllers();
      });
      widget.onProfileSaved?.call(savedProfile);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('用户信息已保存')));
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存用户信息失败: $e')));
    }
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
          title: Text(
            '用户信息',
            style: TextStyle(color: AppColors.textPrimary(isDark)),
          ),
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.textPrimary(isDark)),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : _toggleEditOrSave,
              child: Text(
                _isSaving
                    ? '保存中...'
                    : _isEditing
                    ? '保存'
                    : '编辑',
                style: TextStyle(
                  color: AppColors.primary(isDark),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
            _ProfileFieldCard(
              label: '昵称',
              controller: _nicknameController,
              value: _profile.nickname,
              enabled: _isEditing,
            ),
            _ProfileFieldCard(
              label: '头像',
              controller: _avatarUrlController,
              value: _profile.avatarUrl,
              enabled: _isEditing,
              keyboardType: TextInputType.url,
            ),
            _ProfileFieldCard(
              label: '生日',
              controller: _ageController,
              value: _profile.birthday,
              enabled: _isEditing,
              keyboardType: TextInputType.datetime,
            ),
            _ProfileFieldCard(
              label: '邮箱',
              controller: _emailController,
              value: _profile.email,
              enabled: _isEditing,
              keyboardType: TextInputType.emailAddress,
            ),
            _ProfileFieldCard(
              label: '手机号',
              controller: _phoneController,
              value: _profile.phone,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
            ),
            _ProfileFieldCard(
              label: '性别',
              controller: _genderController,
              value: _genderText(_profile.gender),
              enabled: _isEditing,
              keyboardType: TextInputType.number,
            ),
            _ProfileFieldCard(
              label: '签名',
              controller: _signController,
              value: _profile.sign,
              enabled: _isEditing,
            ),
            _ProfileFieldCard(
              label: '扩展',
              controller: _extController,
              value: _profile.ext,
              enabled: _isEditing,
            ),
          ],
        ),
      ),
    );
  }

  String _genderText(int gender) {
    switch (gender) {
      case 1:
        return '男 (1)';
      case 2:
        return '女 (2)';
      default:
        return '未知 (0)';
    }
  }
}

class _ProfileFieldCard extends StatelessWidget {
  const _ProfileFieldCard({
    required this.label,
    required this.controller,
    required this.value,
    required this.enabled,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String value;
  final bool enabled;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final isDark = AppSettings().isDarkMode;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputBackground(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary(isDark),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          if (enabled)
            TextField(
              key: ValueKey('profile_field_$label'),
              controller: controller,
              keyboardType: keyboardType,
              style: TextStyle(color: AppColors.textPrimary(isDark)),
              decoration: InputDecoration(
                isDense: true,
                hintText: '请输入$label',
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.glassBorder(isDark)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary(isDark)),
                ),
              ),
            )
          else
            Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
