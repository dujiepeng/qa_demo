// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:im_flutter_sdk_interface/im_flutter_sdk_interface.dart';
import 'package:qa_flutter/pages/single/single_chat_list_page.dart';

class _ContactAction {
  const _ContactAction(this.method, this.userId);

  final String method;
  final String userId;
}

class _TestClient extends Client {
  final _contactManager = _TestContactManager();

  @override
  ContactManager get contactManager => _contactManager;

  List<_ContactAction> get actions => _contactManager.actions;

  @override
  void updateNativeHandler(handler) {}
}

class _TestContactManager extends ContactManager {
  final List<_ContactAction> actions = [];

  @override
  Future<dynamic> callNativeMethod(String method, [dynamic params]) async {
    final userId = params is Map ? params['userId'] as String? : null;
    if ((method == 'acceptInvitation' || method == 'declineInvitation') &&
        userId != null) {
      actions.add(_ContactAction(method, userId));
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
    EMClient.getInstance.contactManager.clearEventHandlers();
  });

  tearDown(() {
    EMClient.getInstance.contactManager.removeEventHandler(
      'single_chat_list_page',
    );
    Client.instance = previousClient;
  });

  testWidgets('friend request callback is shown as a pending invitation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SingleChatListPage(loadContacts: () async => const []),
      ),
    );
    await tester.pumpAndSettle();

    EMClient.getInstance.contactManager
        .getEventHandler('single_chat_list_page')
        ?.onContactInvited
        ?.call('user-a', 'hello');
    await tester.pumpAndSettle();

    expect(find.text('好友申请'), findsOneWidget);
    expect(find.text('user-a'), findsOneWidget);
    expect(find.text('原因: hello'), findsOneWidget);
    expect(find.text('同意'), findsOneWidget);
    expect(find.text('拒绝'), findsOneWidget);
  });

  testWidgets('accepting a pending friend request calls SDK accept invitation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SingleChatListPage(loadContacts: () async => const []),
      ),
    );
    await tester.pumpAndSettle();

    EMClient.getInstance.contactManager
        .getEventHandler('single_chat_list_page')
        ?.onContactInvited
        ?.call('user-a', null);
    await tester.pumpAndSettle();

    await tester.tap(find.text('同意'));
    await tester.pumpAndSettle();

    expect(testClient.actions.length, 1);
    expect(testClient.actions.single.method, 'acceptInvitation');
    expect(testClient.actions.single.userId, 'user-a');
    expect(find.text('user-a'), findsNothing);
  });

  testWidgets('declining a pending friend request calls SDK decline invitation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SingleChatListPage(loadContacts: () async => const []),
      ),
    );
    await tester.pumpAndSettle();

    EMClient.getInstance.contactManager
        .getEventHandler('single_chat_list_page')
        ?.onContactInvited
        ?.call('user-a', null);
    await tester.pumpAndSettle();

    await tester.tap(find.text('拒绝'));
    await tester.pumpAndSettle();

    expect(testClient.actions.length, 1);
    expect(testClient.actions.single.method, 'declineInvitation');
    expect(testClient.actions.single.userId, 'user-a');
    expect(find.text('user-a'), findsNothing);
  });
}
