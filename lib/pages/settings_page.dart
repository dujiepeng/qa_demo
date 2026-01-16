import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settings = AppSettings();
  late TextEditingController _appKeyController;
  late TextEditingController _imServerController;
  late TextEditingController _imPortController;
  late TextEditingController _restServerController;

  late bool _useCustomAppKey;
  late bool _useCustomServer;

  @override
  void initState() {
    super.initState();
    _appKeyController = TextEditingController(text: _settings.appKey);
    _imServerController = TextEditingController(text: _settings.imServer);
    _imPortController = TextEditingController(
      text: _settings.imPort.toString(),
    );
    _restServerController = TextEditingController(text: _settings.restServer);
    _useCustomAppKey = _settings.useCustomAppKey;
    _useCustomServer = _settings.useCustomServer;
  }

  @override
  void dispose() {
    _appKeyController.dispose();
    _imServerController.dispose();
    _imPortController.dispose();
    _restServerController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final imPort = int.tryParse(_imPortController.text) ?? 6717;

    bool hasChanged = _settings.hasChanged(
      currentUseCustomAppKey: _useCustomAppKey,
      currentAppKey: _appKeyController.text.trim(),
      currentUseCustomServer: _useCustomServer,
      currentImServer: _imServerController.text.trim(),
      currentImPort: imPort,
      currentRestServer: _restServerController.text.trim(),
    );

    if (hasChanged) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('是否更新配置?'),
            content: const Text('更新服务器配置需要重启app后才生效。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  _settings.useCustomAppKey = _useCustomAppKey;
                  _settings.appKey = _appKeyController.text.trim();
                  _settings.useCustomServer = _useCustomServer;
                  _settings.imServer = _imServerController.text.trim();
                  _settings.imPort = imPort;
                  _settings.restServer = _restServerController.text.trim();
                  _settings.isDirty = true;
                  // 清理登录状态
                  _settings.isLoggedIn = false;

                  await _settings.saveSettings();
                  exit(0);
                },
                child: const Text('确认重启'),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('配置未发生变更')));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _settings.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.backgroundStart(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '服务器设置',
          style: TextStyle(color: AppColors.textPrimary(isDark)),
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary(isDark)),
        actions: [
          TextButton(
            onPressed: _handleSave,
            child: Text(
              '保存',
              style: TextStyle(
                color: AppColors.primary(isDark),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
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
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            _buildSectionTitle('AppKey 配置', isDark),
            _buildSwitchItem(
              title: '使用自定义 AppKey',
              icon: Icons.key_outlined,
              value: _useCustomAppKey,
              onChanged: (val) => setState(() => _useCustomAppKey = val),
              isDark: isDark,
            ),
            if (_useCustomAppKey) ...[
              const SizedBox(height: 10),
              _buildInputItem(
                controller: _appKeyController,
                hintText: '输入 AppKey',
                isDark: isDark,
              ),
            ],
            const SizedBox(height: 30),
            _buildSectionTitle('服务器配置', isDark),
            _buildSwitchItem(
              title: '使用自定义服务器',
              icon: Icons.dns_outlined,
              value: _useCustomServer,
              onChanged: (val) => setState(() => _useCustomServer = val),
              isDark: isDark,
            ),
            if (_useCustomServer) ...[
              const SizedBox(height: 10),
              _buildInputItem(
                controller: _imServerController,
                hintText: 'IM 服务器地址',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildInputItem(
                controller: _imPortController,
                hintText: 'IM 端口',
                keyboardType: TextInputType.number,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildInputItem(
                controller: _restServerController,
                hintText: 'REST 服务器地址',
                isDark: isDark,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.primary(isDark),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground(isDark),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.glassBorder(isDark)),
      ),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary(isDark), size: 20),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontSize: 16,
              ),
            ),
          ],
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary(isDark),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
      ),
    );
  }

  Widget _buildInputItem({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground(isDark),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.glassBorder(isDark)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: AppColors.textPrimary(isDark)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    );
  }
}
