import 'package:em_chat_uikit/chat_uikit.dart';

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage>
    with ChatUIKitThemeMixin {
  @override
  Widget themeBuilder(BuildContext context, ChatUIKitTheme theme) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('会话', style: TextStyle(color: AppColors.textPrimary(true))),
        centerTitle: true,
      ),
      body: Container(),
    );
  }
}
