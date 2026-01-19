import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/test_pages/test_chat_room_page.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';

class TestChatRoomListPage extends StatefulWidget {
  const TestChatRoomListPage({super.key});

  @override
  State<TestChatRoomListPage> createState() => _TestChatRoomListPageState();
}

class _TestChatRoomListPageState extends State<TestChatRoomListPage> {
  final _settings = AppSettings();
  final ScrollController _scrollController = ScrollController();
  List<EMChatRoom> _chatRooms = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _pageNum = 1;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _fetchChatRooms();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isFetchingMore &&
        _hasMore) {
      _fetchMoreChatRooms();
    }
  }

  Future<void> _fetchChatRooms() async {
    setState(() {
      _isLoading = true;
      _pageNum = 1;
      _hasMore = true;
    });

    try {
      final result = await EMClient.getInstance.chatRoomManager
          .fetchPublicChatRoomsFromServer(
            pageNum: _pageNum,
            pageSize: _pageSize,
          );
      setState(() {
        _chatRooms = result.data;
        _hasMore = result.data.length >= _pageSize;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('获取聊天室列表失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMoreChatRooms() async {
    if (_isFetchingMore || !_hasMore) return;

    setState(() {
      _isFetchingMore = true;
    });

    try {
      final nextP = _pageNum + 1;
      final result = await EMClient.getInstance.chatRoomManager
          .fetchPublicChatRoomsFromServer(pageNum: nextP, pageSize: _pageSize);

      setState(() {
        final newData = result.data;
        _chatRooms.addAll(newData);
        _pageNum = nextP;
        _hasMore = newData.length >= _pageSize;
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
              '聊天室列表',
              style: TextStyle(color: AppColors.textPrimary(isDark)),
            ),
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
                    MaterialPageRoute(builder: (context) => TestChatRoomPage()),
                  );
                },
              ),
            ],
            backgroundColor: AppColors.backgroundStart(isDark),
            iconTheme: IconThemeData(color: AppColors.textPrimary(isDark)),
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
                    onRefresh: _fetchChatRooms,
                    child: _chatRooms.isEmpty
                        ? Center(
                            child: Text(
                              '暂无公开聊天室',
                              style: TextStyle(
                                color: AppColors.textSecondary(isDark),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: _chatRooms.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index < _chatRooms.length) {
                                final room = _chatRooms[index];
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
                                      _copyToClipboard(room.roomId);
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
                                          Icons.meeting_room_outlined,
                                          color: AppColors.primary(isDark),
                                        ),
                                      ),
                                      title: Text(
                                        room.name ?? '未命名聊天室',
                                        style: TextStyle(
                                          color: AppColors.textPrimary(isDark),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'ID: ${room.roomId}',
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
                                            builder: (context) =>
                                                TestChatRoomPage(
                                                  roomId: room.roomId,
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
