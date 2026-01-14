import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';

class TestChatRoomPage extends StatefulWidget {
  const TestChatRoomPage({super.key});

  @override
  State<TestChatRoomPage> createState() => _TestChatRoomPageState();
}

class _TestChatRoomPageState extends State<TestChatRoomPage> {
  final _settings = AppSettings();
  final _roomIdController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _roomIdController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _settings.isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '聊天室测试',
          style: TextStyle(color: AppColors.textPrimary(isDark)),
        ),
        centerTitle: true,
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
        child: Padding(
          padding: const EdgeInsets.only(
            top: kToolbarHeight + 60,
            left: 15,
            right: 15,
          ),
          child: Column(
            children: [
              _buildInputRow(
                controller: _roomIdController,
                hintText: '输入聊天室 ID',
                buttonText: 'Join',
                onPressed: () {
                  print('Joining Room: ${_roomIdController.text}');
                },
                isDark: isDark,
              ),
              const SizedBox(height: 20),
              _buildInputRow(
                controller: _messageController,
                hintText: '输入消息内容',
                buttonText: 'Send',
                onPressed: () {
                  print('Sending Message: ${_messageController.text}');
                },
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputRow({
    required TextEditingController controller,
    required String hintText,
    required String buttonText,
    required VoidCallback onPressed,
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
          child: Text(buttonText),
        ),
      ],
    );
  }
}
