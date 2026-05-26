import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/pages/group/group_admins_page.dart';

void main() {
  testWidgets('group admin cannot remove admin when current role is not owner', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroupAdminsPage(
            groupId: 'group-001',
            groupInfoLoader: (_) async => EMGroup(
              groupId: 'group-001',
              adminList: const ['tst01'],
              permissionType: EMGroupPermissionType.Admin,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('tst01'));
    await tester.pumpAndSettle();

    expect(find.text('移除管理员'), findsNothing);
  });

  testWidgets('remove admin reports failure when server list still contains admin', (
    tester,
  ) async {
    var removeCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroupAdminsPage(
            groupId: 'group-001',
            groupInfoLoader: (_) async => EMGroup(
              groupId: 'group-001',
              adminList: const ['tst01'],
              permissionType: EMGroupPermissionType.Owner,
            ),
            adminRemover: (_, _) async {
              removeCalled = true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('tst01'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('移除管理员'));
    await tester.pumpAndSettle();

    expect(removeCalled, isTrue);
    expect(find.text('移除 tst01 管理员成功'), findsNothing);
    expect(find.text('移除 tst01 管理员失败: 服务端管理员列表仍包含该成员'), findsOneWidget);
    expect(find.text('tst01'), findsOneWidget);
  });

  testWidgets('remove admin reports success only after server list excludes admin', (
    tester,
  ) async {
    var loadCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroupAdminsPage(
            groupId: 'group-001',
            groupInfoLoader: (_) async {
              loadCount += 1;
              return EMGroup(
                groupId: 'group-001',
                adminList: loadCount == 1 ? const ['tst01'] : const [],
                permissionType: EMGroupPermissionType.Owner,
              );
            },
            adminRemover: (_, _) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('tst01'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('移除管理员'));
    await tester.pumpAndSettle();

    expect(find.text('移除 tst01 管理员成功'), findsOneWidget);
    expect(find.text('tst01'), findsNothing);
  });
}
