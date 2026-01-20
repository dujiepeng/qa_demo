import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/test_pages/group/test_group_page.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_settings.dart';

/// 群组列表页面
class TestGroupListPage extends StatefulWidget {
  const TestGroupListPage({super.key});

  @override
  State<TestGroupListPage> createState() => _TestGroupListPageState();
}

class _TestGroupListPageState extends State<TestGroupListPage> {
  final _settings = AppSettings();
  final ScrollController _scrollController = ScrollController();
  List<EMGroup> _groups = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _pageNum = 0; // 群组分页从 0 开始
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _fetchGroups();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动监听，触发加载更多
  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isFetchingMore &&
        _hasMore) {
      _fetchMoreGroups();
    }
  }

  /// 获取群组列表（首次加载）
  Future<void> _fetchGroups() async {
    setState(() {
      _isLoading = true;
      _pageNum = 0;
      _hasMore = true;
    });

    try {
      final result = await EMClient.getInstance.groupManager
          .fetchJoinedGroupsFromServer(pageNum: _pageNum, pageSize: _pageSize);
      setState(() {
        _groups = result;
        _hasMore = result.length >= _pageSize;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('获取群组列表失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 加载更多群组
  Future<void> _fetchMoreGroups() async {
    if (_isFetchingMore || !_hasMore) return;

    setState(() {
      _isFetchingMore = true;
    });

    try {
      final nextP = _pageNum + 1;
      final result = await EMClient.getInstance.groupManager
          .fetchJoinedGroupsFromServer(pageNum: nextP, pageSize: _pageSize);

      setState(() {
        _groups.addAll(result);
        _pageNum = nextP;
        _hasMore = result.length >= _pageSize;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载更多失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingMore = false;
        });
      }
    }
  }

  /// 复制到剪贴板
  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已复制: $text'),
          duration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final isDark = _settings.isDarkMode;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              '群组列表',
              style: TextStyle(color: AppColors.textPrimary(isDark)),
            ),
            backgroundColor: AppColors.backgroundStart(isDark),
            iconTheme: IconThemeData(color: AppColors.textPrimary(isDark)),
            actions: [
              TextButton(
                child: Text(
                  'Join',
                  style: TextStyle(
                    color: AppColors.textPrimary(isDark),
                    fontSize: 14,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TestGroupPage()),
                  );
                },
              ),
            ],
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
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary(isDark),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchGroups,
                    child: _groups.isEmpty
                        ? Center(
                            child: Text(
                              '暂无加入的群组',
                              style: TextStyle(
                                color: AppColors.textSecondary(isDark),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: _groups.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index < _groups.length) {
                                final group = _groups[index];
                                return GestureDetector(
                                  onLongPressStart: (details) async {
                                    final position = details.globalPosition;
                                    final value = await showMenu<String>(
                                      context: context,
                                      position: RelativeRect.fromLTRB(
                                        position.dx,
                                        position.dy,
                                        position.dx,
                                        position.dy,
                                      ),
                                      items: [
                                        const PopupMenuItem(
                                          value: 'copy_id',
                                          child: Text('复制 ID'),
                                        ),
                                      ],
                                    );

                                    if (value == 'copy_id') {
                                      _copyToClipboard(group.groupId);
                                    }
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.inputBackground(isDark),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.glassBorder(isDark),
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary(
                                            isDark,
                                          ).withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.group_outlined,
                                          color: AppColors.primary(isDark),
                                        ),
                                      ),
                                      title: Text(
                                        group.name ?? '未命名群组',
                                        style: TextStyle(
                                          color: AppColors.textPrimary(isDark),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'ID: ${group.groupId}',
                                        style: TextStyle(
                                          color: AppColors.textSecondary(
                                            isDark,
                                          ),
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                      trailing: Icon(
                                        Icons.chevron_right,
                                        color: AppColors.textSecondary(isDark),
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => TestGroupPage(
                                              groupId: group.groupId,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              } else {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary(isDark),
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                  ),
          ),
        );
      },
    );
  }
}
