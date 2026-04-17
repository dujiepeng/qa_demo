import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_flutter/common/widgets/message_send_options_row.dart';

void main() {
  testWidgets('shows repeat count and online-only toggle', (tester) async {
    final controller = TextEditingController(text: '2');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageSendOptionsRow(
            countController: controller,
            deliverOnlineOnly: false,
            onDeliverOnlineOnlyChanged: (_) {},
            isDark: true,
          ),
        ),
      ),
    );

    expect(find.text('重复次数'), findsOneWidget);
    expect(find.text('只发在线'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('tapping checkbox updates online-only state callback', (
    tester,
  ) async {
    final controller = TextEditingController(text: '1');
    var currentValue = false;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: MessageSendOptionsRow(
                countController: controller,
                deliverOnlineOnly: currentValue,
                onDeliverOnlineOnlyChanged: (value) {
                  setState(() {
                    currentValue = value;
                  });
                },
                isDark: true,
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(currentValue, isTrue);
  });
}
