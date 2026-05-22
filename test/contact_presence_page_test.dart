import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/pages/single/contact_presence_page.dart';

void main() {
  setUp(() {
    debugResetContactPresenceCache();
  });

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
    expect(find.text('长按联系人可设置备注、订阅、取消订阅或查询 Presence'), findsOneWidget);
    expect(find.text('Presence 通知'), findsNothing);
    expect(find.text('未获取 Presence 状态'), findsAtLeastNWidgets(1));
  });

  testWidgets(
    'contact presence page restores subscribed members presence on rebuild',
    (tester) async {
      final queriedUsers = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: ContactPresencePage(
            loadContacts: () async => [
              EMContact.fromJson({'userId': 'alice', 'remark': ''}),
            ],
            loadSubscribedMembers: () async => ['alice'],
            queryPresence: (userId) async {
              queriedUsers.add(userId);
              return [
                EMPresence(
                  userId,
                  'available',
                  {'android': 1},
                  1710000000,
                  1710003600,
                ),
              ];
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(queriedUsers, ['alice']);
      expect(find.text('Presence 已订阅'), findsOneWidget);
      expect(find.text('在线'), findsOneWidget);
      expect(find.text('available'), findsOneWidget);
      expect(find.text('未获取 Presence 状态'), findsNothing);
    },
  );

  testWidgets('contact presence page shows remark as title when available', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ContactPresencePage(
          loadContacts: () async => [
            EMContact.fromJson({'userId': 'alice', 'remark': 'Alice备注'}),
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('alice(Alice备注)'), findsOneWidget);
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

  testWidgets(
    'contact presence page keeps subscribed presence after leaving and re-entering',
    (tester) async {
      Widget buildPage() {
        return MaterialApp(
          home: ContactPresencePage(
            loadContacts: () async => [
              EMContact.fromJson({'userId': 'alice', 'remark': ''}),
            ],
            loadSubscribedMembers: () async => [],
            subscribePresence: (userId) async {
              return [
                EMPresence(
                  userId,
                  'available',
                  {'android': 1},
                  1710000000,
                  1710003600,
                ),
              ];
            },
          ),
        );
      }

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();
      await tester.longPress(find.text('alice'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('订阅 Presence'));
      await tester.pumpAndSettle();

      expect(find.text('Presence 已订阅'), findsOneWidget);
      expect(find.text('在线'), findsOneWidget);
      expect(find.text('available'), findsOneWidget);

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pumpAndSettle();
      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Presence 已订阅'), findsOneWidget);
      expect(find.text('在线'), findsOneWidget);
      expect(find.text('available'), findsOneWidget);
    },
  );

  testWidgets('contact presence page does not open chat on tap', (
    tester,
  ) async {
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

  testWidgets('contact presence menu shows only valid subscription action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ContactPresencePage(
          loadContacts: () async => [
            EMContact.fromJson({'userId': 'alice', 'remark': ''}),
            EMContact.fromJson({'userId': 'bob', 'remark': ''}),
          ],
          loadSubscribedMembers: () async => ['alice'],
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.longPress(find.text('alice'));
    await tester.pumpAndSettle();
    expect(find.text('取消订阅 Presence'), findsOneWidget);
    expect(find.text('订阅 Presence'), findsNothing);
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    await tester.longPress(find.text('bob'));
    await tester.pumpAndSettle();
    expect(find.text('订阅 Presence'), findsOneWidget);
    expect(find.text('取消订阅 Presence'), findsNothing);
  });

  testWidgets('contact presence page queries presence from menu', (
    tester,
  ) async {
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
    expect(find.text('已查询 alice 的在线状态：在线'), findsOneWidget);
  });

  testWidgets('manual query refreshes display even when result time is older', (
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
          queryPresence: (userId) async {
            return [
              EMPresence(userId, '', {'android': 1}, 100, 1710003600),
            ];
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    controller.add([
      EMPresence('alice', '', {'android': 0}, 200, 1710003600),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('离线'), findsOneWidget);

    await tester.longPress(find.text('alice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('查询状态'));
    await tester.pumpAndSettle();

    expect(find.text('在线'), findsOneWidget);
    expect(find.text('离线'), findsNothing);

    await controller.close();
  });

  testWidgets(
    'contact presence page updates cell subtitle when presence changes',
    (tester) async {
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
    },
  );

  testWidgets('contact presence page ignores older presence updates', (
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
      EMPresence('alice', '', {'android': 1}, 200, 1710003600),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('在线'), findsOneWidget);

    controller.add([
      EMPresence('alice', '', {'android': 0}, 100, 1710003600),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('在线'), findsOneWidget);
    expect(find.text('离线'), findsNothing);

    await controller.close();
  });
}
