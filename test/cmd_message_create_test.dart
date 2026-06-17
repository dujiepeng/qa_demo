import 'package:flutter_test/flutter_test.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/pages/chatroom/room_page.dart';
import 'package:qa_flutter/pages/group/group_page.dart';
import 'package:qa_flutter/pages/single/single_chat_page.dart';

void main() {
  test('single chat command message uses action1', () {
    final message = createSingleChatCommandMessage('user1');

    expect(message.to, 'user1');
    expect(message.chatType, ChatType.Chat);
    expect(message.body, isA<EMCmdMessageBody>());
    expect((message.body as EMCmdMessageBody).action, 'action1');
  });

  test('group command message uses group chat type', () {
    final message = createGroupCommandMessage('group1');

    expect(message.to, 'group1');
    expect(message.chatType, ChatType.GroupChat);
    expect(message.body, isA<EMCmdMessageBody>());
    expect((message.body as EMCmdMessageBody).action, 'action1');
  });

  test('chatroom command message uses chatroom type', () {
    final message = createChatRoomCommandMessage('room1');

    expect(message.to, 'room1');
    expect(message.chatType, ChatType.ChatRoom);
    expect(message.body, isA<EMCmdMessageBody>());
    expect((message.body as EMCmdMessageBody).action, 'action1');
  });
}
