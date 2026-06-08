import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/pages/group/group_members_page.dart';

void main() {
  testWidgets('member actions can remove group member', (tester) async {
    String? removedGroupId;
    List<String>? removedMembers;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroupMembersPage(
            groupId: 'group-001',
            membersLoader: (_, {cursor = '', pageSize = 50}) async =>
                EMCursorResult<String>('', const ['alice']),
            memberRemover: (groupId, members) async {
              removedGroupId = groupId;
              removedMembers = members;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('alice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('移出群组'));
    await tester.pumpAndSettle();

    expect(removedGroupId, 'group-001');
    expect(removedMembers, ['alice']);
    expect(find.text('已将 alice 移出群组'), findsOneWidget);
  });

  testWidgets('member actions can add group member to block list', (
    tester,
  ) async {
    String? blockedGroupId;
    List<String>? blockedMembers;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroupMembersPage(
            groupId: 'group-001',
            membersLoader: (_, {cursor = '', pageSize = 50}) async =>
                EMCursorResult<String>('', const ['alice']),
            memberBlocker: (groupId, members) async {
              blockedGroupId = groupId;
              blockedMembers = members;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('alice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('加入黑名单'));
    await tester.pumpAndSettle();

    expect(blockedGroupId, 'group-001');
    expect(blockedMembers, ['alice']);
    expect(find.text('已将 alice 加入群黑名单'), findsOneWidget);
  });

  testWidgets('member actions can fetch group member attributes', (
    tester,
  ) async {
    String? fetchedGroupId;
    String? fetchedUserId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroupMembersPage(
            groupId: 'group-001',
            membersLoader: (_, {cursor = '', pageSize = 50}) async =>
                EMCursorResult<String>('', const ['alice']),
            memberAttributesFetcher: ({required groupId, userId}) async {
              fetchedGroupId = groupId;
              fetchedUserId = userId;
              return const {'attKey': 'attValue'};
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('alice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('查询成员属性'));
    await tester.pumpAndSettle();

    expect(fetchedGroupId, 'group-001');
    expect(fetchedUserId, 'alice');
    expect(find.text('成员属性'), findsOneWidget);
    expect(find.text('attKey: attValue'), findsOneWidget);
  });

  testWidgets('top action opens group block list with server data', (
    tester,
  ) async {
    String? loadedGroupId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroupMembersPage(
            groupId: 'group-001',
            membersLoader: (_, {cursor = '', pageSize = 50}) async =>
                EMCursorResult<String>('', const ['alice']),
            blockListLoader: (groupId, {pageNum = 1, pageSize = 50}) async {
              loadedGroupId = groupId;
              return const ['blocked-user'];
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('黑名单'));
    await tester.pumpAndSettle();

    expect(loadedGroupId, 'group-001');
    expect(find.text('群黑名单 (1)'), findsOneWidget);
    expect(find.text('blocked-user'), findsOneWidget);
  });

  testWidgets('group block list can unblock member', (tester) async {
    String? unblockedGroupId;
    List<String>? unblockedMembers;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroupMembersPage(
            groupId: 'group-001',
            membersLoader: (_, {cursor = '', pageSize = 50}) async =>
                EMCursorResult<String>('', const ['alice']),
            blockListLoader: (_, {pageNum = 1, pageSize = 50}) async => const [
              'blocked-user',
            ],
            memberUnblocker: (groupId, members) async {
              unblockedGroupId = groupId;
              unblockedMembers = members;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('黑名单'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('blocked-user'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('移出黑名单'));
    await tester.pumpAndSettle();

    expect(unblockedGroupId, 'group-001');
    expect(unblockedMembers, ['blocked-user']);
    expect(find.text('已将 blocked-user 移出群黑名单'), findsOneWidget);
  });
}
