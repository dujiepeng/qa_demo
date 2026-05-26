import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/pages/chatroom/room_page.dart';

void main() {
  group('parseChatRoomReceiverList', () {
    test('returns null for blank input so message targets all members', () {
      expect(parseChatRoomReceiverList('  \n '), isNull);
    });

    test('splits comma whitespace and newline separated user IDs', () {
      expect(
        parseChatRoomReceiverList('alice, bob，charlie\n dave'),
        ['alice', 'bob', 'charlie', 'dave'],
      );
    });

    test('deduplicates repeated user IDs while preserving order', () {
      expect(
        parseChatRoomReceiverList('alice bob alice charlie bob'),
        ['alice', 'bob', 'charlie'],
      );
    });
  });

  group('chatroom recall helpers', () {
    test('matches recall info by conversation ID', () {
      const info = RecallMessageInfo(
        recallBy: 'alice',
        recallMessageId: 'msg-001',
        conversationId: 'room-001',
        ext: 'recall-ext',
      );

      expect(isChatRoomRecallForRoom(info, 'room-001'), isTrue);
      expect(isChatRoomRecallForRoom(info, 'room-002'), isFalse);
    });

    test('builds recall log with operator message id and ext', () {
      const info = RecallMessageInfo(
        recallBy: 'alice',
        recallMessageId: 'msg-001',
        conversationId: 'room-001',
        ext: 'recall-ext',
      );

      expect(
        buildChatRoomRecallLog(info),
        '收到聊天室消息撤回: msgId=msg-001, recallBy=alice, ext=recall-ext',
      );
    });
  });

  testWidgets('selects chatroom members and fills targeted receiver input', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RoomPage(
          roomId: 'room-001',
          showAppBar: false,
          chatRoomMembersLoader: (_, {cursor = '', pageSize = 50}) async =>
              EMCursorResult<String>('', const ['alice', 'bob', 'charlie']),
        ),
      ),
    );

    await tester.tap(find.text('选择'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('alice'));
    await tester.tap(find.text('charlie'));
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    final receiverField = tester.widget<TextField>(
      find.widgetWithText(TextField, '定向接收人，最多20个，空则发全体'),
    );
    expect(receiverField.controller?.text, 'alice, charlie');
  });

  testWidgets('select all fills loaded chatroom members up to receiver limit', (
    tester,
  ) async {
    final members = List<String>.generate(25, (index) => 'user$index');

    await tester.pumpWidget(
      MaterialApp(
        home: RoomPage(
          roomId: 'room-001',
          showAppBar: false,
          chatRoomMembersLoader: (_, {cursor = '', pageSize = 50}) async =>
              EMCursorResult<String>('', members),
        ),
      ),
    );

    await tester.tap(find.text('选择'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('全选'));
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    final receiverField = tester.widget<TextField>(
      find.widgetWithText(TextField, '定向接收人，最多20个，空则发全体'),
    );
    expect(receiverField.controller?.text, members.take(20).join(', '));
  });

  testWidgets('chatroom message log supports editing sent text messages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? modifiedMessageId;
    String? modifiedContent;

    await tester.pumpWidget(
      MaterialApp(
        home: RoomPage(
          roomId: 'room-001',
          showAppBar: false,
          messageModifier:
              ({
                required messageId,
                msgBody,
                Map<String, dynamic>? attributes,
              }) async {
                modifiedMessageId = messageId;
                modifiedContent = (msgBody as EMTextMessageBody).content;
                return _buildChatRoomTextMessage(
                  content: modifiedContent!,
                  msgId: messageId,
                );
              },
        ),
      ),
    );

    final state = tester.state(find.byType(RoomPage)) as dynamic;
    state.addSendLog(
      'alice: old content',
      attachment: _buildChatRoomTextMessage(content: 'old content'),
      tag: 'message',
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.textContaining('old content'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('修改'));
    await tester.pumpAndSettle();

    expect(modifiedMessageId, 'msg-1');
    expect(modifiedContent, chatRoomMessageEditContent);
    expect(find.text('已编辑'), findsOneWidget);
    expect(find.textContaining(chatRoomMessageEditContent), findsOneWidget);
  });

  testWidgets('chatroom sent text messages show edit action by body class', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final message = _buildChatRoomTextMessage(content: 'typed content');
    message.body.type = MessageType.CMD;

    await tester.pumpWidget(
      const MaterialApp(
        home: RoomPage(roomId: 'room-001', showAppBar: false),
      ),
    );

    final state = tester.state(find.byType(RoomPage)) as dynamic;
    state.addSendLog(
      'alice: typed content',
      attachment: message,
      tag: 'message',
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.textContaining('typed content'));
    await tester.pumpAndSettle();

    expect(find.text('修改'), findsOneWidget);
    expect(find.text('撤回'), findsOneWidget);
  });

  testWidgets('chatroom message edit updates ext for file-like messages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? modifiedMessageId;
    EMMessageBody? modifiedBody;
    Map<String, dynamic>? modifiedAttributes;

    await tester.pumpWidget(
      MaterialApp(
        home: RoomPage(
          roomId: 'room-001',
          showAppBar: false,
          messageModifier:
              ({
                required messageId,
                msgBody,
                Map<String, dynamic>? attributes,
              }) async {
                modifiedMessageId = messageId;
                modifiedBody = msgBody;
                modifiedAttributes = attributes;
                return _buildChatRoomFileMessage(
                  msgId: messageId,
                  attributes: attributes,
                );
              },
        ),
      ),
    );

    final state = tester.state(find.byType(RoomPage)) as dynamic;
    state.addSendLog(
      'alice: file message',
      attachment: _buildChatRoomFileMessage(
        attributes: {'origin': 'old'},
      ),
      tag: 'message',
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.textContaining('file message'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('修改'));
    await tester.pumpAndSettle();

    expect(modifiedMessageId, 'msg-1');
    expect(modifiedBody, isNull);
    expect(modifiedAttributes?['origin'], 'old');
    expect(modifiedAttributes?['qa_chatroom_edit'], chatRoomMessageEditExtValue);
    expect(find.text('已编辑'), findsOneWidget);
  });

  testWidgets('chatroom custom message edit updates body and ext', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    EMMessageBody? modifiedBody;
    Map<String, dynamic>? modifiedAttributes;

    await tester.pumpWidget(
      MaterialApp(
        home: RoomPage(
          roomId: 'room-001',
          showAppBar: false,
          messageModifier:
              ({
                required messageId,
                msgBody,
                Map<String, dynamic>? attributes,
              }) async {
                modifiedBody = msgBody;
                modifiedAttributes = attributes;
                return _buildChatRoomCustomMessage(
                  msgId: messageId,
                  attributes: attributes,
                );
              },
        ),
      ),
    );

    final state = tester.state(find.byType(RoomPage)) as dynamic;
    state.addSendLog(
      'alice: custom message',
      attachment: _buildChatRoomCustomMessage(attributes: {'origin': 'old'}),
      tag: 'message',
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.textContaining('custom message'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('修改'));
    await tester.pumpAndSettle();

    expect(modifiedBody, isA<EMCustomMessageBody>());
    final customBody = modifiedBody as EMCustomMessageBody;
    expect(customBody.event, chatRoomMessageEditCustomEvent);
    expect(customBody.params?['old'], 'value');
    expect(customBody.params?['content'], chatRoomMessageEditContent);
    expect(modifiedAttributes?['origin'], 'old');
    expect(modifiedAttributes?['qa_chatroom_edit'], chatRoomMessageEditExtValue);
  });

  testWidgets('chatroom command messages do not show edit action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: RoomPage(roomId: 'room-001', showAppBar: false),
      ),
    );

    final state = tester.state(find.byType(RoomPage)) as dynamic;
    state.addSendLog(
      'alice: cmd message',
      attachment: _buildChatRoomCommandMessage(),
      tag: 'message',
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.textContaining('cmd message'));
    await tester.pumpAndSettle();

    expect(find.text('修改'), findsNothing);
  });

  testWidgets('chatroom received messages do not show recall action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: RoomPage(roomId: 'room-001', showAppBar: false),
      ),
    );

    final state = tester.state(find.byType(RoomPage)) as dynamic;
    state.addReceiveLog(
      'bob: received message',
      attachment: _buildChatRoomTextMessage(
        content: 'received message',
        direction: MessageDirection.RECEIVE,
      ),
      tag: 'message',
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.textContaining('received message'));
    await tester.pumpAndSettle();

    expect(find.text('撤回'), findsNothing);
  });

  testWidgets('chatroom sent messages show recall action', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: RoomPage(roomId: 'room-001', showAppBar: false),
      ),
    );

    final state = tester.state(find.byType(RoomPage)) as dynamic;
    state.addSendLog(
      'alice: sent message',
      attachment: _buildChatRoomTextMessage(content: 'sent message'),
      tag: 'message',
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.textContaining('sent message'));
    await tester.pumpAndSettle();

    expect(find.text('撤回'), findsOneWidget);
  });

  testWidgets('chatroom message log removes server history by message id', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? removedConversationId;
    EMConversationType? removedConversationType;
    List<String>? removedMessageIds;

    await tester.pumpWidget(
      MaterialApp(
        home: RoomPage(
          roomId: 'room-001',
          showAppBar: false,
          remoteMessageRemover:
              ({required conversationId, required type, required msgIds}) async {
                removedConversationId = conversationId;
                removedConversationType = type;
                removedMessageIds = msgIds;
              },
        ),
      ),
    );

    final state = tester.state(find.byType(RoomPage)) as dynamic;
    state.addSendLog(
      'alice: delete server history',
      attachment: _buildChatRoomTextMessage(
        content: 'delete server history',
        msgId: 'msg-delete-1',
      ),
      tag: 'message',
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.textContaining('delete server history'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删服务端'));
    await tester.pumpAndSettle();

    expect(removedConversationId, 'room-001');
    expect(removedConversationType, EMConversationType.ChatRoom);
    expect(removedMessageIds, ['msg-delete-1']);
    expect(find.text('已删服务端'), findsOneWidget);
  });

  testWidgets('chatroom message log removes server history before server time', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? removedConversationId;
    EMConversationType? removedConversationType;
    int? removedTimestamp;

    await tester.pumpWidget(
      MaterialApp(
        home: RoomPage(
          roomId: 'room-001',
          showAppBar: false,
          remoteMessageBeforeTimeRemover:
              ({required conversationId, required type, required timestamp}) async {
                removedConversationId = conversationId;
                removedConversationType = type;
                removedTimestamp = timestamp;
              },
        ),
      ),
    );

    final state = tester.state(find.byType(RoomPage)) as dynamic;
    state.addSendLog(
      'alice: delete before server time',
      attachment: _buildChatRoomTextMessage(
        content: 'delete before server time',
        msgId: 'msg-delete-time-1',
        serverTime: 1710000000000,
      ),
      tag: 'message',
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.textContaining('delete before server time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('按时间删'));
    await tester.pumpAndSettle();

    expect(removedConversationId, 'room-001');
    expect(removedConversationType, EMConversationType.ChatRoom);
    expect(removedTimestamp, 1710000000000);
    expect(find.text('已按时间删服务端'), findsOneWidget);
  });
}

EMMessage _buildChatRoomTextMessage({
  required String content,
  String msgId = 'msg-1',
  MessageDirection direction = MessageDirection.SEND,
  int? serverTime,
}) {
  return EMMessage.fromJson({
    'to': 'room-001',
    'from': 'alice',
    'body': {'type': MessageType.TXT.index, 'content': content},
    'direction': direction.index,
    'msgId': msgId,
    'convId': 'room-001',
    'chatType': ChatType.ChatRoom.index,
    'status': MessageStatus.SUCCESS.index,
    'serverTime': serverTime,
  });
}

EMMessage _buildChatRoomFileMessage({
  String msgId = 'msg-1',
  Map<String, dynamic>? attributes,
}) {
  return EMMessage.fromJson({
    'to': 'room-001',
    'from': 'alice',
    'body': {
      'type': MessageType.FILE.index,
      'localPath': '/tmp/file.txt',
      'displayName': 'file.txt',
      'fileStatus': DownloadStatus.SUCCESS.index,
    },
    'attributes': attributes,
    'direction': MessageDirection.SEND.index,
    'msgId': msgId,
    'convId': 'room-001',
    'chatType': ChatType.ChatRoom.index,
    'status': MessageStatus.SUCCESS.index,
  });
}

EMMessage _buildChatRoomCustomMessage({
  String msgId = 'msg-1',
  Map<String, dynamic>? attributes,
}) {
  return EMMessage.fromJson({
    'to': 'room-001',
    'from': 'alice',
    'body': {
      'type': MessageType.CUSTOM.index,
      'event': 'old_event',
      'params': {'old': 'value'},
    },
    'attributes': attributes,
    'direction': MessageDirection.SEND.index,
    'msgId': msgId,
    'convId': 'room-001',
    'chatType': ChatType.ChatRoom.index,
    'status': MessageStatus.SUCCESS.index,
  });
}

EMMessage _buildChatRoomCommandMessage() {
  return EMMessage.fromJson({
    'to': 'room-001',
    'from': 'alice',
    'body': {
      'type': MessageType.CMD.index,
      'action': 'qa_cmd',
    },
    'direction': MessageDirection.SEND.index,
    'msgId': 'cmd-1',
    'convId': 'room-001',
    'chatType': ChatType.ChatRoom.index,
    'status': MessageStatus.SUCCESS.index,
  });
}
