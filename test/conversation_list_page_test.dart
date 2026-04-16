import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/pages/conversation/conversation_list_page.dart';

void main() {
  testWidgets('conversation list page shows interaction hint', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ConversationListPage(
          loadConversationsPage: ({cursor, pageSize = 30}) async =>
              EMCursorResult<EMConversation>(null, [
                _buildConversation('alice'),
              ]),
          unreadCountBuilder: (_) async => 0,
          latestMessageBuilder: (_) async => null,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('长按会话可复制 ID、置顶、设为已读或删除'), findsOneWidget);
  });

  testWidgets('conversation list page does not show trailing more icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ConversationListPage(
          loadConversationsPage: ({cursor, pageSize = 30}) async =>
              EMCursorResult<EMConversation>(null, [
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
}

EMConversation _buildConversation(String id) {
  return EMConversation.fromJson({
    'convId': id,
    'type': EMConversationType.Chat.index,
    'isThread': false,
    'isPinned': false,
    'pinnedTime': 0,
  });
}
