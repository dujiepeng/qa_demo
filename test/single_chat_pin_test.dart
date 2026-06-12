import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/pages/single/single_chat_page.dart';

void main() {
  test('single chat pin event matches current conversation only', () {
    expect(
      isSingleChatPinEventForCurrentConversation(
        currentUserId: 'Alice ',
        conversationId: 'alice',
      ),
      isTrue,
    );
    expect(
      isSingleChatPinEventForCurrentConversation(
        currentUserId: 'alice',
        conversationId: 'bob',
      ),
      isFalse,
    );
    expect(
      isSingleChatPinEventForCurrentConversation(
        currentUserId: '',
        conversationId: 'alice',
      ),
      isFalse,
    );
  });

  testWidgets(
    'single chat pin event does not fallback when message is absent',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SingleChatPage(
            userId: 'alice',
            showAppBar: false,
            messageLoader: (_) async => null,
            messagePinInfoLoader: (_) async => null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final handler = EMClient.getInstance.chatManager.getEventHandler(
        'single_test',
      );
      handler?.onMessagePinChanged?.call(
        'missing-msg',
        'alice',
        MessagePinOperation.Pin,
        MessagePinInfo(pinTime: 1, operatorId: 'bob'),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('收到置顶通知'), findsNothing);
    },
  );

  testWidgets('single chat log action forwards one message body and ext', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    EMMessage? sentMessage;
    EMMessage? sourceMessage;

    await tester.pumpWidget(
      MaterialApp(
        home: SingleChatPage(
          userId: 'alice',
          showAppBar: false,
          messageLoader: (_) async => sourceMessage,
          messagePinInfoLoader: (_) async => null,
          messageSender: (message) async {
            sentMessage = message;
            return message;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(SingleChatPage)) as dynamic;
    final message = EMMessage.fromJson({
      'from': 'alice',
      'to': 'bob',
      'body': {
        'type': MessageType.TXT.index,
        'content': 'single forward source',
      },
      'direction': MessageDirection.RECEIVE.index,
      'hasRead': false,
      'hasReadAck': false,
      'hasDeliverAck': false,
      'msgId': 'msg-single-forward-001',
      'convId': 'alice',
      'chatType': ChatType.Chat.index,
      'status': MessageStatus.SUCCESS.index,
      'attributes': {'qa_ext': 'single_forward', 'qa_count': 1},
    });
    sourceMessage = message;
    state.addReceiveLog(
      'alice: single forward source',
      attachment: message,
      tag: 'message',
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.textContaining('single forward source'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('转发'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, '目标 ID'), 'charlie');
    await tester.enterText(find.widgetWithText(TextField, '类型'), 'chat');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(sentMessage, isNotNull);
    expect(sentMessage!.to, 'charlie');
    expect(sentMessage!.conversationId, 'charlie');
    expect(sentMessage!.chatType, ChatType.Chat);
    expect(sentMessage!.body, same(message.body));
    expect(sentMessage!.attributes, equals(message.attributes));
    expect(sentMessage!.attributes, isNot(same(message.attributes)));
    expect(find.textContaining('转发消息:'), findsOneWidget);
  });

  testWidgets('single chat combine forward pre-fills matching message ids', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    EMMessage? sentMessage;

    await tester.pumpWidget(
      MaterialApp(
        home: SingleChatPage(
          userId: 'alice',
          showAppBar: false,
          messageLoader: (_) async => null,
          messagePinInfoLoader: (_) async => null,
          messageSender: (message) async {
            sentMessage = message;
            return message;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(SingleChatPage)) as dynamic;
    state.addReceiveLog(
      'alice: single combine first',
      attachment: EMMessage.fromJson({
        'from': 'alice',
        'to': 'bob',
        'body': {'type': MessageType.TXT.index, 'content': 'first'},
        'direction': MessageDirection.RECEIVE.index,
        'hasRead': false,
        'hasReadAck': false,
        'hasDeliverAck': false,
        'msgId': 'single-local-a',
        'convId': 'alice',
        'chatType': ChatType.Chat.index,
        'status': MessageStatus.SUCCESS.index,
      }),
      tag: 'message',
    );
    state.addReceiveLog(
      'alice: single combine second',
      attachment: EMMessage.fromJson({
        'from': 'alice',
        'to': 'bob',
        'body': {'type': MessageType.TXT.index, 'content': 'second'},
        'direction': MessageDirection.RECEIVE.index,
        'hasRead': false,
        'hasReadAck': false,
        'hasDeliverAck': false,
        'msgId': 'single-local-b',
        'convId': 'alice',
        'chatType': ChatType.Chat.index,
        'status': MessageStatus.SUCCESS.index,
      }),
      tag: 'message',
    );
    state.addReceiveLog(
      'alice: single combine failed',
      attachment: EMMessage.fromJson({
        'from': 'alice',
        'to': 'bob',
        'body': {'type': MessageType.TXT.index, 'content': 'failed'},
        'direction': MessageDirection.SEND.index,
        'hasRead': false,
        'hasReadAck': false,
        'hasDeliverAck': false,
        'msgId': 'single-local-failed',
        'convId': 'alice',
        'chatType': ChatType.Chat.index,
        'status': MessageStatus.FAIL.index,
      }),
      tag: 'message',
    );
    state.addReceiveLog(
      'group: wrong type',
      attachment: EMMessage.fromJson({
        'from': 'alice',
        'to': 'group-001',
        'body': {'type': MessageType.TXT.index, 'content': 'group'},
        'direction': MessageDirection.RECEIVE.index,
        'hasRead': false,
        'hasReadAck': false,
        'hasDeliverAck': false,
        'msgId': 'group-local-a',
        'convId': 'group-001',
        'chatType': ChatType.GroupChat.index,
        'status': MessageStatus.SUCCESS.index,
      }),
      tag: 'message',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('合并转发'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, '目标 ID'), 'bob');
    await tester.enterText(find.widgetWithText(TextField, '类型'), 'chat');
    final idsInput = tester.widget<TextField>(
      find.widgetWithText(TextField, '消息 ID 列表'),
    );
    expect(idsInput.controller?.text, 'single-local-b\nsingle-local-a');
    await tester.enterText(find.widgetWithText(TextField, '标题'), '聊天记录');
    await tester.enterText(
      find.widgetWithText(TextField, '摘要'),
      'Alice: hello',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '兼容文本'),
      '当前版本不支持合并消息',
    );
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(sentMessage, isNotNull);
    expect(sentMessage!.to, 'bob');
    expect(sentMessage!.conversationId, 'bob');
    expect(sentMessage!.chatType, ChatType.Chat);
    expect(sentMessage!.body, isA<EMCombineMessageBody>());

    final bodyJson = sentMessage!.body.toJson();
    expect(bodyJson['messageList'], ['single-local-b', 'single-local-a']);
    expect(bodyJson['messageList'], isNot(contains('single-local-failed')));
    expect(bodyJson['messageList'], isNot(contains('group-local-a')));
    expect(bodyJson['title'], '聊天记录');
    expect(bodyJson['summary'], 'Alice: hello');
    expect(bodyJson['compatibleText'], '当前版本不支持合并消息');
    expect(find.textContaining('合并转发消息:'), findsOneWidget);
  });

  testWidgets('single chat log action resends message through SDK callback', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    EMMessage? resentSource;

    await tester.pumpWidget(
      MaterialApp(
        home: SingleChatPage(
          userId: 'alice',
          showAppBar: false,
          messageLoader: (_) async => null,
          messagePinInfoLoader: (_) async => null,
          messageResender: (message) async {
            resentSource = message;
            return EMMessage.fromJson({
              'from': 'bob',
              'to': 'alice',
              'body': {'type': MessageType.TXT.index, 'content': 'resend me'},
              'direction': MessageDirection.SEND.index,
              'hasRead': false,
              'hasReadAck': false,
              'hasDeliverAck': false,
              'msgId': 'msg-resend-001',
              'convId': 'alice',
              'chatType': ChatType.Chat.index,
              'status': MessageStatus.SUCCESS.index,
            });
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(SingleChatPage)) as dynamic;
    final failedMessage = EMMessage.fromJson({
      'from': 'bob',
      'to': 'alice',
      'body': {'type': MessageType.TXT.index, 'content': 'resend me'},
      'direction': MessageDirection.SEND.index,
      'hasRead': false,
      'hasReadAck': false,
      'hasDeliverAck': false,
      'msgId': 'msg-resend-001',
      'convId': 'alice',
      'chatType': ChatType.Chat.index,
      'status': MessageStatus.FAIL.index,
    });
    state.addSendLog(
      'bob: resend me',
      attachment: failedMessage,
      tag: 'message',
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.textContaining('resend me'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('重发'));
    await tester.pumpAndSettle();

    expect(resentSource, same(failedMessage));
    expect(find.textContaining('重发消息:'), findsOneWidget);
    expect(find.textContaining('msg-resend-001'), findsOneWidget);
  });

  testWidgets('single chat log actions call server-backed message APIs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final calls = <String, Object?>{};
    EMMessage? sourceMessage;

    await tester.pumpWidget(
      MaterialApp(
        home: SingleChatPage(
          userId: 'alice',
          showAppBar: false,
          messageLoader: (_) async => sourceMessage,
          messagePinInfoLoader: (_) async => null,
          attachmentDownloader: (message) async {
            calls['attachment'] = message.msgId;
          },
          thumbnailDownloader: (message) async {
            calls['thumbnail'] = message.msgId;
          },
          combineAttachmentDownloader: (message) async {
            calls['combineAttachment'] = message.msgId;
          },
          combineThumbnailDownloader: (message) async {
            calls['combineThumbnail'] = message.msgId;
          },
          combineMessageDetailFetcher: (message) async {
            calls['combineDetail'] = message.msgId;
            return [
              EMMessage.fromJson({
                'from': 'alice',
                'to': 'bob',
                'body': {'type': MessageType.TXT.index, 'content': 'child'},
                'direction': MessageDirection.RECEIVE.index,
                'hasRead': false,
                'hasReadAck': false,
                'hasDeliverAck': false,
                'msgId': 'msg-child',
                'convId': 'alice',
                'chatType': ChatType.Chat.index,
                'status': MessageStatus.SUCCESS.index,
              }),
            ];
          },
          reactionListFetcher:
              ({required messageIds, required chatType, groupId}) async {
                calls['reactionList'] = [messageIds, chatType, groupId];
                return const <String, List<EMMessageReaction>>{};
              },
          reactionDetailFetcher:
              ({
                required messageId,
                required reaction,
                cursor,
                pageSize = 20,
              }) async {
                calls['reactionDetail'] = [
                  messageId,
                  reaction,
                  cursor,
                  pageSize,
                ];
                return EMCursorResult<EMMessageReaction>('', const []);
              },
          supportedLanguagesFetcher: () async {
            calls['languages'] = true;
            return <EMTranslateLanguage>[];
          },
          messageReporter:
              ({required messageId, required tag, required reason}) async {
                calls['report'] = [messageId, tag, reason];
              },
          messageTranslator: ({required msg, required languages}) async {
            calls['translate'] = [msg.msgId, languages];
            return msg;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final state = tester.state(find.byType(SingleChatPage)) as dynamic;
    sourceMessage = EMMessage.fromJson({
      'from': 'alice',
      'to': 'bob',
      'body': {'type': MessageType.TXT.index, 'content': 'server api msg'},
      'direction': MessageDirection.RECEIVE.index,
      'hasRead': false,
      'hasReadAck': false,
      'hasDeliverAck': false,
      'msgId': 'msg-server-api',
      'convId': 'alice',
      'chatType': ChatType.Chat.index,
      'status': MessageStatus.SUCCESS.index,
    });
    state.addReceiveLog(
      'alice: server api msg',
      attachment: sourceMessage,
      tag: 'message',
    );
    await tester.pumpAndSettle();

    Future<void> runAction(String label) async {
      await tester.longPress(find.textContaining('server api msg'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    await runAction('下附件');
    await runAction('下缩略图');
    await runAction('合并附件');
    await runAction('合并缩略');
    await runAction('合并详情');
    await runAction('Reaction列表');
    await runAction('Reaction详情');
    await runAction('语言列表');
    await runAction('举报');
    await tester.enterText(find.widgetWithText(TextField, '举报标签'), 'ad');
    await tester.enterText(find.widgetWithText(TextField, '举报原因'), 'spam');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    await runAction('翻译');
    await tester.enterText(find.widgetWithText(TextField, '语言'), 'en,zh-Hans');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(calls['attachment'], 'msg-server-api');
    expect(calls['thumbnail'], 'msg-server-api');
    expect(calls['combineAttachment'], 'msg-server-api');
    expect(calls['combineThumbnail'], 'msg-server-api');
    expect(calls['combineDetail'], 'msg-server-api');
    expect(calls['reactionList'], [
      ['msg-server-api'],
      ChatType.Chat,
      null,
    ]);
    expect(calls['reactionDetail'], ['msg-server-api', '👍', null, 20]);
    expect(calls['languages'], true);
    expect(calls['report'], ['msg-server-api', 'ad', 'spam']);
    expect(calls['translate'], [
      'msg-server-api',
      ['en', 'zh-Hans'],
    ]);
    expect(find.textContaining('合并消息详情: msg-child'), findsOneWidget);
  });

  testWidgets(
    'single chat download action reports start instead of false success',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      EMMessage? downloadedMessage;

      await tester.pumpWidget(
        MaterialApp(
          home: SingleChatPage(
            userId: 'alice',
            showAppBar: false,
            messageLoader: (_) async => null,
            messagePinInfoLoader: (_) async => null,
            attachmentDownloader: (message) async {
              downloadedMessage = message;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state(find.byType(SingleChatPage)) as dynamic;
      final message = EMMessage.fromJson({
        'from': 'alice',
        'to': 'bob',
        'body': {
          'type': MessageType.FILE.index,
          'localPath': '',
          'displayName': 'qa.txt',
          'fileStatus': DownloadStatus.PENDING.index,
        },
        'direction': MessageDirection.RECEIVE.index,
        'hasRead': false,
        'hasReadAck': false,
        'hasDeliverAck': false,
        'msgId': 'msg-download-001',
        'convId': 'alice',
        'chatType': ChatType.Chat.index,
        'status': MessageStatus.SUCCESS.index,
      });
      state.addReceiveLog(
        'alice: file message',
        attachment: message,
        tag: 'message',
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.textContaining('file message'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('下附件'));
      await tester.pumpAndSettle();

      expect(downloadedMessage, same(message));
      expect(find.textContaining('附件下载已发起'), findsOneWidget);
      expect(find.textContaining('附件已下载'), findsNothing);
      expect(find.textContaining('下载附件成功'), findsNothing);
    },
  );

  testWidgets('single chat imports and inserts local text messages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    List<EMMessage>? importedMessages;
    String? requestedConversationId;
    EMConversationType? requestedConversationType;
    EMMessage? insertedMessage;

    await tester.pumpWidget(
      MaterialApp(
        home: SingleChatPage(
          userId: 'alice',
          showAppBar: false,
          messageLoader: (_) async => null,
          messagePinInfoLoader: (_) async => null,
          messageImporter: (messages) async {
            importedMessages = messages;
          },
          conversationGetter:
              (
                conversationId, {
                type = EMConversationType.Chat,
                createIfNeed = true,
              }) async {
                requestedConversationId = conversationId;
                requestedConversationType = type;
                return EMConversation.fromJson({
                  'convId': conversationId,
                  'type': type.index,
                });
              },
          conversationMessageInserter: (conversation, message) async {
            insertedMessage = message;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('导入消息'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '消息内容'), 'imported');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(importedMessages, isNotNull);
    expect(importedMessages, hasLength(1));
    expect(importedMessages!.single.conversationId, 'alice');
    expect(importedMessages!.single.chatType, ChatType.Chat);
    expect(importedMessages!.single.body, isA<EMTextMessageBody>());
    expect(
      (importedMessages!.single.body as EMTextMessageBody).content,
      'imported',
    );
    expect(find.textContaining('导入消息成功'), findsOneWidget);

    await tester.tap(find.text('插入消息'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '消息内容'), 'inserted');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(requestedConversationId, 'alice');
    expect(requestedConversationType, EMConversationType.Chat);
    expect(insertedMessage, isNotNull);
    expect(insertedMessage!.conversationId, 'alice');
    expect(insertedMessage!.chatType, ChatType.Chat);
    expect((insertedMessage!.body as EMTextMessageBody).content, 'inserted');
    expect(find.textContaining('插入消息成功'), findsOneWidget);
  });
}
