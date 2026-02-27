import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import '../pages/conversation/conversation_list_page.dart';
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
        ConversationListPage(
          onItemTap: (conv) {
            Widget page;
            String title;
            switch (conv.type) {
              case EMConversationType.Chat:
                page = SingleChatPage(userId: conv.id, showAppBar: false);
                title = '单聊: ${conv.id}';
                break;
              case EMConversationType.GroupChat:
                page = GroupPage(groupId: conv.id, showAppBar: false);
                title = '群组: ${conv.id}';
                break;
              case EMConversationType.ChatRoom:
                page = RoomPage(roomId: conv.id, showAppBar: false);
                title = '聊天室: ${conv.id}';
                break;
            }
            onShowDetail(page, title);
          },
        ),
        SingleChatListPage(
          onItemTap: (id) => onShowDetail(
            SingleChatPage(userId: id, showAppBar: false),
            id.isEmpty ? '新建单聊' : '单聊: $id',
          ),
        ),
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
      ],
    );
  }
}
