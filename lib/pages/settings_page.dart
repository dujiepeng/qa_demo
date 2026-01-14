import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  void initState() {
    super.initState();
    _appKeyController = TextEditingController(text: _settings.appKey);
    _imServerController = TextEditingController(text: _settings.imServer);
    _imPortController = TextEditingController(
      text: _settings.imPort.toString(),
    );
    _restServerController = TextEditingController(text: _settings.restServer);
  }

  @override
  void dispose() {
    _appKeyController.dispose();
    _imServerController.dispose();
    _imPortController.dispose();
    _restServerController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    final currentAppKey = _appKeyController.text.trim();
    final currentImServer = _imServerController.text.trim();
    final currentImPort = int.tryParse(_imPortController.text.trim()) ?? 6717;
    final currentRestServer = _restServerController.text.trim();

    // 真正的对比：由于 switch 已经改变了 _settings，我们需要将控制器中的内容也考虑进去进行对比
    final changed = _settings.hasChanged(
      currentUseCustomAppKey: _settings.useCustomAppKey,
      currentAppKey: currentAppKey,
      currentUseCustomServer: _settings.useCustomServer,
      currentImServer: currentImServer,
      currentImPort: currentImPort,
      currentRestServer: currentRestServer,
    );

    if (changed) {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('重启提醒'),
          content: const Text('配置已发生变更，应用将保存并自动退出。请您稍后手动重新启动应用以使新配置生效。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确定'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // 只有在确认后才真正写回 AppSettings 的持久化字段
      _settings.appKey = currentAppKey;
      _settings.imServer = currentImServer;
      _settings.imPort = currentImPort;
      _settings.restServer = currentRestServer;

      await _settings.saveSettings();

      // 彻底退出应用
      exit(0);
    } else {
      // 没有任何变化，直接返回上一页
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundStart,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveSettings),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.backgroundStart, AppColors.backgroundEnd],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: [
              _buildSectionTitle('AppKey Configuration'),
              _buildSwitchItem(
                title: 'Use Custom AppKey',
                value: _settings.useCustomAppKey,
                onChanged: (val) =>
                    setState(() => _settings.useCustomAppKey = val),
              ),
              if (_settings.useCustomAppKey) ...[
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _appKeyController,
                  hintText: 'Enter AppKey',
                  icon: Icons.key,
                ),
              ],
              const SizedBox(height: 30),

              _buildSectionTitle('Server Configuration'),
              _buildSwitchItem(
                title: 'Use Custom Server',
                value: _settings.useCustomServer,
                onChanged: (val) =>
                    setState(() => _settings.useCustomServer = val),
              ),
              if (_settings.useCustomServer) ...[
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _imServerController,
                  hintText: 'IM Server',
                  icon: Icons.dns,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  controller: _imPortController,
                  hintText: 'IM Port',
                  icon: Icons.numbers,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  controller: _restServerController,
                  hintText: 'Rest Server',
                  icon: Icons.cloud_queue,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 10, left: 5),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 20,
          ),
        ),
      ),
    );
  }
}
