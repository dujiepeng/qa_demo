import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/pages/thread/chat_thread_page.dart';

EMChatThread _thread(String id) => EMChatThread(
  threadId: id,
  threadName: 'Thread $id',
  owner: 'owner',
  messageId: 'msg-001',
  parentId: 'group-001',
  membersCount: 2,
  messageCount: 3,
  createAt: 1,
);

EMChatThread _threadWithParentMessage(String id, String messageId) =>
    EMChatThread(
      threadId: id,
      threadName: 'Thread $id',
      owner: 'owner',
      messageId: messageId,
      parentId: 'group-001',
      membersCount: 2,
      messageCount: 3,
      createAt: 1,
    );

void main() {
  void useLargeViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('thread page exposes event handler APIs', (tester) async {
    useLargeViewport(tester);
    final controller = ChatThreadTestController();

    await tester.pumpWidget(
      MaterialApp(
        home: ChatThreadPage(showAppBar: false, controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('注册事件'));
    await tester.pumpAndSettle();
    expect(controller.getEventHandler('thread_test'), isNotNull);
    expect(find.textContaining('Thread 事件监听已注册'), findsOneWidget);

    await tester.tap(find.text('取事件'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Thread 事件监听存在: true'), findsOneWidget);

    await tester.tap(find.text('移除事件'));
    await tester.pumpAndSettle();
    expect(controller.getEventHandler('thread_test'), isNull);
    expect(find.textContaining('Thread 事件监听已移除'), findsOneWidget);

    await tester.tap(find.text('注册事件'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('清空事件'));
    await tester.pumpAndSettle();
    expect(controller.getEventHandler('thread_test'), isNull);
    expect(find.textContaining('Thread 事件监听已清空'), findsOneWidget);
  });

  testWidgets('thread page calls server APIs with user inputs', (tester) async {
    useLargeViewport(tester);
    final calls = <String, Object?>{};
    final controller = ChatThreadTestController(
      createChatThread:
          ({required name, required messageId, required parentId}) async {
            calls['create'] = [name, messageId, parentId];
            return _thread('thread-created');
          },
      fetchChatThread: ({required chatThreadId}) async {
        calls['fetch'] = chatThreadId;
        return _thread(chatThreadId);
      },
      fetchChatThreadMembers:
          ({required chatThreadId, cursor, limit = 20}) async {
            calls['members'] = [chatThreadId, cursor, limit];
            return EMCursorResult<String>('', const ['alice', 'bob']);
          },
      fetchChatThreadsWithParentId:
          ({required parentId, cursor, limit = 20}) async {
            calls['parentThreads'] = [parentId, cursor, limit];
            return EMCursorResult<EMChatThread>('', [_thread('thread-parent')]);
          },
      fetchJoinedChatThreads: ({cursor, limit = 20}) async {
        calls['joined'] = [cursor, limit];
        return EMCursorResult<EMChatThread>('', [_thread('thread-joined')]);
      },
      fetchJoinedChatThreadsWithParentId:
          ({required parentId, cursor, limit = 20}) async {
            calls['joinedParent'] = [parentId, cursor, limit];
            return EMCursorResult<EMChatThread>('', [
              _thread('thread-joined-parent'),
            ]);
          },
      fetchLatestMessageWithChatThreads: ({required chatThreadIds}) async {
        calls['latest'] = chatThreadIds;
        final message = EMMessage.createTxtSendMessage(
          targetId: 'thread-a',
          content: 'latest',
          chatType: ChatType.GroupChat,
        );
        return {'thread-a': message};
      },
      joinChatThread: ({required chatThreadId}) async {
        calls['join'] = chatThreadId;
        return _thread(chatThreadId);
      },
      leaveChatThread: ({required chatThreadId}) async {
        calls['leave'] = chatThreadId;
      },
      destroyChatThread: ({required chatThreadId}) async {
        calls['destroy'] = chatThreadId;
      },
      removeMemberFromChatThread:
          ({required memberId, required chatThreadId}) async {
            calls['removeMember'] = [chatThreadId, memberId];
          },
      updateChatThreadName: ({required chatThreadId, required newName}) async {
        calls['updateName'] = [chatThreadId, newName];
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChatThreadPage(
          showAppBar: false,
          controller: controller,
          parentGroupId: 'group-a',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Thread ID'),
      'thread-a',
    );
    expect(find.widgetWithText(TextField, '父级群组 ID'), findsNothing);
    expect(find.widgetWithText(TextField, '父消息 ID'), findsNothing);
    expect(find.widgetWithText(TextField, 'Thread 名称'), findsNothing);
    await tester.enterText(find.widgetWithText(TextField, '成员 ID'), 'alice');
    await tester.enterText(
      find.widgetWithText(TextField, 'Thread ID 列表'),
      'thread-a,thread-b',
    );

    await tester.tap(find.text('创建'));
    await tester.pumpAndSettle();
    expect(find.text('创建子区'), findsOneWidget);
    expect(find.text('父级群组 ID: group-a'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, '父消息 ID / 子区消息 ID'),
      'msg-a',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Thread 名称'),
      'topic-a',
    );
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('详情'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('成员'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('父级列表'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('已加入'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('父级已加入'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('最新消息'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('加入'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('退出'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('解散'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('移除成员'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('改名'));
    await tester.pumpAndSettle();
    expect(find.text('修改子区名称'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Thread 新名称'),
      'topic-renamed',
    );
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(calls['create'], ['topic-a', 'msg-a', 'group-a']);
    expect(calls['fetch'], 'thread-created');
    expect(calls['members'], ['thread-created', null, 20]);
    expect(calls['parentThreads'], ['group-a', null, 20]);
    expect(calls['joined'], [null, 20]);
    expect(calls['joinedParent'], ['group-a', null, 20]);
    expect(calls['latest'], ['thread-a', 'thread-b', 'thread-created']);
    expect(calls['join'], 'thread-created');
    expect(calls['leave'], 'thread-created');
    expect(calls['destroy'], 'thread-created');
    expect(calls['removeMember'], ['thread-created', 'alice']);
    expect(calls['updateName'], ['thread-created', 'topic-renamed']);
    expect(find.textContaining('创建 Thread 成功'), findsOneWidget);
    expect(find.textContaining('Thread 成员: alice'), findsOneWidget);
    expect(find.textContaining('Thread 最新消息: thread-a'), findsOneWidget);
  });

  testWidgets('thread creation can use fixed parent message id', (
    tester,
  ) async {
    useLargeViewport(tester);
    final calls = <String, Object?>{};
    final controller = ChatThreadTestController(
      createChatThread:
          ({required name, required messageId, required parentId}) async {
            calls['create'] = [name, messageId, parentId];
            return _thread('thread-created');
          },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChatThreadPage(
          showAppBar: false,
          controller: controller,
          parentGroupId: 'group-a',
          parentMessageId: 'msg-a',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('当前父级群组 ID: group-a'), findsOneWidget);
    expect(find.textContaining('当前父消息 ID: msg-a'), findsOneWidget);

    await tester.tap(find.text('创建'));
    await tester.pumpAndSettle();

    expect(find.text('父级群组 ID: group-a'), findsOneWidget);
    expect(find.text('父消息 ID: msg-a'), findsOneWidget);
    expect(find.widgetWithText(TextField, '父消息 ID'), findsNothing);
    await tester.enterText(
      find.widgetWithText(TextField, 'Thread 名称'),
      'topic-a',
    );
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(calls['create'], ['topic-a', 'msg-a', 'group-a']);
    expect(find.textContaining('创建 Thread 成功'), findsOneWidget);
  });

  testWidgets('thread creation fills current thread id and id list', (
    tester,
  ) async {
    useLargeViewport(tester);
    final controller = ChatThreadTestController(
      createChatThread:
          ({required name, required messageId, required parentId}) async =>
              _threadWithParentMessage('thread-created', messageId),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChatThreadPage(
          showAppBar: false,
          controller: controller,
          parentGroupId: 'group-a',
          parentMessageId: 'msg-a',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('创建'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Thread 名称'),
      'topic-a',
    );
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    final threadField = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Thread ID'),
    );
    final threadIdsField = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Thread ID 列表'),
    );
    expect(threadField.controller?.text, 'thread-created');
    expect(threadIdsField.controller?.text, 'thread-created');
    expect(find.textContaining('当前 Thread ID: thread-created'), findsOneWidget);
  });

  testWidgets('thread id auto fills from server returned thread list', (
    tester,
  ) async {
    useLargeViewport(tester);
    final calls = <String, Object?>{};
    final controller = ChatThreadTestController(
      fetchChatThreadsWithParentId:
          ({required parentId, cursor, limit = 20}) async {
            calls['parentThreads'] = [parentId, cursor, limit];
            return EMCursorResult<EMChatThread>('', [
              _threadWithParentMessage('thread-other', 'msg-other'),
              _threadWithParentMessage('thread-auto', 'msg-a'),
            ]);
          },
      fetchChatThread: ({required chatThreadId}) async {
        calls['fetch'] = chatThreadId;
        return _thread(chatThreadId);
      },
      fetchLatestMessageWithChatThreads: ({required chatThreadIds}) async {
        calls['latest'] = chatThreadIds;
        return {};
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChatThreadPage(
          showAppBar: false,
          controller: controller,
          parentGroupId: 'group-a',
          parentMessageId: 'msg-a',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final threadField = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Thread ID'),
    );
    final threadIdsField = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Thread ID 列表'),
    );
    expect(calls['parentThreads'], ['group-a', null, 20]);
    expect(threadField.controller?.text, 'thread-auto');
    expect(threadIdsField.controller?.text, 'thread-other\nthread-auto');

    await tester.tap(find.text('详情'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('最新消息'));
    await tester.pumpAndSettle();

    expect(calls['fetch'], 'thread-auto');
    expect(calls['latest'], ['thread-other', 'thread-auto']);
  });

  testWidgets(
    'thread page covers thread message send, fetch, local and recall',
    (tester) async {
      useLargeViewport(tester);
      final calls = <String, Object?>{};
      EMMessage? sentMessage;
      final controller = ChatThreadTestController(
        sendMessage: (message) async {
          sentMessage = message;
          return message;
        },
        fetchThreadHistoryMessages:
            ({required threadId, cursor, pageSize = 20}) async {
              calls['history'] = [threadId, cursor, pageSize];
              final message = EMMessage.createTxtSendMessage(
                targetId: threadId,
                content: 'server thread message',
                chatType: ChatType.GroupChat,
              );
              message.isChatThreadMessage = true;
              return EMCursorResult<EMMessage>('next', [message]);
            },
        getThreadConversation: ({required threadId}) async {
          calls['conversation'] = threadId;
          return EMConversation.fromJson({
            'convId': threadId,
            'type': EMConversationType.GroupChat.index,
            'isThread': true,
          });
        },
        loadThreadLocalMessages:
            ({required conversation, startMsgId = '', loadCount = 20}) async {
              calls['local'] = [
                conversation.id,
                conversation.isChatThread,
                startMsgId,
                loadCount,
              ];
              final message = EMMessage.createTxtSendMessage(
                targetId: conversation.id,
                content: 'local thread message',
                chatType: ChatType.GroupChat,
              );
              message.isChatThreadMessage = true;
              return [message];
            },
        recallMessage: ({required messageId}) async {
          calls['recall'] = messageId;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatThreadPage(showAppBar: false, controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Thread ID'),
        'thread-a',
      );
      await tester.scrollUntilVisible(
        find.widgetWithText(TextField, '子区消息内容'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find.widgetWithText(TextField, '子区消息内容'),
        'hello thread',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '父消息 ID / 子区消息 ID'),
        'msg-a',
      );

      await tester.tap(find.text('发消息'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('拉服务端消息'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('本地会话'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('撤回消息'));
      await tester.pumpAndSettle();

      expect(sentMessage, isNotNull);
      expect(sentMessage!.to, 'thread-a');
      expect(sentMessage!.chatType, ChatType.GroupChat);
      expect(sentMessage!.isChatThreadMessage, isTrue);
      expect(calls['history'], ['thread-a', null, 20]);
      expect(calls['conversation'], 'thread-a');
      expect(calls['local'], ['thread-a', true, '', 20]);
      expect(calls['recall'], sentMessage!.msgId);
      expect(find.textContaining('发送 Thread 消息成功'), findsOneWidget);
      expect(find.textContaining('content=hello thread'), findsOneWidget);
      expect(find.textContaining('server thread message'), findsOneWidget);
      expect(find.textContaining('local thread message'), findsOneWidget);
      expect(find.textContaining('撤回 Thread 消息成功'), findsOneWidget);
    },
  );

  testWidgets('thread page logs received and recalled thread messages', (
    tester,
  ) async {
    useLargeViewport(tester);
    final controller = ChatThreadTestController();

    await tester.pumpWidget(
      MaterialApp(
        home: ChatThreadPage(showAppBar: false, controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Thread ID'),
      'thread-a',
    );
    await tester.tap(find.text('注册事件'));
    await tester.pumpAndSettle();

    final handler = controller.getChatEventHandler('thread_message_test');
    expect(handler, isNotNull);
    final message = EMMessage.createTxtSendMessage(
      targetId: 'thread-a',
      content: 'incoming thread message',
      chatType: ChatType.GroupChat,
    );
    message.isChatThreadMessage = true;
    handler!.onMessagesReceived?.call([message]);
    handler.onMessagesRecalledInfo?.call([
      RecallMessageInfo(
        recallBy: 'alice',
        recallMessageId: 'msg-recalled',
        conversationId: 'thread-a',
        recallMessage: message,
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.textContaining('收到 Thread 消息'), findsOneWidget);
    expect(find.textContaining('收到 Thread 撤回'), findsOneWidget);
  });
}
