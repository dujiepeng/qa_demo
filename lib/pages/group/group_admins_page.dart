import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_settings.dart';

typedef GroupAdminsGroupInfoLoader = Future<EMGroup> Function(String groupId);
typedef GroupAdminRemover = Future<void> Function(
  String groupId,
  String adminId,
);

/// 群组管理员列表页面
class GroupAdminsPage extends StatefulWidget {
  const GroupAdminsPage({
    super.key,
    required this.groupId,
    this.groupInfoLoader,
    this.adminRemover,
  });

  final String groupId;
  final GroupAdminsGroupInfoLoader? groupInfoLoader;
  final GroupAdminRemover? adminRemover;

  @override
  State<GroupAdminsPage> createState() => _GroupAdminsPageState();
}

class _GroupAdminsPageState extends State<GroupAdminsPage> {
  final _settings = AppSettings();
  final _scrollController = ScrollController();
  List<String> _members = [];
  bool _isLoading = false;
  String? _errorMessage;
  EMGroupPermissionType? _permissionType;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 获取群组管理员列表
  Future<void> _fetchMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 获取群组信息
      final result = await _fetchGroupInfo();

      setState(() {
        _members = result.adminList ?? [];
        _permissionType = result.permissionType;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<EMGroup> _fetchGroupInfo() {
    final loader = widget.groupInfoLoader;
    if (loader != null) {
      return loader(widget.groupId);
    }
    return EMClient.getInstance.groupManager.fetchGroupInfoFromServer(
      widget.groupId,
    );
  }

  /// 显示成员操作菜单
  void _showMemberActions(String memberId, bool isDark) {
    final canRemoveAdmin = _permissionType == EMGroupPermissionType.Owner;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        title: Text(
          '成员操作',
          style: TextStyle(
            color: AppColors.textPrimary(isDark),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),
            Divider(height: 1, color: AppColors.glassBorder(isDark)),

            if (canRemoveAdmin)
              // 移除管理员
              ListTile(
                leading: Icon(
                  Icons.admin_panel_settings_outlined,
                  color: AppColors.primary(isDark),
                ),
                title: Text(
                  '移除管理员',
                  style: TextStyle(color: AppColors.textPrimary(isDark)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removeAdmin(memberId);
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: TextStyle(color: AppColors.textSecondary(isDark)),
            ),
          ),
        ],
      ),
    );
  }

  /// 移除管理员
  Future<void> _removeAdmin(String memberId) async {
    try {
      final remover = widget.adminRemover;
      if (remover != null) {
        await remover(widget.groupId, memberId);
      } else {
        await EMClient.getInstance.groupManager.removeAdmin(
          widget.groupId,
          memberId,
        );
      }
      final result = await _fetchGroupInfo();
      final admins = result.adminList ?? [];
      if (mounted) {
        setState(() {
          _members = admins;
          _permissionType = result.permissionType;
          _isLoading = false;
        });
        if (admins.contains(memberId)) {
          _showResultDialog('移除 $memberId 管理员失败: 服务端管理员列表仍包含该成员', false);
        } else {
          _showResultDialog('移除 $memberId 管理员成功', true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showResultDialog('移除 $memberId 管理员失败: ${e.toString()}', false);
      }
    }
  }

  /// 显示操作结果对话框
  void _showResultDialog(String message, bool isSuccess) {
    final isDark = _settings.isDarkMode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: AppColors.textPrimary(isDark)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '确定',
              style: TextStyle(color: AppColors.primary(isDark)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _settings.isDarkMode;

    return Column(
      children: [
        // 顶部标题栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.glassBorder(isDark),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '管理员 (${_members.length})',
                style: TextStyle(
                  color: AppColors.textPrimary(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.refresh, color: AppColors.primary(isDark)),
                    onPressed: _isLoading ? null : _fetchMembers,
                    tooltip: '刷新',
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: AppColors.textSecondary(isDark),
                    ),
                    onPressed: () => Navigator.pop(context),
                    tooltip: '关闭',
                  ),
                ],
              ),
            ],
          ),
        ),

        // 成员列表
        Expanded(child: _buildContent(isDark)),
      ],
    );
  }

  Widget _buildContent(bool isDark) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primary(isDark)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.textSecondary(isDark),
            ),
            const SizedBox(height: 16),
            Text(
              '获取管理员列表失败',
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: AppColors.textSecondary(isDark),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchMembers,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary(isDark),
                foregroundColor: Colors.white,
              ),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings_outlined,
              size: 64,
              color: AppColors.textSecondary(isDark),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无管理员',
              style: TextStyle(
                color: AppColors.textSecondary(isDark),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.inputBackground(isDark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.glassBorder(isDark)),
          ),
          child: ListTile(
            onTap: () => _showMemberActions(member, isDark),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary(isDark),
              child: Text(
                member.isNotEmpty ? member[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              member,
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              'ID: $member',
              style: TextStyle(
                color: AppColors.textSecondary(isDark),
                fontSize: 12,
              ),
            ),
          ),
        );
      },
    );
  }
}
