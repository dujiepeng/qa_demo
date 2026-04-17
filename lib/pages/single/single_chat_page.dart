import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_settings.dart';
import '../../common/widgets/log_view.dart';
import '../../common/widgets/log_view_actions.dart';
import '../../common/widgets/grid_action_menu.dart';
import '../../common/widgets/common_input_row.dart';
import '../../common/widgets/common_section_title.dart';
import '../../common/widgets/common_layout.dart';
import '../../common/widgets/info_dialog.dart';
import '../../common/mixins/base_mixin.dart';
import 'single_chat_reaction.dart';

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
  final Map<String, Map<String, int>> _reactionCountsByMessageId = {};
  bool _deliverOnlineOnly = false;

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
          addSendLog(
            '${msg.from}: ${msg.toJson().toString()}',
            attachment: msg,
            tag: 'message',
          );
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
                attachment: msg,
                tag: 'message',
              );
            }
          }
        },
        onMessageContentChanged: (msg, operator, operationTime) {
          addReceiveLog(
            '${msg.from}: ${msg.toJson().toString()}',
            attachment: msg,
            tag: 'message',
          );
        },
        onMessagesRecalled: (messages) {
          final recalledMessages = messages.map((e) => e.msgId).toSet();
          List<LogEntry> list = [];
          logController.entities
              .where((element) => element.attachment is EMMessage)
              .forEach((element) {
                final message = element.attachment as EMMessage;
                if (recalledMessages.contains(message.msgId)) {
                  list.add(element);
                }
              });
          logController.changeEntities(list, style: LogStyle.lineThrough);
          addSendLog('收到撤回事件');
        },
        onMessagesRead: (messages) {
          final recalledMessages = messages.map((e) => e.msgId).toSet();
          List<LogEntry> list = [];
          logController.entities
              .where((element) => element.attachment is EMMessage)
              .forEach((element) {
                final message = element.attachment as EMMessage;
                if (recalledMessages.contains(message.msgId)) {
                  list.add(element);
                }
              });
          logController.changeEntities(
            list,
            style: LogStyle.none,
            color: Colors.yellow,
          );
          addSendLog('收到消息已读, 已读消息会变成黄色');
        },
        onMessageReactionDidChange: (events) {
          final currentConversationId = _userIdController.text
              .trim()
              .toLowerCase();
          for (final event in events) {
            final reactionCounts = _reactionCountsByMessageId.putIfAbsent(
              event.messageId,
              () => <String, int>{},
            );
            applySingleChatReactionEvent(reactionCounts, event);
            final applied = applySingleChatReactionOverlay(
              logController,
              event.messageId,
              reactionCounts,
            );
            if (!applied &&
                currentConversationId.isNotEmpty &&
                event.conversationId == currentConversationId) {
              addReceiveLog(buildSingleChatReactionLabel(reactionCounts));
            }
          }
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
        // 信息按钮：显示当前用户、设备及服务器配置信息
        IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: '信息',
          // 复用通用 InfoDialog，自动拉取用户信息和服务器配置后展示弹窗
          onPressed: () => InfoDialog.show(context, _settings),
        ),
      ],
    );
  }

  Widget _buildControlPanel(bool isDark, bool isWide) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CommonInputRow(
                controller: _userIdController,
                hintText: '输入对方 ID',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Checkbox(
              value: _deliverOnlineOnly,
              onChanged: (value) {
                setState(() {
                  _deliverOnlineOnly = value ?? false;
                });
              },
            ),
            Text(
              '只发在线',
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
        CommonSectionTitle(title: '功能', isDark: isDark),
        SizedBox(height: isWide ? 20 : 10),
        _buildMessageButtons(isDark),
        const SizedBox(height: 10),
        // 「工具」区已移至 AppBar 右上角
      ],
    );
  }

  Widget _buildLogPanel(bool isDark) {
    return LogView(
      controller: _logController,
      isDark: isDark,
      menuShowCallback: () {
        FocusScope.of(context).unfocus();
      },
      actionsBuilder: (entry) => _buildLogActions(entry),
    );
  }

  List<LogAction> _buildLogActions(LogEntry entry) {
    final actions = <LogAction>[LogViewActions.copyEntry()];
    final attachment = entry.attachment;
    if (entry.tag == 'message' && attachment is EMMessage) {
      final message = attachment;
      actions.addAll([
        LogAction(
          id: 'send_read_ack',
          title: '发送单聊已读ACK',
          icon: Icons.mark_chat_read_outlined,
          onSelected: (_) async {
            try {
              await EMClient.getInstance.chatManager.sendMessageReadAck(
                message,
              );
              return const LogActionResult(
                overlayLabel: 'ACK已发送',
                overlayStyle: LogOverlayStyle.success,
              );
            } catch (e) {
              return LogActionResult(
                overlayLabel: 'ACK失败: $e',
                overlayStyle: LogOverlayStyle.error,
              );
            }
          },
        ),
        LogAction(
          id: 'reaction',
          title: 'Reaction',
          icon: Icons.emoji_emotions_outlined,
          onSelected: (_) async {
            final selection = await showSingleChatReactionSheet(context);
            if (selection == null) {
              return null;
            }
            try {
              if (selection.action == SingleChatReactionSheetAction.add) {
                await EMClient.getInstance.chatManager.addReaction(
                  messageId: message.msgId,
                  reaction: selection.reaction,
                );
                return null;
              }
              await EMClient.getInstance.chatManager.removeReaction(
                messageId: message.msgId,
                reaction: selection.reaction,
              );
              return null;
            } catch (e) {
              return LogActionResult(
                overlayLabel: 'Reaction失败: $e',
                overlayStyle: LogOverlayStyle.error,
              );
            }
          },
        ),
        LogAction(
          id: 'delete_remote',
          title: '从服务器删除',
          icon: Icons.delete_sweep_outlined,
          isDestructive: true,
          onSelected: (_) async {
            try {
              await EMClient.getInstance.chatManager
                  .deleteRemoteMessagesWithIds(
                    conversationId: message.conversationId!,
                    type: EMConversationType.values[message.chatType.index],
                    msgIds: [message.msgId],
                  );
              addSendLog('从服务器删除成功');
              return LogActionResult(
                overlayLabel: '已从服务器删除',
                overlayStyle: LogOverlayStyle.warning,
                style: LogStyle.lineThrough,
              );
            } catch (e) {
              return LogActionResult(
                overlayLabel: '删除失败: $e',
                overlayStyle: LogOverlayStyle.error,
              );
            }
          },
        ),
        LogAction(
          id: 'modify',
          title: '修改',
          icon: Icons.edit_outlined,
          foregroundColor: Colors.purple,
          onSelected: (_) async {
            try {
              final msg = await EMClient.getInstance.chatManager.modifyMessage(
                messageId: message.msgId,
                msgBody: EMTextMessageBody(content: 'modify content'),
              );
              addSendLog(
                '${msg.from}: ${msg.toJson().toString()}',
                attachment: msg,
                tag: 'message',
                color: Colors.purple,
              );
              return const LogActionResult(
                overlayLabel: '已修改',
                overlayStyle: LogOverlayStyle.info,
              );
            } catch (e) {
              return LogActionResult(
                overlayLabel: '修改失败:$e',
                overlayStyle: LogOverlayStyle.error,
              );
            }
          },
        ),
        LogAction(
          id: 'recall',
          title: '撤回',
          icon: Icons.undo_outlined,
          isDestructive: true,
          onSelected: (_) async {
            try {
              await EMClient.getInstance.chatManager.recallMessage(
                message.msgId,
              );
              addSendLog('撤回成功', color: Colors.green);
              return LogActionResult(
                overlayLabel: '已撤回',
                overlayStyle: LogOverlayStyle.warning,
                color: Colors.red.withValues(alpha: 0.14),
                style: LogStyle.lineThrough,
              );
            } catch (e) {
              addAppErrLog('撤回失败: $e');
              return LogActionResult(
                overlayLabel: '撤回失败: $e',
                overlayStyle: LogOverlayStyle.error,
              );
            }
          },
        ),
      ]);
    }
    return actions;
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
      msg.deliverOnlineOnly = _deliverOnlineOnly;
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
    // GestureDetector 捕获空白区域点击，收起键盘并取消输入框焦点。
    // behavior: translucent 确保事件能继续穿透到子组件（按钮等仍可正常响应）。
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: CommonLayout(
        isDark: isDark,
        showAppBar: widget.showAppBar,
        appBar: widget.showAppBar ? _buildAppBar(isDark) : null,
        controlPanel: LayoutBuilder(
          builder: (context, constraints) {
            return _buildControlPanel(isDark, constraints.maxWidth > 800);
          },
        ),
        logPanel: _buildLogPanel(isDark),
      ),
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

  String? _cursor;
  final int _pageSize = 30;
  Widget _buildMessageButtons(bool isDark) {
    final items = [
      GridActionItem(
        icon: Icons.article_outlined,
        label: '拉消息1',
        onTap: () async {
          EMCursorResult result = await EMClient.getInstance.chatManager
              .fetchHistoryMessagesByOption(
                _userIdController.text,
                EMConversationType.Chat,
                cursor: _cursor,
                pageSize: _pageSize,
              );
          _cursor = result.cursor;
          if (result.data.length < _pageSize) {
            addSendLog(
              '1拉取消息成功: ${result.data.length}/$_pageSize, 已无更多,再点将重新拉取',
              color: Colors.red,
            );
          } else {
            addSendLog('拉取消息成功: ${result.data.length}/$_pageSize, 还有更多');
          }
        },
      ),
      GridActionItem(
        icon: Icons.article_outlined,
        label: '拉消息2',
        onTap: () async {
          EMCursorResult result = await EMClient.getInstance.chatManager
              // ignore: deprecated_member_use
              .fetchHistoryMessages(
                conversationId: _userIdController.text,
                type: EMConversationType.Chat,
                startMsgId: _cursor ?? "",
                pageSize: _pageSize,
              );
          _cursor = result.cursor;
          if (result.data.length < _pageSize) {
            addSendLog(
              '2拉取消息成功: ${result.data.length}/$_pageSize, 已无更多,再点将重新拉取',
              color: Colors.red,
            );
          } else {
            addSendLog('拉取消息成功: ${result.data.length}/$_pageSize, 还有更多');
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
