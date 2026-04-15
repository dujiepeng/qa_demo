import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/pages/single/contact_presence_page.dart';

void main() {
  testWidgets('contact presence page renders contacts', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ContactPresencePage(
          loadContacts: () async => [
            EMContact.fromJson({'userId': 'alice', 'remark': ''}),
            EMContact.fromJson({'userId': 'bob', 'remark': ''}),
          ],
          loadSubscribedMembers: () async => ['bob'],
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('alice'), findsOneWidget);
    expect(find.text('bob'), findsOneWidget);
    expect(find.text('Presence 已订阅'), findsOneWidget);
    expect(find.text('长按联系人可订阅、取消订阅或查询 Presence'), findsOneWidget);
    expect(find.text('Presence 通知'), findsNothing);
    expect(find.text('未获取 Presence 状态'), findsAtLeastNWidgets(1));
  });

  testWidgets('contact presence page subscribes presence from menu', (
    tester,
  ) async {
    final subscribedUsers = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: ContactPresencePage(
          loadContacts: () async => [
            EMContact.fromJson({'userId': 'alice', 'remark': ''}),
          ],
          subscribePresence: (userId) async {
            subscribedUsers.add(userId);
            return [
              EMPresence('alice', '', {'android': 1}, 1710000000, 1710003600),
            ];
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.longPress(find.text('alice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('订阅 Presence'));
    await tester.pumpAndSettle();

    expect(subscribedUsers, ['alice']);
    expect(find.text('在线'), findsOneWidget);
    expect(find.text('离线'), findsNothing);
  });

  testWidgets('contact presence page does not open chat on tap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ContactPresencePage(
          loadContacts: () async => [
            EMContact.fromJson({'userId': 'alice', 'remark': ''}),
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('alice'));
    await tester.pumpAndSettle();

    expect(find.byType(PopupMenuItem<String>), findsNothing);
  });

  testWidgets('contact presence page adds user to blacklist from menu', (
    tester,
  ) async {
    final blacklistedUsers = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: ContactPresencePage(
          loadContacts: () async => [
            EMContact.fromJson({'userId': 'alice', 'remark': ''}),
          ],
          addUserToBlockList: (userId) async {
            blacklistedUsers.add(userId);
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.longPress(find.text('alice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('加入黑名单'));
    await tester.pumpAndSettle();

    expect(blacklistedUsers, ['alice']);
  });

  testWidgets('contact presence page unsubscribes presence from menu', (
    tester,
  ) async {
    final unsubscribedUsers = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: ContactPresencePage(
          loadContacts: () async => [
            EMContact.fromJson({'userId': 'alice', 'remark': ''}),
          ],
          loadSubscribedMembers: () async => ['alice'],
          unsubscribePresence: (userId) async {
            unsubscribedUsers.add(userId);
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Presence 已订阅'), findsOneWidget);

    await tester.longPress(find.text('alice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消订阅 Presence'));
    await tester.pumpAndSettle();

    expect(unsubscribedUsers, ['alice']);
    expect(find.text('Presence 已订阅'), findsNothing);
  });

  testWidgets('contact presence page queries presence from menu', (tester) async {
    final queriedUsers = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: ContactPresencePage(
          loadContacts: () async => [
            EMContact.fromJson({'userId': 'alice', 'remark': ''}),
          ],
          queryPresence: (userId) async {
            queriedUsers.add(userId);
            return [
              EMPresence('alice', 'away', {'web': 1}, 1710000000, 1710003600),
            ];
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.longPress(find.text('alice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('查询状态'));
    await tester.pumpAndSettle();

    expect(queriedUsers, ['alice']);
    expect(find.text('在线'), findsOneWidget);
    expect(find.text('away'), findsOneWidget);
  });

  testWidgets('contact presence page updates cell subtitle when presence changes', (
    tester,
  ) async {
    final controller = StreamController<List<EMPresence>>();

    await tester.pumpWidget(
      MaterialApp(
        home: ContactPresencePage(
          loadContacts: () async => [
            EMContact.fromJson({'userId': 'alice', 'remark': ''}),
          ],
          presenceUpdates: controller.stream,
        ),
      ),
    );

    await tester.pumpAndSettle();

    controller.add([
      EMPresence('alice', 'busy', {'ios': 0}, 1710000000, 1710003600),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('离线'), findsOneWidget);
    expect(find.text('busy'), findsAtLeastNWidgets(1));
    expect(find.text('alice'), findsOneWidget);
    expect(find.text('busy'), findsOneWidget);

    await controller.close();
  });
}
