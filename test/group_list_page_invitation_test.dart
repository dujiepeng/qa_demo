// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:im_flutter_sdk_interface/im_flutter_sdk_interface.dart';
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
    if (method == 'fetchJoinedGroupsFromServer') {
      return {method: <Map>[]};
    }
    if (method == 'acceptInvitationFromGroup') {
      actions.add(_GroupAction(method, request));
      return {
        method: EMGroup(
          groupId: request['groupId'] as String,
          groupName: '邀请群',
        ).toJson(),
      };
    }
    if (method == 'declineInvitationFromGroup') {
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
  });

  tearDown(() {
    EMClient.getInstance.groupManager.removeEventHandler('group_list');
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
    await tester.pumpAndSettle();

    expect(testClient.actions.length, 1);
    expect(testClient.actions.single.method, 'acceptInvitationFromGroup');
    expect(testClient.actions.single.params['groupId'], 'group-001');
    expect(testClient.actions.single.params['inviter'], 'owner-a');
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
}
