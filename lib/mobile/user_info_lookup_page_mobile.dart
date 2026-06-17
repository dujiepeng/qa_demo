import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';

import '../common/widgets/common_gradient_background.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';

typedef FetchUsersInfoCallback =
    Future<Map<String, EMUserInfo>> Function(List<String> userIds);

class UserInfoLookupPageMobile extends StatefulWidget {
  const UserInfoLookupPageMobile({super.key, this.fetchUsersInfo});

  final FetchUsersInfoCallback? fetchUsersInfo;

  @override
  State<UserInfoLookupPageMobile> createState() =>
      _UserInfoLookupPageMobileState();
}

class _UserInfoLookupPageMobileState extends State<UserInfoLookupPageMobile> {
  final _userIdsController = TextEditingController();
  bool _isLoading = false;
  List<String> _queriedIds = const [];
  Map<String, EMUserInfo> _results = const {};
  String? _errorText;

  @override
  void dispose() {
    _userIdsController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsersInfo() async {
    final userIds = _parseUserIds(_userIdsController.text);
    if (userIds.isEmpty) {
      _showMessage('请输入用户 ID');
      return;
    }
    if (userIds.length > 100) {
      _showMessage('每次查询的用户 ID 数量不能超过 100 个');
      return;
    }

    setState(() {
      _isLoading = true;
      _queriedIds = userIds;
      _results = const {};
      _errorText = null;
    });

    try {
      final results =
          await (widget.fetchUsersInfo ?? _defaultFetchUsersInfo).call(userIds);
      if (!mounted) {
        return;
      }
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = '查询用户属性失败: $e';
        _isLoading = false;
      });
      _showMessage(_errorText!);
    }
  }

  Future<Map<String, EMUserInfo>> _defaultFetchUsersInfo(List<String> userIds) {
    return EMClient.getInstance.userInfoManager.fetchUserInfoById(userIds);
  }

  List<String> _parseUserIds(String rawText) {
    final seen = <String>{};
    final userIds = <String>[];
    final parts = rawText
        .split(RegExp(r'[\s,，;；]+'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty);
    for (final part in parts) {
      if (seen.add(part)) {
        userIds.add(part);
      }
    }
    return userIds;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
          title: Text(
            '查询用户属性',
            style: TextStyle(color: AppColors.textPrimary(isDark)),
          ),
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.textPrimary(isDark)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildInputPanel(isDark),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorText != null)
              _StatusCard(text: _errorText!, isDark: isDark)
            else if (_queriedIds.isEmpty)
              _StatusCard(text: '输入用户 ID 后查询用户属性', isDark: isDark)
            else
              ..._queriedIds.map(
                (userId) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _UserInfoResultCard(
                    userId: userId,
                    userInfo: _results[userId],
                    isDark: isDark,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputPanel(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inputBackground(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _userIdsController,
            minLines: 3,
            maxLines: 6,
            style: TextStyle(color: AppColors.textPrimary(isDark)),
            decoration: InputDecoration(
              labelText: '用户 ID',
              hintText: 'qa01, qa02\n或每行一个用户 ID',
              labelStyle: TextStyle(color: AppColors.textSecondary(isDark)),
              hintStyle: TextStyle(color: AppColors.textSecondary(isDark)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.glassBorder(isDark)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary(isDark)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _fetchUsersInfo,
            icon: const Icon(Icons.manage_search_outlined),
            label: Text(_isLoading ? '查询中...' : '查询'),
          ),
        ],
      ),
    );
  }
}

class _UserInfoResultCard extends StatelessWidget {
  const _UserInfoResultCard({
    required this.userId,
    required this.userInfo,
    required this.isDark,
  });

  final String userId;
  final EMUserInfo? userInfo;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inputBackground(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userId,
            style: TextStyle(
              color: AppColors.textPrimary(isDark),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          if (userInfo == null)
            Text(
              '未返回属性',
              style: TextStyle(color: AppColors.textSecondary(isDark)),
            )
          else ...[
            _InfoLine(label: '昵称', value: userInfo!.nickName, isDark: isDark),
            _InfoLine(label: '头像', value: userInfo!.avatarUrl, isDark: isDark),
            _InfoLine(label: '邮箱', value: userInfo!.mail, isDark: isDark),
            _InfoLine(label: '手机号', value: userInfo!.phone, isDark: isDark),
            _InfoLine(
              label: '性别',
              value: _genderText(userInfo!.gender),
              isDark: isDark,
            ),
            _InfoLine(label: '签名', value: userInfo!.sign, isDark: isDark),
            _InfoLine(label: '生日', value: userInfo!.birth, isDark: isDark),
            _InfoLine(label: '扩展', value: userInfo!.ext, isDark: isDark),
          ],
        ],
      ),
    );
  }

  String _genderText(int gender) {
    switch (gender) {
      case 1:
        return '男';
      case 2:
        return '女';
      default:
        return '未知';
    }
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String? value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final displayValue = value == null || value!.trim().isEmpty
        ? '未设置'
        : value!.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        '$label: $displayValue',
        style: TextStyle(color: AppColors.textSecondary(isDark), height: 1.35),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.text, required this.isDark});

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inputBackground(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder(isDark)),
      ),
      child: Text(
        text,
        style: TextStyle(color: AppColors.textSecondary(isDark)),
      ),
    );
  }
}
