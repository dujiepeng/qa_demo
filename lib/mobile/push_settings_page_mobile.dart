import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';

import '../common/widgets/common_gradient_background.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';

typedef BindDeviceTokenCallback =
    Future<void> Function({
      required String notifierName,
      required String deviceToken,
    });
typedef SetSilentModeForAllCallback =
    Future<void> Function(ChatSilentModeParam param);
typedef SetConversationSilentModeCallback =
    Future<void> Function({
      required String conversationId,
      required EMConversationType type,
      required ChatSilentModeParam param,
    });
typedef RemoveConversationSilentModeCallback =
    Future<void> Function({
      required String conversationId,
      required EMConversationType type,
    });
typedef FetchSilentModeForAllCallback = Future<ChatSilentModeResult> Function();
typedef FetchConversationSilentModeCallback =
    Future<ChatSilentModeResult> Function({
      required String conversationId,
      required EMConversationType type,
    });
typedef UpdatePushDisplayStyleCallback =
    Future<void> Function(DisplayStyle displayStyle);
typedef FetchPushConfigsCallback = Future<EMPushConfigs> Function();
typedef PushTemplateSetter = Future<void> Function(String templateName);
typedef PushTemplateGetter = Future<String?> Function();
typedef SyncConversationsSilentModeCallback = Future<void> Function();

class PushSettingsPageMobile extends StatefulWidget {
  const PushSettingsPageMobile({
    super.key,
    this.bindDeviceToken,
    this.setSilentModeForAll,
    this.fetchSilentModeForAll,
    this.setConversationSilentMode,
    this.removeConversationSilentMode,
    this.fetchConversationSilentMode,
    this.syncConversationsSilentMode,
    this.updatePushDisplayStyle,
    this.fetchPushConfigs,
    this.setPushTemplate,
    this.getPushTemplate,
  });

  final BindDeviceTokenCallback? bindDeviceToken;
  final SetSilentModeForAllCallback? setSilentModeForAll;
  final FetchSilentModeForAllCallback? fetchSilentModeForAll;
  final SetConversationSilentModeCallback? setConversationSilentMode;
  final RemoveConversationSilentModeCallback? removeConversationSilentMode;
  final FetchConversationSilentModeCallback? fetchConversationSilentMode;
  final SyncConversationsSilentModeCallback? syncConversationsSilentMode;
  final UpdatePushDisplayStyleCallback? updatePushDisplayStyle;
  final FetchPushConfigsCallback? fetchPushConfigs;
  final PushTemplateSetter? setPushTemplate;
  final PushTemplateGetter? getPushTemplate;

  @override
  State<PushSettingsPageMobile> createState() => _PushSettingsPageMobileState();
}

class _PushSettingsPageMobileState extends State<PushSettingsPageMobile> {
  final _notifierNameController = TextEditingController();
  final _deviceTokenController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  final _conversationIdController = TextEditingController();
  final _templateController = TextEditingController();
  DisplayStyle _displayStyle = DisplayStyle.Simple;
  EMConversationType _conversationType = EMConversationType.GroupChat;

  @override
  void dispose() {
    _notifierNameController.dispose();
    _deviceTokenController.dispose();
    _durationController.dispose();
    _conversationIdController.dispose();
    _templateController.dispose();
    super.dispose();
  }

  Future<void> _bindDeviceToken() async {
    final notifierName = _notifierNameController.text.trim();
    final deviceToken = _deviceTokenController.text.trim();
    if (notifierName.isEmpty || deviceToken.isEmpty) {
      _showMessage('请输入 notifier name 和 device token');
      return;
    }
    try {
      await (widget.bindDeviceToken ?? _defaultBindDeviceToken).call(
        notifierName: notifierName,
        deviceToken: deviceToken,
      );
      _showMessage('绑定推送 token 成功');
    } catch (e) {
      _showMessage('绑定推送 token 失败: $e');
    }
  }

