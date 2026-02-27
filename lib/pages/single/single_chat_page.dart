import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_settings.dart';
import '../../common/widgets/log_view.dart';
import '../../common/widgets/grid_action_menu.dart';
import '../../common/log_content_page.dart';
import '../../common/widgets/common_input_row.dart';
import '../../common/widgets/common_section_title.dart';
import '../../common/widgets/common_layout.dart';
import '../../common/mixins/base_mixin.dart';

class SingleChatPage extends StatefulWidget {
  const SingleChatPage({super.key, this.userId, this.showAppBar = true});

  final String? userId;
  final bool showAppBar;

  @override
  State<SingleChatPage> createState() => _SingleChatPageState();
}

class _SingleChatPageState extends State<SingleChatPage> with BaseMixin {
  final _eventKey = 'single_test';
  final _settings = AppSettings();
  final _userIdController = TextEditingController();
  final _messageController = TextEditingController();
  final _logController = LogController();
  final _repeatCountController = TextEditingController(text: '1');

  @override
  LogController get logController => _logController;

  @override
  void initState() {
    super.initState();
    _addListener();

    // 如果传入了 userId,则自动填充
    if (widget.userId != null) {
      _userIdController.text = widget.userId!;
    }

    _userIdController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _messageController.dispose();
    _repeatCountController.dispose();
    super.dispose();
  }

  void _addListener() {
    EMClient.getInstance.chatManager.addMessageEvent(
      _eventKey,
      ChatMessageEvent(
        onSuccess: (msgId, msg) {
          addSendLog('${msg.from}: ${msg.toJson().toString()}', message: msg);
        },
        onError: (msgId, msg, error) {
          addSendLog('发送失败: ${error.toString()}');
        },
      ),
    );

    EMClient.getInstance.chatManager.addEventHandler(
      _eventKey,
      EMChatEventHandler(
        onMessagesReceived: (messages) {
          for (var msg in messages) {
            if (msg.chatType == ChatType.Chat) {
              addReceiveLog(
                '${msg.from}: ${msg.toJson().toString()}',
                message: msg,
              );
            }
          }
        },
        onMessageContentChanged: (msg, operator, operationTime) {
          addReceiveLog(
            '${msg.from}: ${msg.toJson().toString()}',
            message: msg,
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textPrimary(isDark)),
      title: Text(
        '单聊测试',
        style: TextStyle(color: AppColors.textPrimary(isDark)),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.info),
          onPressed: () => Navigator.of(context).pushNamed('/settings'),
        ),
      ],
    );
  }

  Widget _buildControlPanel(bool isDark, bool isWide) {
    return Column(
      children: [
        CommonInputRow(
          controller: _userIdController,
          hintText: '输入对方 ID',
          isDark: isDark,
        ),
        const SizedBox(height: 20),
        CommonInputRow(
          controller: _messageController,
          hintText: '输入消息内容',
          buttonText: 'Send',
          onPressed: () => _sendTextMessage(_messageController.text),
          isDark: isDark,
          countController: _repeatCountController,
        ),
        const SizedBox(height: 10),
        CommonSectionTitle(title: '消息', isDark: isDark),
        SizedBox(height: isWide ? 20 : 10),
        _buildMessageTypeButtons(isDark),
        const SizedBox(height: 10),
        CommonSectionTitle(title: '工具', isDark: isDark),
        SizedBox(height: isWide ? 20 : 10),
        _buildItemsButtons(isDark),
      ],
    );
  }

  Widget _buildLogPanel(bool isDark) {
    return LogView(
      controller: _logController,
      isDark: isDark,
      menuBuilder: (entry) {
        final items = <LogMenuItem>[];
        // 复制按钮始终显示
        items.add(
          LogMenuItem(
            title: '复制',
            onTap: () async {
              final text = '${entry.timestamp}: ${entry.content}';
              await Clipboard.setData(ClipboardData(text: text));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('已复制到剪贴板'),
                    duration: Duration(milliseconds: 500),
                  ),
                );
              }
            },
          ),
        );

