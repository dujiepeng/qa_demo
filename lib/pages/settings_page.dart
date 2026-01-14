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
    _settings.appKey = _appKeyController.text.trim();
    _settings.imServer = _imServerController.text.trim();
    _settings.imPort = int.tryParse(_imPortController.text.trim()) ?? 6717;
    _settings.restServer = _restServerController.text.trim();

    await _settings.saveSettings(); // 持久化到本地

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings saved')));
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
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              _saveSettings();
              Navigator.pop(context);
            },
          ),
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