  Future<void> _setSilentModeForAll() async {
    final param = _buildSilentModeParam();
    if (param == null) return;
    try {
      await (widget.setSilentModeForAll ?? _defaultSetSilentModeForAll).call(
        param,
      );
      _showMessage('设置全局静默成功');
    } catch (e) {
      _showMessage('设置全局静默失败: $e');
    }
  }

  Future<void> _fetchSilentModeForAll() async {
    try {
      final result =
          await (widget.fetchSilentModeForAll ?? _defaultFetchSilentModeForAll)
              .call();
      _showMessage('全局静默: ${_formatSilentModeResult(result)}');
    } catch (e) {
      _showMessage('查询全局静默失败: $e');
    }
  }

  Future<void> _setConversationSilentMode() async {
    final conversationId = _conversationIdController.text.trim();
    final param = _buildSilentModeParam();
    if (conversationId.isEmpty) {
      _showMessage('请输入会话 ID');
      return;
    }
    if (param == null) return;
    try {
      await (widget.setConversationSilentMode ??
              _defaultSetConversationSilentMode)
          .call(
            conversationId: conversationId,
            type: _conversationType,
            param: param,
          );
      _showMessage('设置会话静默成功');
    } catch (e) {
      _showMessage('设置会话静默失败: $e');
    }
  }

  Future<void> _removeConversationSilentMode() async {
    final conversationId = _conversationIdController.text.trim();
    if (conversationId.isEmpty) {
      _showMessage('请输入会话 ID');
      return;
    }
    try {
      await (widget.removeConversationSilentMode ??
              _defaultRemoveConversationSilentMode)
          .call(conversationId: conversationId, type: _conversationType);
      _showMessage('清除会话静默成功');
    } catch (e) {
      _showMessage('清除会话静默失败: $e');
    }
  }

  Future<void> _fetchConversationSilentMode() async {
    final conversationId = _conversationIdController.text.trim();
    if (conversationId.isEmpty) {
      _showMessage('请输入会话 ID');
      return;
    }
    try {
      final result =
          await (widget.fetchConversationSilentMode ??
                  _defaultFetchConversationSilentMode)
              .call(conversationId: conversationId, type: _conversationType);
      _showMessage('会话静默: ${_formatSilentModeResult(result)}');
    } catch (e) {
      _showMessage('查询会话静默失败: $e');
    }
  }

  Future<void> _syncConversationsSilentMode() async {
    try {
      await (widget.syncConversationsSilentMode ??
              _defaultSyncConversationsSilentMode)
          .call();
      _showMessage('同步会话静默成功');
    } catch (e) {
      _showMessage('同步会话静默失败: $e');
    }
  }

  Future<void> _updatePushDisplayStyle() async {
    try {
      await (widget.updatePushDisplayStyle ?? _defaultUpdatePushDisplayStyle)
          .call(_displayStyle);
      _showMessage('设置展示样式成功: ${_displayStyleLabel(_displayStyle)}');
    } catch (e) {
      _showMessage('设置展示样式失败: $e');
    }
  }

  Future<void> _fetchPushConfigs() async {
    try {
      final configs =
          await (widget.fetchPushConfigs ?? _defaultFetchPushConfigs).call();
      _showMessage(
        '推送配置: style=${_displayStyleLabel(configs.displayStyle)}, name=${configs.displayName ?? ''}',
      );
    } catch (e) {
      _showMessage('查询推送配置失败: $e');
    }
  }

  Future<void> _setPushTemplate() async {
    final templateName = _templateController.text.trim();
    if (templateName.isEmpty) {
      _showMessage('请输入模板名称');
      return;
    }
    try {
      await (widget.setPushTemplate ?? _defaultSetPushTemplate).call(
        templateName,
      );
      _showMessage('设置推送模板成功');
    } catch (e) {
      _showMessage('设置推送模板失败: $e');
    }
  }

