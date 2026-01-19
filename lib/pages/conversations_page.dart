import 'package:em_chat_uikit/chat_uikit/chat_uikit.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ConversationsPage extends StatefulWidget {
  final bool isDark;
  const ConversationsPage({super.key, required this.isDark});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '会话',
          style: TextStyle(color: AppColors.textPrimary(widget.isDark)),
        ),
        centerTitle: true,
      ),
      body: ConversationsView(enableAppBar: false, enableSearchBar: false),
    );
  }
}
