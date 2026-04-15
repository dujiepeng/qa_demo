import 'package:flutter/material.dart';
import '../pages/conversation/conversation_list_page.dart';
import '../pages/single/black_list_page.dart';
import '../pages/single/contact_presence_page.dart';
import '../pages/single/single_chat_list_page.dart';
import '../pages/single/single_chat_page.dart';
import '../pages/group/group_list_page.dart';
import '../pages/group/group_page.dart';
import '../pages/chatroom/room_list_page.dart';
import '../pages/chatroom/room_page.dart';

class PagePad extends StatelessWidget {
  final TabController tabController;
  final Function(Widget page, String title) onShowDetail;

  const PagePad({
    super.key,
    required this.tabController,
    required this.onShowDetail,
  });

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: tabController,
      children: [
        const ConversationListPage(),
        SingleChatListPage(
          onItemTap: (id) => onShowDetail(
            SingleChatPage(userId: id, showAppBar: false),
            id.isEmpty ? '新建单聊' : '单聊: $id',
          ),
        ),
        const ContactPresencePage(),
        GroupListPage(
          onItemTap: (id) => onShowDetail(
            GroupPage(groupId: id, showAppBar: false),
            id.isEmpty ? '加入群组' : '群组: $id',
          ),
        ),
        RoomListPage(
          onItemTap: (id) => onShowDetail(
            RoomPage(roomId: id, showAppBar: false),
            id.isEmpty ? '加入聊天室' : '聊天室: $id',
          ),
        ),
        BlackListPage(
          onItemTap: (id) => onShowDetail(
            SingleChatPage(userId: id, showAppBar: false),
            '黑名单: $id',
          ),
        ),
      ],
    );
  }
}
