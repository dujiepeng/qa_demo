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
}
