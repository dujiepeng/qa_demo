// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:im_flutter_sdk_interface/im_flutter_sdk_interface.dart';
import 'package:qa_flutter/pages/group/group_invitation_store.dart';
import 'package:qa_flutter/pages/group/group_list_page.dart';

class _GroupAction {
  const _GroupAction(this.method, this.params);

  final String method;
  final Map params;
}

class _TestClient extends Client {
  final _groupManager = _TestGroupManager();

  @override
  GroupManager get groupManager => _groupManager;

  List<_GroupAction> get actions => _groupManager.actions;

  @override
  void updateNativeHandler(handler) {}
}

class _TestGroupManager extends GroupManager {
  final List<_GroupAction> actions = [];

  @override
  Future<dynamic> callNativeMethod(String method, [dynamic params]) async {
    final request = params is Map ? params : <String, dynamic>{};
    if (method == 'getJoinedGroupsFromServer') {
      return {method: <Map>[]};
    }
    if (method == 'fetchJoinedGroupCount') {
      actions.add(_GroupAction(method, request));
      return {method: 7};
    }
    if (method == 'acceptInvitationFromGroup') {
      actions.add(_GroupAction(method, request));
      return {
        method: {
          'groupId': request['groupId'] as String,
          'name': '邀请群',
          'permissionType': 0,
        },
      };
    }
    if (method == 'declineInvitationFromGroup') {
      actions.add(_GroupAction(method, request));
      return {};
    }
    if (method == 'acceptJoinApplication') {
      actions.add(_GroupAction(method, request));
      return {};
    }
    if (method == 'declineJoinApplication') {
      actions.add(_GroupAction(method, request));
      return {};
    }
    return {};
  }

  @override
  void updateNativeHandler(handler) {}
}

