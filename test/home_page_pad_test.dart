import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qa_flutter/common/utils/offline_message_counter.dart';
import 'package:qa_flutter/common/widgets/log_panel/log_panel.dart';
import 'package:qa_flutter/pad/home_page_pad.dart';
import 'package:qa_flutter/theme/app_settings.dart';

void main() {
  testWidgets('pad home shows offline message count', (tester) async {
    final counter = OfflineMessageCounter();
    counter.recordOnlineStates([false, false, false]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: AppSettings()),
          ChangeNotifierProvider.value(value: counter),
        ],
        child: const MaterialApp(home: HomePagePad()),
      ),
    );

    expect(find.text('离线消息: 3'), findsOneWidget);
  });

  testWidgets('pad home keeps log panel collapsed by default', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: AppSettings()),
          ChangeNotifierProvider.value(value: OfflineMessageCounter()),
        ],
        child: const MaterialApp(home: HomePagePad()),
      ),
    );

    expect(find.text('展开日志'), findsOneWidget);
    expect(find.byType(LogPanel), findsNothing);
  });

  testWidgets('pad home expands log panel on demand', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: AppSettings()),
          ChangeNotifierProvider.value(value: OfflineMessageCounter()),
        ],
        child: const MaterialApp(home: HomePagePad()),
      ),
    );

    await tester.tap(find.text('展开日志'));
    await tester.pumpAndSettle();

    expect(find.text('收起日志'), findsOneWidget);
    expect(find.byType(LogPanel), findsOneWidget);
  });
}
