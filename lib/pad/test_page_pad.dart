import 'package:flutter/material.dart';
import '../test_pages/single/test_single_chat_list_page.dart';
import '../test_pages/single/test_single_chat_page.dart';
import '../test_pages/group/test_group_list_page.dart';
import '../test_pages/group/test_group_page.dart';
import '../test_pages/chatroom/test_chat_room_list_page.dart';
import '../test_pages/chatroom/test_chat_room_page.dart';

class TestPagePad extends StatelessWidget {
  final TabController tabController;
  final Function(Widget page, String title) onShowDetail;

  const TestPagePad({
    super.key,
    required this.tabController,
    required this.onShowDetail,
  });

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: tabController,
      children: [
        TestSingleChatListPage(
          onItemTap: (id) => onShowDetail(
            TestSingleChatPage(userId: id, showAppBar: false),
            id.isEmpty ? '新建单聊' : '单聊: $id',
          ),
        ),
        TestGroupListPage(
          onItemTap: (id) => onShowDetail(
            TestGroupPage(groupId: id, showAppBar: false),
            id.isEmpty ? '加入群组' : '群组: $id',
          ),
        ),
        TestChatRoomListPage(
          onItemTap: (id) => onShowDetail(
            TestChatRoomPage(roomId: id, showAppBar: false),
            id.isEmpty ? '加入聊天室' : '聊天室: $id',
          ),
        ),
      ],
    );
  }
}
