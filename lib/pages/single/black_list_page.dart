import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/pages/single/single_chat_page.dart';

import '../../common/widgets/common_gradient_background.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_settings.dart';

typedef LoadBlockListCallback = Future<List<String>> Function();
typedef UpdateBlockListCallback = Future<void> Function(String userId);

class BlackListPage extends StatefulWidget {
  final ValueChanged<String>? onItemTap;
  final LoadBlockListCallback? loadBlockList;
  final UpdateBlockListCallback? removeFromBlockList;

  const BlackListPage({
    super.key,
    this.onItemTap,
    this.loadBlockList,
    this.removeFromBlockList,
  });

  @override
  State<BlackListPage> createState() => _BlackListPageState();
}

class _BlackListPageState extends State<BlackListPage> {
  final _settings = AppSettings();
  final ScrollController _scrollController = ScrollController();
  List<String> _blockedUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchBlockList();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<String>> _defaultLoadBlockList() {
    return EMClient.getInstance.contactManager.fetchBlockIds();
  }

  Future<void> _defaultRemoveFromBlockList(String userId) {
    return EMClient.getInstance.contactManager.removeUserFromBlockList(userId);
  }

  Future<void> _fetchBlockList() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result =
          await (widget.loadBlockList ?? _defaultLoadBlockList).call();
      if (!mounted) {
        return;
      }
      setState(() {
        _blockedUsers = result;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('获取黑名单失败: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeBlockedUser(String userId) async {
    try {
      await (widget.removeFromBlockList ?? _defaultRemoveFromBlockList).call(
        userId,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已移出黑名单')));
      await _fetchBlockList();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('移出黑名单失败: $e')));
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已复制: $text'),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _openChat(String userId) {
    if (widget.onItemTap != null) {
      widget.onItemTap!(userId);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SingleChatPage(userId: userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final isDark = _settings.isDarkMode;
        return CommonGradientBackground(
          isDark: isDark,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(
                '黑名单测试',
                style: TextStyle(color: AppColors.textPrimary(isDark)),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  tooltip: '刷新',
                  onPressed: _fetchBlockList,
                  icon: const Icon(Icons.refresh),
                ),
              ],
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: AppColors.textPrimary(isDark)),
            ),
            body: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary(isDark),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchBlockList,
                    child: _blockedUsers.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height - 200,
                                child: Center(
                                  child: Text(
                                    '暂无黑名单用户',
                                    style: TextStyle(
                                      color: AppColors.textSecondary(isDark),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _blockedUsers.length,
                            itemBuilder: (context, index) {
                              final userId = _blockedUsers[index];
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
                                    items: const [
                                      PopupMenuItem(
                                        value: 'copy_id',
                                        child: Text('复制 ID'),
                                      ),
                                      PopupMenuItem(
                                        value: 'remove_block',
                                        child: Text('移出黑名单'),
                                      ),
                                    ],
                                  );

                                  if (value == 'copy_id') {
                                    _copyToClipboard(userId);
                                  } else if (value == 'remove_block') {
                                    _removeBlockedUser(userId);
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
                                        color: Colors.red.withValues(
                                          alpha: isDark ? 0.18 : 0.10,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.block_outlined,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                    title: Text(
                                      userId,
                                      style: TextStyle(
                                        color: AppColors.textPrimary(isDark),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'ID: $userId',
                                      style: TextStyle(
                                        color: AppColors.textSecondary(isDark),
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: AppColors.textSecondary(isDark),
                                    ),
                                    onTap: () => _openChat(userId),
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
