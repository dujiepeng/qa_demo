import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/common/widgets/log_view.dart';
import 'package:qa_flutter/pages/single/single_chat_reaction.dart';

void main() {
  testWidgets('shows only visible log actions on long press', (tester) async {
    final controller = LogController()..addLog('hello', tag: 'message');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 240,
            child: LogView(
              controller: controller,
              isDark: true,
              actionsBuilder: (entry) => [
                LogAction(
                  id: 'copy',
                  title: '复制',
                  onSelected: (_) async => null,
                ),
                LogAction(
                  id: 'hidden',
                  title: '隐藏',
                  isVisible: (_) => false,
                  onSelected: (_) async => null,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.longPress(find.textContaining('hello'));
    await tester.pumpAndSettle();

    expect(find.text('复制'), findsOneWidget);
    expect(find.text('隐藏'), findsNothing);
  });

  testWidgets('supports async actions builder on long press', (tester) async {
    final controller = LogController()..addLog('hello');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 240,
            child: LogView(
              controller: controller,
              isDark: true,
              asyncActionsBuilder: (entry) async {
                await Future<void>.delayed(Duration.zero);
                return [
                  LogAction(
                    id: 'async_copy',
                    title: '异步动作',
                    onSelected: (_) async => null,
                  ),
                ];
              },
            ),
          ),
        ),
      ),
    );

    await tester.longPress(find.textContaining('hello'));
    await tester.pumpAndSettle();

    expect(find.text('异步动作'), findsOneWidget);
  });

  testWidgets('renders centered overlay label without replacing log text', (
    tester,
  ) async {
    final controller = LogController();
    final entry = controller.addLog('hello');
    controller.updateEntry(entry, overlayLabel: '已复制');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 240,
            child: LogView(controller: controller, isDark: true),
          ),
        ),
      ),
    );

    expect(find.textContaining('hello'), findsOneWidget);
    expect(find.text('已复制'), findsOneWidget);
    final overlayBox = tester.widget<DecoratedBox>(
      find.byWidgetPredicate((widget) {
        if (widget is! DecoratedBox) {
          return false;
        }
        final decoration = widget.decoration;
        return decoration is BoxDecoration && decoration.border != null;
      }).first,
    );
    final decoration = overlayBox.decoration as BoxDecoration;
    expect(decoration.border, isNotNull);
  });

  testWidgets('applies action result overlay to the selected entry', (
    tester,
  ) async {
    final controller = LogController()..addLog('hello');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 240,
            child: LogView(
              controller: controller,
              isDark: true,
              actionsBuilder: (entry) => [
                const LogAction(
                  id: 'copy',
                  title: '复制',
                  onSelected: _copyResult,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.longPress(find.textContaining('hello'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('复制'));
    await tester.pumpAndSettle();

    expect(find.text('已复制'), findsOneWidget);
  });

  testWidgets('applies action result patch fields to the selected entry', (
    tester,
  ) async {
    final controller = LogController()..addLog('hello');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 240,
            child: LogView(
              controller: controller,
              isDark: true,
              actionsBuilder: (entry) => [
                const LogAction(
                  id: 'patch',
                  title: '应用补丁',
                  onSelected: _patchResult,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.longPress(find.textContaining('hello'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('应用补丁'));
    await tester.pumpAndSettle();

    final updated = controller.entities.single;
    expect(updated.content, 'patched');
    expect(updated.color, Colors.yellow);
    expect(updated.style, LogStyle.lineThrough);
    expect(updated.overlayLabel, '已打补丁');
    expect(updated.overlayStyle, LogOverlayStyle.success);
  });

  testWidgets('renders action icon and foreground color in menu', (
    tester,
  ) async {
    final controller = LogController()..addLog('hello');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 240,
            child: LogView(
              controller: controller,
              isDark: true,
              actionsBuilder: (entry) => [
                const LogAction(
                  id: 'danger',
                  title: '危险操作',
                  icon: Icons.delete_outline,
                  foregroundColor: Colors.red,
                  onSelected: _copyResult,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.longPress(find.textContaining('hello'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    final actionLabel = tester.widget<Text>(find.text('危险操作'));
    expect(actionLabel.style?.color, Colors.red);
  });

  testWidgets('read ack action is hidden for self sent message', (
    tester,
  ) async {
    final controller = LogController()
      ..addLog(
        'self message',
        tag: 'message',
        attachment: _buildMessage(MessageDirection.SEND),
      );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 240,
            child: LogView(
              controller: controller,
              isDark: true,
              actionsBuilder: (entry) {
                final message = entry.attachment as EMMessage;
                return [
                  LogAction(
                    id: 'send_read_ack',
                    title: '发送单聊已读ACK',
                    isVisible: (_) =>
                        message.direction == MessageDirection.RECEIVE,
                    onSelected: _noopResult,
                  ),
                ];
              },
            ),
          ),
        ),
      ),
    );

    await tester.longPress(find.textContaining('self message'));
    await tester.pumpAndSettle();

    expect(find.text('发送单聊已读ACK'), findsNothing);
  });

  testWidgets(
    'menu selection keeps text field unfocused after callback unfocus',
    (tester) async {
      final controller = LogController()..addLog('hello');
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(focusNode: focusNode),
                SizedBox(
                  height: 240,
                  child: LogView(
                    controller: controller,
                    isDark: true,
                    menuShowCallback: focusNode.unfocus,
                    actionsBuilder: (entry) => [
                      const LogAction(
                        id: 'act',
                        title: '动作',
                        onSelected: _noopResult,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isTrue);

      await tester.longPress(find.textContaining('hello'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('动作'));
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isFalse);
    },
  );

  testWidgets('menu dismissal keeps text field unfocused', (tester) async {
    final controller = LogController()..addLog('hello');
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(focusNode: focusNode),
              SizedBox(
                height: 240,
                child: LogView(
                  controller: controller,
                  isDark: true,
                  menuShowCallback: focusNode.unfocus,
                  actionsBuilder: (entry) => [
                    const LogAction(
                      id: 'act',
                      title: '动作',
                      onSelected: _noopResult,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(focusNode.hasFocus, isTrue);

    await tester.longPress(find.textContaining('hello'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets('reaction action closes menu before showing bottom sheet', (
    tester,
  ) async {
    final controller = LogController()..addLog('hello', tag: 'message');
    BuildContext? hostContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              hostContext = context;
              return SizedBox(
                height: 240,
                child: LogView(
                  controller: controller,
                  isDark: true,
                  actionsBuilder: (entry) => [
                    LogAction(
                      id: 'reaction',
                      title: 'Reaction…',
                      onSelected: (_) async {
                        await showSingleChatReactionSheet(hostContext!);
                        return null;
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.longPress(find.textContaining('hello'));
    await tester.pumpAndSettle();
    expect(find.text('Reaction…'), findsOneWidget);

    await tester.tap(find.text('Reaction…'));
    await tester.pumpAndSettle();

    expect(find.text('Reaction…'), findsNothing);
    expect(find.text('Reaction'), findsOneWidget);
  });
}

Future<LogActionResult?> _copyResult(LogEntry _) async {
  return const LogActionResult(overlayLabel: '已复制');
}

Future<LogActionResult?> _noopResult(LogEntry _) async {
  return null;
}

Future<LogActionResult?> _patchResult(LogEntry _) async {
  return const LogActionResult(
    content: 'patched',
    color: Colors.yellow,
    style: LogStyle.lineThrough,
    overlayLabel: '已打补丁',
    overlayStyle: LogOverlayStyle.success,
  );
}

EMMessage _buildMessage(MessageDirection direction) {
  return EMMessage.fromJson({
    'to': 'alice',
    'from': 'bob',
    'body': {'type': MessageType.TXT.index, 'content': 'hello'},
    'direction': direction.index,
    'msgId': 'msg-1',
    'convId': 'alice',
    'chatType': ChatType.Chat.index,
    'status': MessageStatus.SUCCESS.index,
  });
}
