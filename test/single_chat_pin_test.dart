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

  testWidgets('single chat pin event does not fallback when message is absent', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SingleChatPage(userId: 'alice', showAppBar: false),
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
  });
}
