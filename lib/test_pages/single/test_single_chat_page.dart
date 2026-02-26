import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_settings.dart';
import '../../common/widgets/log_view.dart';
import '../../common/widgets/grid_action_menu.dart';
import '../../common/log_content_page.dart';

class TestSingleChatPage extends StatefulWidget {
  const TestSingleChatPage({super.key, this.userId, this.showAppBar = true});

  final String? userId;
  final bool showAppBar;

  @override
  State<TestSingleChatPage> createState() => _TestSingleChatPageState();
}

class _TestSingleChatPageState extends State<TestSingleChatPage> {
  final _eventKey = 'single_test';
  final _settings = AppSettings();
  final _userIdController = TextEditingController();
  final _messageController = TextEditingController();
  final _logController = LogController();

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
    super.dispose();
  }

  void _addListener() {
    EMClient.getInstance.chatManager.addMessageEvent(
      _eventKey,
      ChatMessageEvent(
        onSuccess: (msgId, msg) {
          _addSendLog('${msg.from}: ${msg.toJson().toString()}', message: msg);
        },
        onError: (msgId, msg, error) {
          _addSendLog('发送失败: ${error.toString()}');
        },
      ),
    );

    EMClient.getInstance.chatManager.addEventHandler(
      _eventKey,
      EMChatEventHandler(
        onMessagesReceived: (messages) {
          for (var msg in messages) {
            if (msg.chatType == ChatType.Chat) {
              _addReceiveLog(
                '${msg.from}: ${msg.toJson().toString()}',
                message: msg,
              );
            }
          }
        },
      ),
    );
  }

  void _addLog(String content) => _logController.addLog(content);
  void _addAppErrLog(String content) =>
      _logController.addLog(content, color: Colors.red);
  void _addSendLog(String content, {EMMessage? message}) =>
      _logController.addLog(content, color: Colors.green);
  void _addReceiveLog(String content, {EMMessage? message}) =>
      _logController.addLog(content, color: Colors.blue);

  Future<String> _getAssetFilePath(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final fileName = assetPath.split('/').last;
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file.path;
  }

  // --- 优化后的 UI 区块 ---

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      toolbarHeight: kToolbarHeight + 20,
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textPrimary(isDark)),
      title: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Text(
          '单聊测试',
          style: TextStyle(color: AppColors.textPrimary(isDark)),
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: IconButton(
            icon: const Icon(Icons.info),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ),
      ],
    );
  }

  Widget _buildControlPanel(bool isDark, bool isWide) {
    return Column(
      children: [
        _buildInputRow(
          controller: _userIdController,
          hintText: '输入对方 ID',
          isDark: isDark,
        ),
        const SizedBox(height: 20),
        _buildInputRow(
          controller: _messageController,
          hintText: '输入消息内容',
          buttonText: 'Send',
          onPressed: () => _sendTextMessage(_messageController.text),
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildSectionTitle('消息', isDark),
        SizedBox(height: isWide ? 20 : 10),
        _buildMessageTypeButtons(isDark),
        const SizedBox(height: 10),
        _buildSectionTitle('工具', isDark),
        SizedBox(height: isWide ? 20 : 10),
        _buildItemsButtons(isDark),
      ],
    );
  }

  Widget _buildLogPanel(bool isDark) {
    return LogView(
      controller: _logController,
      isDark: isDark,
      longPassCallback: _handleLogLongPress,
    );
  }

  Future<void> _handleLogLongPress(
    EMMessage? message,
    LogMenuAction action,
  ) async {
    if (message == null) return;
    try {
      switch (action) {
        case LogMenuAction.sendReadAck:
          await EMClient.getInstance.chatManager.sendMessageReadAck(message);
          break;
        case LogMenuAction.delete:
          await EMClient.getInstance.chatManager.deleteRemoteMessagesWithIds(
            conversationId: message.conversationId!,
            type: EMConversationType.values[message.chatType.index],
            msgIds: [message.msgId],
          );
          break;
        case LogMenuAction.recall:
          await EMClient.getInstance.chatManager.recallMessage(message.msgId);
          break;
      }
    } catch (e) {
      _addAppErrLog('日志操作失败: ${e.toString()}');
    }
  }

  Future<void> _sendTextMessage(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;
    try {
      final msg = EMMessage.createTxtSendMessage(
        targetId: _userIdController.text.trim().toLowerCase(),
        content: trimmedText,
        chatType: ChatType.Chat,
      );
      await sendMessage(msg);
      _messageController.clear();
    } catch (e) {
      _addAppErrLog('发送文字失败: ${e.toString()}');
    }
  }

  Future<void> sendMessage(EMMessage msg) async {
    if (_userIdController.text.trim().isEmpty) {
      _addLog('请先输入对方ID');
      return;
    }
    try {
      msg.attributes = {
        'extKey1': 'extValue1',
        'date': DateTime.now().toString(),
      };
      _addSendLog('开始发送消息');
      await EMClient.getInstance.chatManager.sendMessage(msg);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _settings.isDarkMode;
    final padding = EdgeInsets.only(
      top: widget.showAppBar ? (kToolbarHeight + 80) : 40,
      left: 15,
      right: 15,
      bottom: 30,
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: widget.showAppBar ? _buildAppBar(isDark) : null,
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      padding: padding,
                      child: _buildControlPanel(isDark, true),
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.glassBorder(isDark).withValues(alpha: 0.2),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: padding,
                      child: _buildLogPanel(isDark),
                    ),
                  ),
                ],
              );
            }

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: padding,
                  child: Column(
                    children: [
                      _buildControlPanel(isDark, false),
                      const SizedBox(height: 20),
                      _buildLogPanel(isDark),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- 辅助组件 ---

  Widget _buildInputRow({
    required TextEditingController controller,
    required String hintText,
    String? buttonText,
    VoidCallback? onPressed,
    required bool isDark,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: TextStyle(color: AppColors.textPrimary(isDark)),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: AppColors.textSecondary(isDark)),
              filled: true,
              fillColor: AppColors.inputBackground(isDark),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.glassBorder(isDark)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.glassBorder(isDark)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary(isDark)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
            ),
          ),
        ),
        if (buttonText?.isNotEmpty == true && onPressed != null) ...[
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary(isDark),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(buttonText!),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary(isDark),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMessageTypeButtons(bool isDark) {
    final items = [
      GridActionItem(
        icon: Icons.image_outlined,
        label: '图片',
        onTap: () async {
          try {
            final filePath = await _getAssetFilePath('assets/image.jpg');
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
            _addAppErrLog('发送图片失败: ${e.toString()}');
          }
        },
      ),
      GridActionItem(
        icon: Icons.videocam_outlined,
        label: '视频',
        onTap: () async {
          try {
            final filePath = await _getAssetFilePath('assets/video.mp4');
            final thumb = await _getAssetFilePath('assets/image.jpg');
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
            _addAppErrLog('发送视频失败: ${e.toString()}');
          }
        },
      ),
      GridActionItem(
        icon: Icons.mic_outlined,
        label: '语音',
        onTap: () async {
          try {
            final filePath = await _getAssetFilePath('assets/voice.mp3');
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
            _addAppErrLog('发送语音失败: ${e.toString()}');
          }
        },
      ),
      GridActionItem(
        icon: Icons.description_outlined,
        label: '文件',
        onTap: () async {
          try {
            final filePath = await _getAssetFilePath('assets/voice.mp3');
            await sendMessage(
              EMMessage.createFileSendMessage(
                targetId: _userIdController.text.trim().toLowerCase(),
                filePath: filePath,
                fileSize: 111916,
                chatType: ChatType.Chat,
              ),
            );
          } catch (e) {
            _addAppErrLog('发送文件失败: ${e.toString()}');
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
            _addAppErrLog('发送位置失败: ${e.toString()}');
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
            _addAppErrLog('发送自定义失败: ${e.toString()}');
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
