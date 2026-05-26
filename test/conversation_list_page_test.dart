import 'package:flutter/material.dart';
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

    expect(find.text('长按会话可复制 ID、置顶、标记、设为已读或删除'), findsOneWidget);
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
