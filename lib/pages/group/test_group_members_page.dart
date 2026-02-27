import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_settings.dart';

/// 群组成员列表页面
class TestGroupMembersPage extends StatefulWidget {
  const TestGroupMembersPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<TestGroupMembersPage> createState() => _TestGroupMembersPageState();
}

class _TestGroupMembersPageState extends State<TestGroupMembersPage> {
  final _settings = AppSettings();
  final _scrollController = ScrollController();
  List<String> _members = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String _cursor = '';
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动监听
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  /// 添加成员
  Future<void> _addMembers() async {
    final isDark = _settings.isDarkMode;
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        title: Text(
          '添加成员',
          style: TextStyle(
            color: AppColors.textPrimary(isDark),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: AppColors.textPrimary(isDark)),
          decoration: InputDecoration(
            hintText: '请输入成员 ID',
            hintStyle: TextStyle(color: AppColors.textSecondary(isDark)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.glassBorder(isDark)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary(isDark)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: TextStyle(color: AppColors.textSecondary(isDark)),
            ),
          ),
          TextButton(
            onPressed: () {
              final input = controller.text.trim();
              if (input.isNotEmpty) {
                Navigator.pop(context, input);
              }
            },
            child: Text(
              '确认',
              style: TextStyle(color: AppColors.primary(isDark)),
            ),
          ),
        ],
      ),
    );

    // 处理输入结果
    if (result != null && result.isNotEmpty) {
      try {
        await EMClient.getInstance.groupManager.addMembers(widget.groupId, [
          result,
        ]);
        if (mounted) {
          _showResultDialog('已添加成员 $result', true);
          // 刷新成员列表
          _fetchMembers();
        }
      } catch (e) {
        if (mounted) {
          _showResultDialog('添加成员失败: ${e.toString()}', false);
        }
      }
    }
  }

  /// 获取群组成员列表
  Future<void> _fetchMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _cursor = '';
      _hasMore = true;
    });

    try {
      // 获取群组成员列表
      final result = await EMClient.getInstance.groupManager
          .fetchMemberListFromServer(widget.groupId, pageSize: 50, cursor: '');

      setState(() {
        _members = result.data;
        _cursor = result.cursor ?? '';
        _hasMore = _cursor.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 加载更多成员
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final result = await EMClient.getInstance.groupManager
          .fetchMemberListFromServer(
            widget.groupId,
            pageSize: 50,
            cursor: _cursor,
          );

      setState(() {
        _members.addAll(result.data);
        _cursor = result.cursor ?? '';
        _hasMore = _cursor.isNotEmpty;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      // 加载更多失败时显示提示
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载更多失败: ${e.toString()}')));
      }
    }
  }

  /// 显示成员操作菜单
  void _showMemberActions(String memberId, bool isDark) {
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
            Divider(height: 1, color: AppColors.glassBorder(isDark)),

            // 设置管理员
            ListTile(
              leading: Icon(
                Icons.admin_panel_settings_outlined,
                color: AppColors.primary(isDark),
              ),
              title: Text(
                '设置管理员',
                style: TextStyle(color: AppColors.textPrimary(isDark)),
              ),
              onTap: () {
                Navigator.pop(context);
                _setAdmin(memberId);
              },
            ),

            // 禁言
            ListTile(
              leading: Icon(
                Icons.mic_off_outlined,
                color: AppColors.primary(isDark),
              ),
              title: Text(
                '禁言',
                style: TextStyle(color: AppColors.textPrimary(isDark)),
              ),
              onTap: () {
                Navigator.pop(context);
                _muteMember(memberId);
              },
            ),

            // 加入白名单
            ListTile(
              leading: Icon(
                Icons.verified_user_outlined,
                color: AppColors.primary(isDark),
              ),
              title: Text(
                '加入白名单',
                style: TextStyle(color: AppColors.textPrimary(isDark)),
              ),
              onTap: () {
                Navigator.pop(context);
                _addToWhitelist(memberId);
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

  /// 设置管理员
  Future<void> _setAdmin(String memberId) async {
    try {
      await EMClient.getInstance.groupManager.addAdmin(
        widget.groupId,
        memberId,
      );
      if (mounted) {
        _showResultDialog('已设置 $memberId 为管理员', true);
      }
    } catch (e) {
      if (mounted) {
        _showResultDialog('设置管理员失败: ${e.toString()}', false);
      }
    }
  }

  /// 禁言成员
  Future<void> _muteMember(String memberId) async {
    try {
      await EMClient.getInstance.groupManager.muteMembers(widget.groupId, [
        memberId,
      ]);
      if (mounted) {
        _showResultDialog('已禁言 $memberId', true);
      }
    } catch (e) {
      if (mounted) {
        _showResultDialog('禁言失败: ${e.toString()}', false);
      }
    }
  }

  /// 加入白名单
  Future<void> _addToWhitelist(String memberId) async {
    try {
      await EMClient.getInstance.groupManager.addAllowList(widget.groupId, [
        memberId,
      ]);
      if (mounted) {
        _showResultDialog('已将 $memberId 加入白名单', true);
      }
    } catch (e) {
      if (mounted) {
        _showResultDialog('加入白名单失败: ${e.toString()}', false);
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
                '群组成员 (${_members.length})',
                style: TextStyle(
                  color: AppColors.textPrimary(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.add, color: AppColors.primary(isDark)),
                    onPressed: _isLoading ? null : _addMembers,
                    tooltip: '添加',
                  ),
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
              '获取成员列表失败',
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
              Icons.people_outline,
              size: 64,
              color: AppColors.textSecondary(isDark),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无成员',
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
      itemCount: _members.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // 显示加载更多指示器
        if (index == _members.length) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            child: _isLoadingMore
                ? CircularProgressIndicator(color: AppColors.primary(isDark))
                : Text(
                    '加载更多...',
                    style: TextStyle(
                      color: AppColors.textSecondary(isDark),
                      fontSize: 12,
                    ),
                  ),
          );
        }

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
