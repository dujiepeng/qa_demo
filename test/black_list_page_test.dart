import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_flutter/pages/single/black_list_page.dart';

void main() {
  testWidgets('blacklist page renders loaded users', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlackListPage(
          loadBlockList: () async => ['alice', 'bob'],
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('alice'), findsOneWidget);
    expect(find.text('bob'), findsOneWidget);
  });

  testWidgets('blacklist page removes user through callback', (tester) async {
    final removedUsers = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: BlackListPage(
          loadBlockList: () async => ['alice'],
          removeFromBlockList: (userId) async {
            removedUsers.add(userId);
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.longPress(find.text('alice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('移出黑名单'));
    await tester.pumpAndSettle();

    expect(removedUsers, ['alice']);
  });
}
