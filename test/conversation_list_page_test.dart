import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/pages/conversation/conversation_list_page.dart';

void main() {
  testWidgets('conversation list page shows interaction hint', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ConversationListPage(
          loadConversationsPage:
              ({
                cursor,
                pageSize = 30,
                filter = ConversationListFilter.all,
              }) async => EMCursorResult<EMConversation>(null, [
                _buildConversation('alice'),
              ]),
          unreadCountBuilder: (_) async => 0,
          latestMessageBuilder: (_) async => null,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('长按会话可复制 ID、置顶、标记、设为已读、发送会话已读ACK或删除'), findsOneWidget);
    expect(find.text('全部'), findsOneWidget);
    expect(find.text('置顶'), findsOneWidget);
    expect(find.text('Mark1'), findsOneWidget);
  });

  testWidgets('conversation list page keeps tabs visible on empty filter', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ConversationListPage(
          loadConversationsPage:
              ({
                cursor,
                pageSize = 30,
                filter = ConversationListFilter.all,
              }) async => EMCursorResult<EMConversation>(
                null,
                filter == ConversationListFilter.mark3
                    ? []
                    : [_buildConversation('alice')],
              ),
          unreadCountBuilder: (_) async => 0,
          latestMessageBuilder: (_) async => null,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark3'));
    await tester.pumpAndSettle();

    expect(find.text('暂无会话'), findsOneWidget);
    expect(find.text('全部'), findsOneWidget);
    expect(find.text('置顶'), findsOneWidget);
    expect(find.text('Mark3'), findsOneWidget);
  });

  testWidgets('conversation list page does not show trailing more icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ConversationListPage(
          loadConversationsPage:
              ({
                cursor,
                pageSize = 30,
                filter = ConversationListFilter.all,
              }) async => EMCursorResult<EMConversation>(null, [
                _buildConversation('alice'),
              ]),
          unreadCountBuilder: (_) async => 0,
          latestMessageBuilder: (_) async => null,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.more_horiz), findsNothing);
  });

  testWidgets('conversation list page reloads when switching filters', (
    tester,
  ) async {
    final requestedFilters = <ConversationListFilter>[];

    await tester.pumpWidget(
      MaterialApp(
        home: ConversationListPage(
          loadConversationsPage:
              ({
                cursor,
                pageSize = 30,
                filter = ConversationListFilter.all,
              }) async {
                requestedFilters.add(filter);
                return EMCursorResult<EMConversation>(null, [
                  _buildConversation(filter.name),
                ]);
              },
          unreadCountBuilder: (_) async => 0,
          latestMessageBuilder: (_) async => null,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('置顶'));
    await tester.pumpAndSettle();

    expect(
      requestedFilters,
      containsAll([
        ConversationListFilter.all,
        ConversationListFilter.mark2,
        ConversationListFilter.pinned,
      ]),
    );
  });

  testWidgets('conversation list page refresh button reloads current filter', (
    tester,
  ) async {
    final requestedFilters = <ConversationListFilter>[];

    await tester.pumpWidget(
      MaterialApp(
        home: ConversationListPage(
          loadConversationsPage:
              ({
                cursor,
                pageSize = 30,
                filter = ConversationListFilter.all,
              }) async {
                requestedFilters.add(filter);
                return EMCursorResult<EMConversation>(null, [
                  _buildConversation(
                    '${filter.name}-${requestedFilters.length}',
                  ),
                ]);
              },
          unreadCountBuilder: (_) async => 0,
          latestMessageBuilder: (_) async => null,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    expect(
      requestedFilters,
      containsAll([
        ConversationListFilter.all,
        ConversationListFilter.mark1,
        ConversationListFilter.mark1,
      ]),
    );
    expect(find.text('mark1-3'), findsOneWidget);
  });

  testWidgets('conversation list page includes local chatroom conversations', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ConversationListPage(
          loadConversationsPage:
              ({
                cursor,
                pageSize = 30,
                filter = ConversationListFilter.all,
              }) async => EMCursorResult<EMConversation>(null, [
                _buildConversation('alice'),
              ]),
          loadLocalConversations: () async => [
            _buildConversation('room-001', type: EMConversationType.ChatRoom),
          ],
          unreadCountBuilder: (_) async => 0,
          latestMessageBuilder: (_) async => null,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('alice'), findsOneWidget);
    expect(find.text('room-001'), findsOneWidget);
    expect(find.textContaining('[聊天室]'), findsOneWidget);
  });

  testWidgets('local chatroom conversations do not force loading indicator', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ConversationListPage(
          loadConversationsPage:
              ({
                cursor,
                pageSize = 30,
                filter = ConversationListFilter.all,
              }) async => EMCursorResult<EMConversation>(null, [
                _buildConversation('alice'),
              ]),
          loadLocalConversations: () async => [
            _buildConversation('room-001', type: EMConversationType.ChatRoom),
          ],
          unreadCountBuilder: (_) async => 0,
          latestMessageBuilder: (_) async => null,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('recall info event refreshes unread badge', (tester) async {
    var unreadCount = 1;

    await tester.pumpWidget(
      MaterialApp(
        home: ConversationListPage(
          loadConversationsPage:
              ({
                cursor,
                pageSize = 30,
                filter = ConversationListFilter.all,
              }) async => EMCursorResult<EMConversation>(null, [
                _buildConversation('alice'),
              ]),
          unreadCountBuilder: (_) async => unreadCount,
          latestMessageBuilder: (_) async => null,
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);

    unreadCount = 0;
    EMClient.getInstance.chatManager
        .getEventHandler('conversation_list_page')
        ?.onMessagesRecalledInfo
        ?.call([
          const RecallMessageInfo(
            recallBy: 'alice',
            recallMessageId: 'msg-001',
            conversationId: 'alice',
          ),
        ]);
    await tester.pumpAndSettle();

    expect(find.text('1'), findsNothing);
  });

  testWidgets('conversation long press can send conversation read ack', (
    tester,
  ) async {
    String? ackConversationId;

    await tester.pumpWidget(
      MaterialApp(
        home: ConversationListPage(
          loadConversationsPage:
              ({
                cursor,
                pageSize = 30,
                filter = ConversationListFilter.all,
              }) async => EMCursorResult<EMConversation>(null, [
                _buildConversation('alice'),
              ]),
          unreadCountBuilder: (_) async => 3,
          latestMessageBuilder: (_) async => null,
          conversationReadAckSender: (conversationId) async {
            ackConversationId = conversationId;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.longPress(find.text('alice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('发送会话已读ACK'));
    await tester.pumpAndSettle();

    expect(ackConversationId, 'alice');
    expect(find.text('会话已读 ACK 已发送: alice'), findsOneWidget);
  });

  testWidgets('conversation page exposes server conversation APIs', (
    tester,
  ) async {
    var oldServerListCalled = false;
    int? oldPageNum;
    int? oldPageSize;
    int? cursorPageSize;
    int? pinnedPageSize;

    await tester.pumpWidget(
      MaterialApp(
        home: ConversationListPage(
          loadConversationsPage:
              ({
                cursor,
                pageSize = 30,
                filter = ConversationListFilter.all,
              }) async => EMCursorResult<EMConversation>(null, const []),
          loadLocalConversations: () async => const [],
          unreadCountBuilder: (_) async => 0,
          latestMessageBuilder: (_) async => null,
          getConversationsFromServerOld: () async => [
            _buildConversation('old-all'),
          ],
          fetchConversationListFromServerOld:
              ({pageNum = 1, pageSize = 20}) async {
                oldServerListCalled = true;
                oldPageNum = pageNum;
                oldPageSize = pageSize;
                return [_buildConversation('old-page')];
              },
          fetchConversationFromServerOld: ({cursor, pageSize = 20}) async {
            cursorPageSize = pageSize;
            return EMCursorResult<EMConversation>('next', [
              _buildConversation('old-cursor'),
            ]);
          },
          fetchPinnedConversations: ({cursor, pageSize = 20}) async {
            pinnedPageSize = pageSize;
            return EMCursorResult<EMConversation>('', [
              _buildConversation('pinned-server'),
            ]);
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('服务端'));
    await tester.pumpAndSettle();

    expect(oldServerListCalled, isTrue);
    expect(oldPageNum, 1);
    expect(oldPageSize, 20);
    expect(cursorPageSize, 20);
    expect(pinnedPageSize, 20);
    expect(find.textContaining('old会话列表: old-all'), findsWidgets);
    expect(find.textContaining('old分页会话: old-page'), findsWidgets);
    expect(find.textContaining('old游标会话: old-cursor'), findsWidgets);
    expect(find.textContaining('置顶会话: pinned-server'), findsWidgets);
  });

  testWidgets('conversation long press exposes server-backed object actions', (
    tester,
  ) async {
    ChatPushRemindType? remindTypeRequestedFor;
    List<String>? deletedMessageIds;
    int? deletedBeforeMs;

    await tester.pumpWidget(
      MaterialApp(
        home: ConversationListPage(
          loadConversationsPage:
              ({
                cursor,
                pageSize = 30,
                filter = ConversationListFilter.all,
              }) async => EMCursorResult<EMConversation>(null, [
                _buildConversation('alice'),
              ]),
          unreadCountBuilder: (_) async => 0,
          latestMessageBuilder: (_) async => _buildMessage('latest-msg-001'),
          nowBuilder: () => DateTime.fromMillisecondsSinceEpoch(7200000),
          conversationRemindTypeFetcher: (conversation) async {
            remindTypeRequestedFor = ChatPushRemindType.ALL;
            return remindTypeRequestedFor!;
          },
          localAndServerMessagesDeleter: (conversation, msgIds) async {
            deletedMessageIds = msgIds;
          },
          localAndServerMessagesByTimeDeleter: (conversation, beforeMs) async {
            deletedBeforeMs = beforeMs;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.longPress(find.text('alice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('查提醒类型'));
    await tester.pumpAndSettle();

    expect(remindTypeRequestedFor, ChatPushRemindType.ALL);
    expect(find.text('会话提醒类型: alice, ALL'), findsOneWidget);

    await tester.longPress(find.text('alice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删服务端消息'));
    await tester.pumpAndSettle();

    final msgIdsField = tester.widget<TextField>(
      find.widgetWithText(TextField, '消息 ID 列表'),
    );
    expect(msgIdsField.controller?.text, 'latest-msg-001');

    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(deletedMessageIds, ['latest-msg-001']);
    expect(find.text('已删除本地+服务端消息: alice, 1 条'), findsOneWidget);

    await tester.longPress(find.text('alice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('按时间删服务端'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '删除多少分钟前'), findsOneWidget);
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(deletedBeforeMs, 3600000);
    expect(find.textContaining('按时间删除本地+服务端消息: alice, 60 分钟前'), findsOneWidget);
  });

  testWidgets(
    'conversation time delete reports native errors without unsupported hint',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConversationListPage(
            loadConversationsPage:
                ({
                  cursor,
                  pageSize = 30,
                  filter = ConversationListFilter.all,
                }) async => EMCursorResult<EMConversation>(null, [
                  _buildConversation('alice'),
                ]),
            unreadCountBuilder: (_) async => 0,
            latestMessageBuilder: (_) async => null,
            nowBuilder: () => DateTime.fromMillisecondsSinceEpoch(7200000),
            localAndServerMessagesByTimeDeleter: (conversation, beforeMs) {
              throw MissingPluginException(
                'No implementation found for method '
                'conversationDeleteServerMessageWithTime on channel '
                'com.chat.im/chat_conversation',
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.longPress(find.text('alice'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('按时间删服务端'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('按时间删除本地+服务端消息失败'),
        findsOneWidget,
      );
      expect(find.textContaining('当前原生插件不支持'), findsNothing);
    },
  );

  testWidgets(
    'conversation refreshes latest message after server message delete',
    (tester) async {
      var latestMessage = _buildMessage('deleted-msg', content: 'deleted text');

      await tester.pumpWidget(
        MaterialApp(
          home: ConversationListPage(
            loadConversationsPage:
                ({
                  cursor,
                  pageSize = 30,
                  filter = ConversationListFilter.all,
                }) async => EMCursorResult<EMConversation>(null, [
                  _buildConversation('alice'),
                ]),
            unreadCountBuilder: (_) async => 0,
            latestMessageBuilder: (_) async => latestMessage,
            localAndServerMessagesDeleter: (conversation, msgIds) async {
              latestMessage = _buildMessage('next-msg', content: 'next text');
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('deleted text'), findsOneWidget);

      await tester.longPress(find.text('alice'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删服务端消息'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();

      expect(find.textContaining('next text'), findsOneWidget);
      expect(find.textContaining('deleted text'), findsNothing);
    },
  );
}

EMConversation _buildConversation(
  String id, {
  EMConversationType type = EMConversationType.Chat,
}) {
  return EMConversation.fromJson({
    'convId': id,
    'type': type.index,
    'isThread': false,
    'isPinned': false,
    'pinnedTime': 0,
  });
}

EMMessage _buildMessage(String msgId, {String content = 'hello'}) {
  return EMMessage.fromJson({
    'to': 'alice',
    'from': 'bob',
    'body': {'type': MessageType.TXT.index, 'content': content},
    'direction': MessageDirection.SEND.index,
    'msgId': msgId,
    'convId': 'alice',
    'chatType': ChatType.Chat.index,
    'status': MessageStatus.SUCCESS.index,
  });
}