        // 如果包含消息，增加功能按钮
        final message = entry.message;
        if (message != null) {
          items.add(
            LogMenuItem(
              title: '发送已读ACK',
              onTap: () async {
                try {
                  await EMClient.getInstance.chatManager.sendMessageReadAck(
                    message,
                  );
                  addLog('已发送已读确认');
                } catch (e) {
                  addAppErrLog('发送已读确认失败: $e');
                }
              },
            ),
          );
          items.add(
            LogMenuItem(
              title: '从服务器删除',
              onTap: () async {
                try {
                  addSendLog('开始删除消息');
                  await EMClient.getInstance.chatManager
                      .deleteRemoteMessagesWithIds(
                        conversationId: message.conversationId!,
                        type: EMConversationType.values[message.chatType.index],
                        msgIds: [message.msgId],
                      );
                  addReceiveLog('删除消息成功');
                } catch (e) {
                  addAppErrLog('删除失败: $e');
                }
              },
            ),
          );
          items.add(
            LogMenuItem(
              title: '修改',
              onTap: () async {
                try {
                  addSendLog('开始修改消息');
                  final msg = await EMClient.getInstance.chatManager
                      .modifyMessage(
                        messageId: message.msgId,
                        msgBody: EMTextMessageBody(content: 'modify content'),
                      );
                  addSendLog(
                    '${msg.from}: ${msg.toJson().toString()}',
                    message: msg,
                  );
                } catch (e) {
                  addAppErrLog('修改失败: $e');
                }
              },
            ),
          );
          items.add(
            LogMenuItem(
              title: '撤回',
              onTap: () async {
                try {
                  addSendLog('开始撤回消息');
                  await EMClient.getInstance.chatManager.recallMessage(
                    message.msgId,
                  );
                  addReceiveLog('撤回消息成功');
                } catch (e) {
                  addAppErrLog('撤回失败: $e');
                }
              },
            ),
          );
        }
        return items;
      },
    );
  }

  Future<void> _sendTextMessage(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;
    int count = int.tryParse(_repeatCountController.text) ?? 1;
    try {
      for (int i = 0; i < count; i++) {
        final msg = EMMessage.createTxtSendMessage(
          targetId: _userIdController.text.trim().toLowerCase(),
          content: count > 1 ? '$trimmedText ($i)' : trimmedText,
          chatType: ChatType.Chat,
        );
        await sendMessage(msg);
      }
      _messageController.clear();
    } catch (e) {
      addAppErrLog('发送文字失败: ${e.toString()}');
    }
  }

  Future<void> sendMessage(EMMessage msg) async {
    if (_userIdController.text.trim().isEmpty) {
      addLog('请先输入对方ID');
      return;
    }
    try {
      msg.attributes = {
        'extKey1': 'extValue1',
        'date': DateTime.now().toString(),
      };
      addSendLog('开始发送消息');
      await EMClient.getInstance.chatManager.sendMessage(msg);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _settings.isDarkMode;
    return CommonLayout(
      isDark: isDark,
      showAppBar: widget.showAppBar,
      appBar: widget.showAppBar ? _buildAppBar(isDark) : null,
      controlPanel: LayoutBuilder(
        builder: (context, constraints) {
          return _buildControlPanel(isDark, constraints.maxWidth > 800);
        },
      ),
      logPanel: _buildLogPanel(isDark),
    );
  }

  // --- 辅助组件 ---

  Widget _buildMessageTypeButtons(bool isDark) {
    final items = [
      GridActionItem(
        icon: Icons.image_outlined,
        label: '图片',
        onTap: () async {
          try {
            final filePath = await getAssetFilePath('assets/image.jpg');
            await sendMessage(
              EMMessage.createImageSendMessage(
                targetId: _userIdController.text.trim().toLowerCase(),
                filePath: filePath,
                width: 1920,
                height: 1080,
                fileSize: 111916,
                chatType: ChatType.Chat,
              ),
            );
          } catch (e) {
            addAppErrLog('发送图片失败: ${e.toString()}');
          }
        },
      ),
      GridActionItem(
        icon: Icons.videocam_outlined,
        label: '视频',
        onTap: () async {
          try {
            final filePath = await getAssetFilePath('assets/video.mp4');
            final thumb = await getAssetFilePath('assets/image.jpg');
            await sendMessage(
              EMMessage.createVideoSendMessage(
                targetId: _userIdController.text.trim().toLowerCase(),
                filePath: filePath,
                thumbnailLocalPath: thumb,
                width: 1920,
                height: 1080,
                duration: 10,
                fileSize: 4006696,
                chatType: ChatType.Chat,
              ),
            );
          } catch (e) {
            addAppErrLog('发送视频失败: ${e.toString()}');
          }
        },
      ),
      GridActionItem(
        icon: Icons.mic_outlined,
        label: '语音',
        onTap: () async {
          try {
            final filePath = await getAssetFilePath('assets/voice.mp3');
            await sendMessage(
              EMMessage.createVoiceSendMessage(
                targetId: _userIdController.text.trim().toLowerCase(),
                filePath: filePath,
                duration: 10,
                fileSize: 111916,
                chatType: ChatType.Chat,
              ),
            );
          } catch (e) {
            addAppErrLog('发送语音失败: ${e.toString()}');
          }
        },
      ),
      GridActionItem(
        icon: Icons.description_outlined,
        label: '文件',
        onTap: () async {
          try {
            final filePath = await getAssetFilePath('assets/voice.mp3');
            await sendMessage(
              EMMessage.createFileSendMessage(
                targetId: _userIdController.text.trim().toLowerCase(),
                filePath: filePath,
                fileSize: 111916,
                chatType: ChatType.Chat,
              ),
            );
          } catch (e) {
            addAppErrLog('发送文件失败: ${e.toString()}');
          }
        },
      ),
      GridActionItem(
        icon: Icons.location_on_outlined,
        label: '位置',
        onTap: () async {
          try {
            await sendMessage(
              EMMessage.createLocationSendMessage(
                targetId: _userIdController.text.trim().toLowerCase(),
                latitude: 39.9042,
                longitude: 116.4074,
                address: '北京市海淀区中关村',
                chatType: ChatType.Chat,
              ),
            );
          } catch (e) {
            addAppErrLog('发送位置失败: ${e.toString()}');
          }
        },
      ),
      GridActionItem(
        icon: Icons.extension_outlined,
        label: '自定义',
        onTap: () async {
          try {
            await sendMessage(
              EMMessage.createCustomSendMessage(
                targetId: _userIdController.text.trim().toLowerCase(),
                event: 'eventValue',
                params: {'paramsKey': 'paramsValue'},
                chatType: ChatType.Chat,
              ),
            );
          } catch (e) {
            addAppErrLog('发送自定义失败: ${e.toString()}');
          }
        },
      ),
    ];

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: GridActionMenu(items: items, isDark: isDark, columns: 6),
    );
  }

  Widget _buildItemsButtons(bool isDark) {
    final items = [
      GridActionItem(
        icon: Icons.article_outlined,
        label: '日志',
        onTap: () async {
          final logZipPath = await EMClient.getInstance.compressLogs();
          final logPath = logZipPath.replaceFirst('log.gz', 'easemob.log');
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => LogContentPage(logPath: logPath),
              ),
            );
          }
        },
      ),
      GridActionItem(
        icon: Icons.info_outline,
        label: '信息',
        onTap: () async {
          final currentUser = await EMClient.getInstance.getCurrentUserId();
          final deviceId = await EMClient.getInstance.getCurrentDeviceId();

          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('个人信息'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('当前用户: $currentUser'),
                    const SizedBox(height: 8),
                    Text('设备ID: $deviceId'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('确定'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    ];

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: GridActionMenu(items: items, isDark: isDark, columns: 6),
    );
  }
}