void main() {
  late Client previousClient;
  late _TestClient testClient;

  setUp(() {
    previousClient = Client.instance;
    testClient = _TestClient();
    Client.instance = testClient;
    EMClient.getInstance.groupManager.clearEventHandlers();
    GroupInvitationStore.instance.clear();
  });

  tearDown(() {
    EMClient.getInstance.groupManager.removeEventHandler('group_list');
    GroupInvitationStore.instance.clear();
    Client.instance = previousClient;
  });

  testWidgets('group invitation callback is shown as a pending invitation', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GroupListPage()));
    await tester.pumpAndSettle();

    EMClient.getInstance.groupManager
        .getEventHandler('group_list')
        ?.onInvitationReceivedFromGroup
        ?.call('group-001', '邀请群', 'owner-a', 'join us');
    await tester.pumpAndSettle();

    expect(find.text('群组邀请'), findsOneWidget);
    expect(find.text('邀请群'), findsOneWidget);
    expect(find.text('邀请人: owner-a'), findsOneWidget);
    expect(find.text('原因: join us'), findsOneWidget);
    expect(find.text('同意'), findsOneWidget);
    expect(find.text('拒绝'), findsOneWidget);
  });

  testWidgets('stored group invitation is shown after entering group list', (
    tester,
  ) async {
    GroupInvitationStore.instance.record(
      const GroupInvitation(
        groupId: 'group-001',
        groupName: '邀请群',
        inviter: 'owner-a',
        reason: 'join us',
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: GroupListPage()));
    await tester.pumpAndSettle();

    expect(find.text('群组邀请'), findsOneWidget);
    expect(find.text('邀请群'), findsOneWidget);
    expect(find.text('邀请人: owner-a'), findsOneWidget);
    expect(find.text('原因: join us'), findsOneWidget);
    expect(find.text('同意'), findsOneWidget);
    expect(find.text('拒绝'), findsOneWidget);
  });

  testWidgets('accepting a group invitation calls SDK accept invitation', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GroupListPage()));
    await tester.pumpAndSettle();

    EMClient.getInstance.groupManager
        .getEventHandler('group_list')
        ?.onInvitationReceivedFromGroup
        ?.call('group-001', '邀请群', 'owner-a', null);
    await tester.pumpAndSettle();

    await tester.tap(find.text('同意'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(testClient.actions.length, 1);
    expect(testClient.actions.single.method, 'acceptInvitationFromGroup');
    expect(testClient.actions.single.params['groupId'], 'group-001');
    expect(testClient.actions.single.params['inviter'], 'owner-a');
    expect(find.textContaining('同意群组邀请失败'), findsNothing);
    expect(find.text('群组邀请'), findsNothing);
  });

  testWidgets('declining a group invitation calls SDK decline invitation', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GroupListPage()));
    await tester.pumpAndSettle();

    EMClient.getInstance.groupManager
        .getEventHandler('group_list')
        ?.onInvitationReceivedFromGroup
        ?.call('group-001', '邀请群', 'owner-a', null);
    await tester.pumpAndSettle();

    await tester.tap(find.text('拒绝'));
    await tester.pumpAndSettle();

    expect(testClient.actions.length, 1);
    expect(testClient.actions.single.method, 'declineInvitationFromGroup');
    expect(testClient.actions.single.params['groupId'], 'group-001');
    expect(testClient.actions.single.params['inviter'], 'owner-a');
    expect(find.text('群组邀请'), findsNothing);
  });

  testWidgets('group join request callback is shown as pending approval', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GroupListPage()));
    await tester.pumpAndSettle();

    EMClient.getInstance.groupManager
        .getEventHandler('group_list')
        ?.onRequestToJoinReceivedFromGroup
        ?.call('group-001', '审批群', 'applicant-a', 'please approve');
    await tester.pumpAndSettle();

    expect(find.text('入群申请'), findsOneWidget);
    expect(find.text('审批群'), findsOneWidget);
    expect(find.text('申请人: applicant-a'), findsOneWidget);
    expect(find.text('原因: please approve'), findsOneWidget);
    expect(find.text('同意'), findsOneWidget);
    expect(find.text('拒绝'), findsOneWidget);
  });

  testWidgets('accepting a group join request calls SDK accept application', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GroupListPage()));
    await tester.pumpAndSettle();

    EMClient.getInstance.groupManager
        .getEventHandler('group_list')
        ?.onRequestToJoinReceivedFromGroup
        ?.call('group-001', '审批群', 'applicant-a', null);
    await tester.pumpAndSettle();

    await tester.tap(find.text('同意'));
    await tester.pumpAndSettle();

    expect(testClient.actions.length, 1);
    expect(testClient.actions.single.method, 'acceptJoinApplication');
    expect(testClient.actions.single.params['groupId'], 'group-001');
    expect(testClient.actions.single.params['userId'], 'applicant-a');
    expect(find.textContaining('同意入群申请失败'), findsNothing);
    expect(find.text('入群申请'), findsNothing);
  });

  testWidgets('declining a group join request calls SDK decline application', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GroupListPage()));
    await tester.pumpAndSettle();

    EMClient.getInstance.groupManager
        .getEventHandler('group_list')
        ?.onRequestToJoinReceivedFromGroup
        ?.call('group-001', '审批群', 'applicant-a', null);
    await tester.pumpAndSettle();

    await tester.tap(find.text('拒绝'));
    await tester.pumpAndSettle();

    expect(testClient.actions.length, 1);
    expect(testClient.actions.single.method, 'declineJoinApplication');
    expect(testClient.actions.single.params['groupId'], 'group-001');
    expect(testClient.actions.single.params['userId'], 'applicant-a');
    expect(testClient.actions.single.params['reason'], 'declined from QA app');
    expect(find.text('入群申请'), findsNothing);
  });

  testWidgets('fetching joined group count shows server result', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GroupListPage()));
    await tester.pumpAndSettle();

    expect(find.text('群组数量'), findsOneWidget);

    await tester.tap(find.text('群组数量'));
    await tester.pumpAndSettle();

    expect(testClient.actions.single.method, 'fetchJoinedGroupCount');
    expect(find.text('已加入群组数量: 7'), findsOneWidget);
  });
}
