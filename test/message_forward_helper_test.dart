import 'package:flutter_test/flutter_test.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/common/utils/message_forward_helper.dart';
import 'package:qa_flutter/common/widgets/log_view.dart';

void main() {
  test('createForwardMessage copies body and ext to target conversation', () {
    final source = EMMessage.createTxtSendMessage(
      targetId: 'alice',
      content: 'hello',
    );
    source.attributes = {
      'str': 'value',
      'int': 1,
      'bool': true,
      'double': 1.5,
      'list': ['a', 'b'],
      'map': {'k': 'v'},
    };

    final forwarded = createForwardMessage(
      source: source,
      targetId: 'group-001',
      chatType: ChatType.GroupChat,
    );

    expect(forwarded.to, 'group-001');
    expect(forwarded.conversationId, 'group-001');
    expect(forwarded.chatType, ChatType.GroupChat);
    expect(forwarded.body, same(source.body));
    expect(forwarded.attributes, equals(source.attributes));
    expect(forwarded.attributes, isNot(same(source.attributes)));
  });

  test('parseForwardChatType accepts qa aliases', () {
    expect(parseForwardChatType('chat'), ChatType.Chat);
    expect(parseForwardChatType('单聊'), ChatType.Chat);
    expect(parseForwardChatType('group'), ChatType.GroupChat);
    expect(parseForwardChatType('群聊'), ChatType.GroupChat);
    expect(parseForwardChatType('room'), ChatType.ChatRoom);
    expect(parseForwardChatType('聊天室'), ChatType.ChatRoom);
  });

  test('createCombineForwardMessage builds combine body from message ids', () {
    final forwarded = createCombineForwardMessage(
      targetId: 'bob',
      chatType: ChatType.Chat,
      msgIds: parseForwardMessageIds('msg-1, msg-2\nmsg-3'),
      title: '合并标题',
      summary: '合并摘要',
      compatibleText: '当前版本不支持合并消息',
    );

    expect(forwarded.to, 'bob');
    expect(forwarded.conversationId, 'bob');
    expect(forwarded.chatType, ChatType.Chat);
    expect(forwarded.body, isA<EMCombineMessageBody>());

    final bodyJson = forwarded.body.toJson();
    expect(bodyJson['title'], '合并标题');
    expect(bodyJson['summary'], '合并摘要');
    expect(bodyJson['compatibleText'], '当前版本不支持合并消息');
    expect(bodyJson['messageList'], ['msg-1', 'msg-2', 'msg-3']);
  });

  test('parseForwardMessageIds rejects empty message id list', () {
    expect(() => parseForwardMessageIds(' , \n '), throwsArgumentError);
  });

  test(
    'successfulLocalMessageIdsForCombineForward filters real message logs',
    () {
      final entries = [
        LogEntry(
          content: 'newest',
          timestamp: '1',
          tag: 'message',
          attachment: _message(
            msgId: 'msg-b',
            conversationId: 'alice',
            chatType: ChatType.Chat,
          ),
        ),
        LogEntry(
          content: 'duplicate',
          timestamp: '2',
          tag: 'message',
          attachment: _message(
            msgId: 'msg-b',
            conversationId: 'alice',
            chatType: ChatType.Chat,
          ),
        ),
        LogEntry(
          content: 'older',
          timestamp: '3',
          tag: 'message',
          attachment: _message(
            msgId: 'msg-a',
            conversationId: 'alice',
            chatType: ChatType.Chat,
          ),
        ),
        LogEntry(
          content: 'failed',
          timestamp: '4',
          tag: 'message',
          attachment: _message(
            msgId: 'msg-failed',
            conversationId: 'alice',
            chatType: ChatType.Chat,
            status: MessageStatus.FAIL,
          ),
        ),
        LogEntry(
          content: 'wrong conversation',
          timestamp: '5',
          tag: 'message',
          attachment: _message(
            msgId: 'msg-other',
            conversationId: 'bob',
            chatType: ChatType.Chat,
          ),
        ),
        LogEntry(
          content: 'wrong type',
          timestamp: '6',
          tag: 'message',
          attachment: _message(
            msgId: 'msg-group',
            conversationId: 'alice',
            chatType: ChatType.GroupChat,
          ),
        ),
        LogEntry(content: 'plain log', timestamp: '7', tag: 'message'),
      ];

      expect(
        successfulLocalMessageIdsForCombineForward(
          entries: entries,
          chatType: ChatType.Chat,
          conversationId: 'alice',
        ),
        ['msg-b', 'msg-a'],
      );
    },
  );
}

EMMessage _message({
  required String msgId,
  required String conversationId,
  required ChatType chatType,
  MessageStatus status = MessageStatus.SUCCESS,
}) {
  return EMMessage.fromJson({
    'from': 'alice',
    'to': conversationId,
    'body': {'type': MessageType.TXT.index, 'content': msgId},
    'direction': MessageDirection.RECEIVE.index,
    'hasRead': false,
    'hasReadAck': false,
    'hasDeliverAck': false,
    'msgId': msgId,
    'convId': conversationId,
    'chatType': chatType.index,
    'status': status.index,
  });
}
