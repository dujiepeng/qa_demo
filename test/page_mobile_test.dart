import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_flutter/mobile/page_mobile.dart';

void main() {
  testWidgets('mobile feature list shows contacts entry', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PageMobile()));

    expect(find.text('联系人'), findsOneWidget);
  });

  testWidgets('mobile feature list shows blacklist entry', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PageMobile()));

    expect(find.text('黑名单'), findsOneWidget);
  });

  testWidgets('mobile feature list shows my entry', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PageMobile()));

    await tester.drag(find.byType(GridView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('我的'), findsOneWidget);
  });

  testWidgets('mobile feature list shows offline message count', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PageMobile(offlineMessageCount: 3)),
    );

    expect(find.text('离线消息: 3'), findsOneWidget);
  });
}
