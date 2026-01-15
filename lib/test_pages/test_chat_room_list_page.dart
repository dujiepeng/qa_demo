import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';

class TestChatRoomListPage extends StatefulWidget {
  const TestChatRoomListPage({super.key});

  @override
  State<TestChatRoomListPage> createState() => _TestChatRoomListPageState();
}

class _TestChatRoomListPageState extends State<TestChatRoomListPage> {
  final _settings = AppSettings();
  List<EMChatRoom> _chatRooms = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchChatRooms();
  }

  Future<void> _fetchChatRooms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 获取页码为1，每页20条数据（可根据需要调整）
      final result = await EMClient.getInstance.chatRoomManager
          .fetchPublicChatRoomsFromServer(pageNum: 1, pageSize: 50);
      setState(() {
        _chatRooms = result.data;
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
                  style: TextStyle(color: AppColors.textPrimary(isDark)),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/test_chat_room');
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
                            itemCount: _chatRooms.length,
                            itemBuilder: (context, index) {
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
                                        color: AppColors.textSecondary(isDark),
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: AppColors.textSecondary(isDark),
                                    ),
                                    // TODO: 点击进入聊天室详情或聊天页面
                                    onTap: () {
                                      // 暂时可以跳转到详情页或者不做操作
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        );
      },
    );
  }
}
