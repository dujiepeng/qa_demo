import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_settings.dart';

/// 群组禁言列表页面
class TestGroupMuteListPage extends StatefulWidget {
  const TestGroupMuteListPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<TestGroupMuteListPage> createState() => _TestGroupMuteListPageState();
}

class _TestGroupMuteListPageState extends State<TestGroupMuteListPage> {
  final _settings = AppSettings();
  final _scrollController = ScrollController();
  List<String> _members = [];
  Map<String, int> _muteMap = {}; // 用户ID -> 禁言时长(毫秒)
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _pageNum = 1;
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

  /// 获取群组禁言列表
  Future<void> _fetchMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _pageNum = 1;
      _hasMore = true;
    });

    try {
      // 获取群组禁言列表
      final result = await EMClient.getInstance.groupManager
          .fetchMuteListFromServer(
            widget.groupId,
            pageNum: _pageNum,
            pageSize: 50,
          );

      setState(() {
        _muteMap = result;
        _members = result.keys.toList();
        _pageNum += 1;
        // 如果返回的数据少于请求的数量，说明没有更多数据了
        _hasMore = result.length >= 50;
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
      // 增加页码
      _pageNum++;

      final result = await EMClient.getInstance.groupManager
          .fetchMuteListFromServer(
            widget.groupId,
            pageNum: _pageNum,
            pageSize: 50,
          );

      setState(() {
        _muteMap.addAll(result);
        _members.addAll(result.keys);
        // 如果返回的数据少于请求的数量，说明没有更多数据了
        _hasMore = result.length >= 50;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        // 加载失败时回退页码
        _pageNum--;
        _isLoadingMore = false;
      });
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

            // 移除禁言
            ListTile(
              leading: Icon(
                Icons.mic_outlined,
                color: AppColors.primary(isDark),
              ),
              title: Text(
                '移除禁言',
                style: TextStyle(color: AppColors.textPrimary(isDark)),
              ),
              onTap: () {
                Navigator.pop(context);
                _removeMute(memberId);
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

  /// 移除禁言
  Future<void> _removeMute(String memberId) async {
    try {
      await EMClient.getInstance.groupManager.unMuteMembers(widget.groupId, [
        memberId,
      ]);
      if (mounted) {
        _fetchMembers();
        _showResultDialog('移除 $memberId 禁言成功', true);
      }
    } catch (e) {
      if (mounted) {
        _showResultDialog('移除 $memberId 禁言失败: ${e.toString()}', false);
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

  /// 格式化禁言时长
  String _formatMuteDuration(int milliseconds) {
    if (milliseconds <= 0) {
      return '永久禁言';
    }

    final duration = Duration(milliseconds: milliseconds);
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) {
      return '$days天$hours小时';
    } else if (hours > 0) {
      return '$hours小时$minutes分钟';
    } else if (minutes > 0) {
      return '$minutes分钟';
    } else {
      return '少于1分钟';
    }
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
                '禁言列表 (${_members.length})',
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
              '获取禁言列表失败',
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
              Icons.mic_off_outlined,
              size: 64,
              color: AppColors.textSecondary(isDark),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无禁言成员',
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ID: $member',
                  style: TextStyle(
                    color: AppColors.textSecondary(isDark),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '禁言时长: ${_formatMuteDuration(_muteMap[member] ?? 0)}',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
