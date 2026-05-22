import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_settings.dart';

typedef RoomBlockListLoader =
    Future<List<String>> Function(
      String roomId, {
      int pageNum,
      int pageSize,
    });
typedef RoomMemberUnblocker =
    Future<void> Function(String roomId, List<String> members);

class RoomBlockListPage extends StatefulWidget {
  const RoomBlockListPage({
    super.key,
    required this.roomId,
    this.blockListLoader,
    this.memberUnblocker,
  });

  final String roomId;
  final RoomBlockListLoader? blockListLoader;
  final RoomMemberUnblocker? memberUnblocker;

  @override
  State<RoomBlockListPage> createState() => _RoomBlockListPageState();
}

class _RoomBlockListPageState extends State<RoomBlockListPage> {
  static const _pageSize = 50;
  final _settings = AppSettings();
  final _scrollController = ScrollController();
  final List<String> _members = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _nextPageNum = 1;
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

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<List<String>> _loadBlockListPage(int pageNum) {
    final loader = widget.blockListLoader;
    if (loader != null) {
      return loader(widget.roomId, pageNum: pageNum, pageSize: _pageSize);
    }
    return EMClient.getInstance.chatRoomManager.fetchChatRoomBlockList(
      widget.roomId,
      pageNum: pageNum,
      pageSize: _pageSize,
    );
  }

  Future<void> _fetchMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _nextPageNum = 1;
      _hasMore = true;
    });

    try {
      final result = await _loadBlockListPage(1);
      if (!mounted) return;
      setState(() {
        _members
          ..clear()
          ..addAll(result);
        _nextPageNum = 2;
        _hasMore = result.length >= _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final pageNum = _nextPageNum;
    try {
      final result = await _loadBlockListPage(pageNum);
      if (!mounted) return;
      setState(() {
        _members.addAll(result);
        _nextPageNum = pageNum + 1;
        _hasMore = result.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

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
            ListTile(
              leading: Icon(
                Icons.person_add_alt_1_outlined,
                color: AppColors.primary(isDark),
              ),
              title: Text(
                '移出黑名单',
                style: TextStyle(color: AppColors.textPrimary(isDark)),
              ),
              onTap: () {
                Navigator.pop(context);
                _removeFromBlockList(memberId);
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

  Future<void> _removeFromBlockList(String memberId) async {
    try {
      final unblocker = widget.memberUnblocker;
      if (unblocker != null) {
        await unblocker(widget.roomId, [memberId]);
      } else {
        await EMClient.getInstance.chatRoomManager.unBlockChatRoomMembers(
          widget.roomId,
          [memberId],
        );
      }
      if (!mounted) return;
      await _fetchMembers();
      if (mounted) {
        _showResultDialog('已将 $memberId 移出黑名单', true);
      }
    } catch (e) {
      if (mounted) {
        _showResultDialog('移出黑名单失败: ${e.toString()}', false);
      }
    }
  }

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
                '黑名单 (${_members.length})',
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
              '获取黑名单失败',
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
              Icons.block_outlined,
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
            leading: const CircleAvatar(
              backgroundColor: Colors.red,
              child: Icon(Icons.block_outlined, color: Colors.white),
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