  Future<void> _getPushTemplate() async {
    try {
      final templateName =
          await (widget.getPushTemplate ?? _defaultGetPushTemplate).call();
      _showMessage('当前推送模板: ${templateName ?? ''}');
    } catch (e) {
      _showMessage('查询推送模板失败: $e');
    }
  }

  ChatSilentModeParam? _buildSilentModeParam() {
    final duration = int.tryParse(_durationController.text.trim());
    if (duration == null || duration <= 0) {
      _showMessage('请输入大于 0 的免打扰分钟数');
      return null;
    }
    return ChatSilentModeParam.silentDuration(duration);
  }

  Future<void> _defaultBindDeviceToken({
    required String notifierName,
    required String deviceToken,
  }) {
    return EMClient.getInstance.pushManager.bindDeviceToken(
      notifierName: notifierName,
      deviceToken: deviceToken,
    );
  }

  Future<void> _defaultSetSilentModeForAll(ChatSilentModeParam param) {
    return EMClient.getInstance.pushManager.setSilentModeForAll(param: param);
  }

  Future<ChatSilentModeResult> _defaultFetchSilentModeForAll() {
    return EMClient.getInstance.pushManager.fetchSilentModeForAll();
  }

  Future<void> _defaultSetConversationSilentMode({
    required String conversationId,
    required EMConversationType type,
    required ChatSilentModeParam param,
  }) {
    return EMClient.getInstance.pushManager.setConversationSilentMode(
      conversationId: conversationId,
      type: type,
      param: param,
    );
  }

  Future<void> _defaultRemoveConversationSilentMode({
    required String conversationId,
    required EMConversationType type,
  }) {
    return EMClient.getInstance.pushManager.removeConversationSilentMode(
      conversationId: conversationId,
      type: type,
    );
  }

  Future<ChatSilentModeResult> _defaultFetchConversationSilentMode({
    required String conversationId,
    required EMConversationType type,
  }) {
    return EMClient.getInstance.pushManager.fetchConversationSilentMode(
      conversationId: conversationId,
      type: type,
    );
  }

  Future<void> _defaultSyncConversationsSilentMode() {
    return EMClient.getInstance.pushManager.syncConversationsSilentMode();
  }

  Future<void> _defaultUpdatePushDisplayStyle(DisplayStyle displayStyle) {
    return EMClient.getInstance.pushManager.updatePushDisplayStyle(
      displayStyle,
    );
  }

  Future<EMPushConfigs> _defaultFetchPushConfigs() {
    return EMClient.getInstance.pushManager.fetchPushConfigsFromServer();
  }

  Future<void> _defaultSetPushTemplate(String templateName) {
    return EMClient.getInstance.pushManager.setPushTemplate(templateName);
  }

  Future<String?> _defaultGetPushTemplate() {
    return EMClient.getInstance.pushManager.getPushTemplate();
  }

  String _formatSilentModeResult(ChatSilentModeResult result) {
    return 'conv=${result.conversationId}, type=${result.conversationType.name}, remind=${result.remindType?.name ?? ''}, expire=${result.expireTimestamp ?? ''}';
  }

