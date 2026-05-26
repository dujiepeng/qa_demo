import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/pages/group/group_change_owner_page.dart';

void main() {
  testWidgets('group owner transfer candidates exclude group admins', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroupChangeOwnerPage(
            groupId: 'group-001',
            groupInfoLoader: (_) async => EMGroup(
              groupId: 'group-001',
              adminList: const ['admin-a'],
              permissionType: EMGroupPermissionType.Owner,
            ),
            membersLoader: (_, {cursor = '', pageSize = 50}) async =>
                EMCursorResult<String>('', const ['admin-a', 'member-a']),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('member-a'), findsOneWidget);
    expect(find.text('admin-a'), findsNothing);
  });

  testWidgets('group owner transfer calls SDK only for non admin members', (
    tester,
  ) async {
    String? changedGroupId;
    String? changedOwner;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroupChangeOwnerPage(
            groupId: 'group-001',
            groupInfoLoader: (_) async => EMGroup(
              groupId: 'group-001',
              adminList: const ['admin-a'],
              permissionType: EMGroupPermissionType.Owner,
            ),
            membersLoader: (_, {cursor = '', pageSize = 50}) async =>
                EMCursorResult<String>('', const ['admin-a', 'member-a']),
            ownerChanger: (groupId, newOwner) async {
              changedGroupId = groupId;
              changedOwner = newOwner;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('member-a'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('转移群组'));
    await tester.pumpAndSettle();

    expect(changedGroupId, 'group-001');
    expect(changedOwner, 'member-a');
    expect(find.text('已转移群组给 member-a'), findsOneWidget);
  });
}
