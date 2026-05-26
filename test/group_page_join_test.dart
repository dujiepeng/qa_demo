import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/pages/group/group_page.dart';

void main() {
  testWidgets('creating a group sends configured options to SDK callback', (
    tester,
  ) async {
    String? createdName;
    String? createdDesc;
    List<String>? createdMembers;
    String? createdReason;
    EMGroupOptions? createdOptions;

    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          showAppBar: false,
          groupCreator:
              ({
                groupName,
                desc,
                inviteMembers,
                inviteReason,
                required options,
              }) async {
                createdName = groupName;
                createdDesc = desc;
                createdMembers = inviteMembers;
                createdReason = inviteReason;
                createdOptions = options;
                return EMGroup(groupId: 'group-created');
              },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('创建'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '群组名称'), 'qa group');
    await tester.enterText(find.widgetWithText(TextField, '群组描述'), 'desc');
    await tester.enterText(
      find.widgetWithText(TextField, '邀请成员，英文逗号分隔'),
      'alice,bob',
    );
    await tester.enterText(find.widgetWithText(TextField, '创建/邀请原因'), 'reason');
    await tester.enterText(find.widgetWithText(TextField, '最大人数'), '100');
    await tester.tap(find.text('私有成员可邀请'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('公开自由加入').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('需要确认'));
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(createdName, 'qa group');
    expect(createdDesc, 'desc');
    expect(createdMembers, ['alice', 'bob']);
    expect(createdReason, 'reason');
    expect(createdOptions?.style, EMGroupStyle.PublicOpenJoin);
    expect(createdOptions?.inviteNeedConfirm, isTrue);
    expect(createdOptions?.maxCount, 100);
    expect(find.text('Leave'), findsOneWidget);
  });

  testWidgets('approval-required group sends join request instead of joining', (
    tester,
  ) async {
    var joined = false;
    var requestedGroupId = '';

    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          showAppBar: false,
          groupInfoLoader: (_) async =>
              EMGroup(groupId: 'group-001', isMemberOnly: true),
          publicGroupJoiner: (_) async {
            joined = true;
          },
          publicGroupJoinRequester: (groupId, {reason}) async {
            requestedGroupId = groupId;
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'group-001');
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(joined, isFalse);
    expect(requestedGroupId, 'group-001');
    expect(find.textContaining('已发送入群申请'), findsOneWidget);
    expect(find.text('group-001(群)'), findsNothing);
  });

  testWidgets('open public group joins directly', (tester) async {
    var joinedGroupId = '';
    var requested = false;

    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          showAppBar: false,
          groupInfoLoader: (_) async =>
              EMGroup(groupId: 'group-001', isMemberOnly: false),
          publicGroupJoiner: (groupId) async {
            joinedGroupId = groupId;
          },
          publicGroupJoinRequester: (_, {reason}) async {
            requested = true;
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'group-001');
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(joinedGroupId, 'group-001');
    expect(requested, isFalse);
    expect(find.textContaining('加入成功'), findsOneWidget);
  });

  testWidgets('missing approval flag does not guess join path', (tester) async {
    var joined = false;
    var requested = false;

    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          showAppBar: false,
          groupInfoLoader: (_) async => EMGroup(groupId: 'group-001'),
          publicGroupJoiner: (_) async {
            joined = true;
          },
          publicGroupJoinRequester: (_, {reason}) async {
            requested = true;
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'group-001');
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(joined, isFalse);
    expect(requested, isFalse);
    expect(find.textContaining('服务端未返回入群审批信息'), findsOneWidget);
  });

  testWidgets('destroy group action is disabled for non owner', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          groupId: 'group-001',
          showAppBar: false,
          groupInfoLoader: (_) async => EMGroup(
            groupId: 'group-001',
            permissionType: EMGroupPermissionType.Admin,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final destroyButton = tester.widget<ElevatedButton>(
      find.ancestor(of: find.text('解散'), matching: find.byType(ElevatedButton)),
    );
    expect(destroyButton.onPressed, isNull);
  });

  testWidgets('group owner can destroy group after confirmation', (
    tester,
  ) async {
    String? destroyedGroupId;

    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          groupId: 'group-001',
          showAppBar: false,
          groupInfoLoader: (_) async => EMGroup(
            groupId: 'group-001',
            permissionType: EMGroupPermissionType.Owner,
          ),
          groupDestroyer: (groupId) async {
            destroyedGroupId = groupId;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final destroyButton = tester.widget<ElevatedButton>(
      find.ancestor(of: find.text('解散'), matching: find.byType(ElevatedButton)),
    );
    expect(destroyButton.onPressed, isNotNull);

    await tester.tap(find.text('解散'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定解散'));
    await tester.pumpAndSettle();

    expect(destroyedGroupId, 'group-001');
    expect(find.text('Join'), findsOneWidget);
  });

  testWidgets('regular member can block and unblock group messages', (
    tester,
  ) async {
    var messageBlocked = false;
    final calls = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          groupId: 'group-001',
          showAppBar: false,
          groupInfoLoader: (_) async => EMGroup(
            groupId: 'group-001',
            permissionType: EMGroupPermissionType.Member,
            messageBlocked: messageBlocked,
          ),
          groupMessageBlocker: (groupId) async {
            calls.add('block:$groupId');
            messageBlocked = true;
          },
          groupMessageUnblocker: (groupId) async {
            calls.add('unblock:$groupId');
            messageBlocked = false;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('屏蔽消息'), findsOneWidget);
    var blockButton = tester.widget<ElevatedButton>(
      find.ancestor(of: find.text('屏蔽消息'), matching: find.byType(ElevatedButton)),
    );
    expect(blockButton.onPressed, isNotNull);

    await tester.tap(find.text('屏蔽消息'));
    await tester.pumpAndSettle();

    expect(calls, ['block:group-001']);
    expect(find.text('解除屏蔽'), findsOneWidget);

    final unblockButton = tester.widget<ElevatedButton>(
      find.ancestor(of: find.text('解除屏蔽'), matching: find.byType(ElevatedButton)),
    );
    expect(unblockButton.onPressed, isNotNull);

    await tester.tap(find.text('解除屏蔽'));
    await tester.pumpAndSettle();

    expect(calls, ['block:group-001', 'unblock:group-001']);
    expect(find.text('屏蔽消息'), findsOneWidget);
  });

  testWidgets('owner and admin cannot block group messages', (tester) async {
    var calls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          groupId: 'group-001',
          showAppBar: false,
          groupInfoLoader: (_) async => EMGroup(
            groupId: 'group-001',
            permissionType: EMGroupPermissionType.Admin,
            messageBlocked: false,
          ),
          groupMessageBlocker: (_) async {
            calls += 1;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final adminBlockButton = tester.widget<ElevatedButton>(
      find.ancestor(of: find.text('屏蔽消息'), matching: find.byType(ElevatedButton)),
    );
    expect(adminBlockButton.onPressed, isNull);

    await tester.pumpWidget(
      MaterialApp(
        home: GroupPage(
          groupId: 'group-001',
          showAppBar: false,
          groupInfoLoader: (_) async => EMGroup(
            groupId: 'group-001',
            permissionType: EMGroupPermissionType.Owner,
            messageBlocked: false,
          ),
          groupMessageBlocker: (_) async {
            calls += 1;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final ownerBlockButton = tester.widget<ElevatedButton>(
      find.ancestor(of: find.text('屏蔽消息'), matching: find.byType(ElevatedButton)),
    );
    expect(ownerBlockButton.onPressed, isNull);
    expect(calls, 0);
  });
}
