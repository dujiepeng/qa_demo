import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qa_flutter/common/utils/offline_message_counter.dart';
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
}