  String _displayStyleLabel(DisplayStyle style) {
    return style == DisplayStyle.Simple ? '简单提示' : '展示内容';
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppSettings().isDarkMode;
    return CommonGradientBackground(
      isDark: isDark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            '离线推送设置',
            style: TextStyle(color: AppColors.textPrimary(isDark)),
          ),
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.textPrimary(isDark)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTokenSection(isDark),
            const SizedBox(height: 12),
            _buildSilentModeSection(isDark),
            const SizedBox(height: 12),
            _buildDisplaySection(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenSection(bool isDark) {
    return _SectionPanel(
      title: '推送 token',
      isDark: isDark,
      children: [
        _buildTextField(
          controller: _notifierNameController,
          labelText: 'notifier name',
          hintText: '例如 qa-huawei / qa-fcm',
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildTextField(
          controller: _deviceTokenController,
          labelText: 'device token',
          hintText: '厂商返回的真实 token',
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _ActionButton(
          icon: Icons.cloud_upload_outlined,
          label: '绑定推送 token',
          onPressed: _bindDeviceToken,
        ),
      ],
    );
  }

  Widget _buildSilentModeSection(bool isDark) {
    return _SectionPanel(
      title: '静默模式',
      isDark: isDark,
      children: [
        _buildTextField(
          controller: _durationController,
          labelText: '免打扰分钟数',
          hintText: '例如 30',
          keyboardType: TextInputType.number,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.notifications_off_outlined,
                label: '设置全局静默',
                onPressed: _setSilentModeForAll,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                icon: Icons.manage_search_outlined,
                label: '查询全局静默',
                onPressed: _fetchSilentModeForAll,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildTextField(
          controller: _conversationIdController,
          labelText: '会话 ID',
          hintText: '用户 ID / 群组 ID / 聊天室 ID',
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<EMConversationType>(
          initialValue: _conversationType,
          dropdownColor: AppColors.inputBackground(isDark),
          decoration: _inputDecoration(
            labelText: '会话类型',
            hintText: '',
            isDark: isDark,
          ),
          items: const [
            DropdownMenuItem(value: EMConversationType.Chat, child: Text('单聊')),
            DropdownMenuItem(
              value: EMConversationType.GroupChat,
              child: Text('群聊'),
            ),
            DropdownMenuItem(
              value: EMConversationType.ChatRoom,
              child: Text('聊天室'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _conversationType = value);
            }
          },
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ActionButton(
              icon: Icons.notifications_paused_outlined,
              label: '设置会话静默',
              onPressed: _setConversationSilentMode,
            ),
            _ActionButton(
              icon: Icons.notifications_active_outlined,
              label: '清除会话静默',
              onPressed: _removeConversationSilentMode,
            ),
            _ActionButton(
              icon: Icons.manage_search_outlined,
              label: '查询会话静默',
              onPressed: _fetchConversationSilentMode,
            ),
            _ActionButton(
              icon: Icons.sync_outlined,
              label: '同步会话静默',
              onPressed: _syncConversationsSilentMode,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDisplaySection(bool isDark) {
    return _SectionPanel(
      title: '展示与模板',
      isDark: isDark,
      children: [
        SegmentedButton<DisplayStyle>(
          segments: const [
            ButtonSegment(value: DisplayStyle.Simple, label: Text('简单提示')),
            ButtonSegment(value: DisplayStyle.Summary, label: Text('展示内容')),
          ],
          selected: {_displayStyle},
          onSelectionChanged: (values) {
            setState(() => _displayStyle = values.single);
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.visibility_outlined,
                label: '设置展示样式',
                onPressed: _updatePushDisplayStyle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                icon: Icons.manage_search_outlined,
                label: '查询推送配置',
                onPressed: _fetchPushConfigs,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildTextField(
          controller: _templateController,
          labelText: '模板名称',
          hintText: '服务端已配置的模板名称',
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.fact_check_outlined,
                label: '设置推送模板',
                onPressed: _setPushTemplate,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                icon: Icons.manage_search_outlined,
                label: '查询推送模板',
                onPressed: _getPushTemplate,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required bool isDark,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: AppColors.textPrimary(isDark)),
      decoration: _inputDecoration(
        labelText: labelText,
        hintText: hintText,
        isDark: isDark,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required String hintText,
    required bool isDark,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: TextStyle(color: AppColors.textSecondary(isDark)),
      hintStyle: TextStyle(color: AppColors.textSecondary(isDark)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.glassBorder(isDark)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary(isDark)),
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({
    required this.title,
    required this.isDark,
    required this.children,
  });

  final String title;
  final bool isDark;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inputBackground(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary(isDark),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
