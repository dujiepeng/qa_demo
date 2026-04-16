import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/common/widgets/log_view.dart';
import 'package:qa_flutter/pages/single/single_chat_reaction.dart';

void main() {
  test('builds reaction label from counts', () {
    expect(
      buildSingleChatReactionLabel({'👍': 3, '🔥': 1}),
      '更新reaction： 👍(3)、🔥(1)',
    );
  });

  test('applies reaction overlay to matching message entry', () {
    final controller = LogController();
    final entry = controller.addLog(
      'alice: hello',
      attachment: _buildMessage('msg-1'),
      tag: 'message',
    );
    final applied = applySingleChatReactionOverlay(controller, 'msg-1', {
      '👍': 2,
      '🔥': 1,
    });

    expect(applied, isTrue);
    expect(entry.overlayLabel, '更新reaction： 👍(2)、🔥(1)');
    expect(entry.overlayStyle, LogOverlayStyle.info);
  });

  test('builds reaction empty label', () {
    expect(buildSingleChatReactionLabel(const {}), '更新reaction： 无');
  });

  test('updates cached counts from reaction operations', () {
    final cache = <String, int>{'👍': 2, '🔥': 1};
    final event = EMMessageReactionEvent(
      conversationId: 'alice',
      messageId: 'msg-1',
      reactions: const [],
      operations: const [
        ReactionOperation('bob', '👍', ReactionOperate.Add),
        ReactionOperation('bob', '👍', ReactionOperate.Remove),
        ReactionOperation('bob', '🔥', ReactionOperate.Remove),
      ],
    );

    applySingleChatReactionEvent(cache, event);

    expect(cache, {'👍': 2});
  });

  test('replaces cached counts from authoritative reaction list', () {
    final cache = <String, int>{'👍': 2};
    final event = EMMessageReactionEvent(
      conversationId: 'alice',
      messageId: 'msg-1',
      reactions: [
        EMMessageReaction(
          reaction: '👀',
          userCount: 3,
          isAddedBySelf: false,
          userList: [],
        ),
        EMMessageReaction(
          reaction: '🔥',
          userCount: 1,
          isAddedBySelf: false,
          userList: [],
        ),
      ],
      operations: const [],
    );

    applySingleChatReactionEvent(cache, event);

    expect(cache, {'👍': 2, '👀': 3, '🔥': 1});
  });

  test('does not double apply operation when authoritative count exists', () {
    final cache = <String, int>{'👍': 1};
    final event = EMMessageReactionEvent(
      conversationId: 'alice',
      messageId: 'msg-1',
      reactions: [
        EMMessageReaction(
          reaction: '👍',
          userCount: 2,
          isAddedBySelf: false,
          userList: [],
        ),
      ],
      operations: const [ReactionOperation('bob', '👍', ReactionOperate.Add)],
    );

    applySingleChatReactionEvent(cache, event);

    expect(cache, {'👍': 2});
  });

  testWidgets('reaction sheet returns selected add action', (tester) async {
    SingleChatReactionSelection? selection;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  selection = await showSingleChatReactionSheet(context);
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Reaction'), findsOneWidget);
    await tester.tap(find.text('发送').first);
    await tester.pumpAndSettle();

    expect(selection?.reaction, '👍');
    expect(selection?.action, SingleChatReactionSheetAction.add);
  });

  testWidgets('reaction sheet dismisses when tapping outside', (tester) async {
    SingleChatReactionSelection? selection = const SingleChatReactionSelection(
      reaction: 'preset',
      action: SingleChatReactionSheetAction.add,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  selection = await showSingleChatReactionSheet(context);
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Reaction'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Reaction'), findsNothing);
    expect(selection, isNull);
  });
}

EMMessage _buildMessage(String msgId) {
  return EMMessage.fromJson({
    'to': 'alice',
    'from': 'bob',
    'body': {'type': MessageType.TXT.index, 'content': 'hello'},
    'direction': MessageDirection.SEND.index,
    'msgId': msgId,
    'convId': 'alice',
    'chatType': ChatType.Chat.index,
    'status': MessageStatus.SUCCESS.index,
  });
}
