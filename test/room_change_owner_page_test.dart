import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/pages/chatroom/room_change_owner_page.dart';

void main() {
  testWidgets('regular member cannot transfer chatroom owner to self', (
    tester,
  ) async {
    var changeOwnerCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoomChangeOwnerPage(
            roomId: 'room-001',
            roomInfoLoader: (_) async => EMChatRoom(
              roomId: 'room-001',
              owner: 'owner-001',
              permissionType: EMChatRoomPermissionType.Member,
            ),
            membersLoader: (_, {cursor = '', pageSize = 50}) async =>
                EMCursorResult<String>('', const ['alice']),
            ownerChanger: (_, _) async {
              changeOwnerCalled = true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('alice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('转移聊天室'));
    await tester.pumpAndSettle();

    expect(changeOwnerCalled, isFalse);
    expect(find.text('转移聊天室失败: 仅聊天室所有者可操作'), findsOneWidget);
    expect(find.text('已转移聊天室给 alice'), findsNothing);
  });

  testWidgets('owner cannot transfer chatroom owner to current owner', (
    tester,
  ) async {
    var changeOwnerCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoomChangeOwnerPage(
            roomId: 'room-001',
            roomInfoLoader: (_) async => EMChatRoom(
              roomId: 'room-001',
              owner: 'owner-001',
              permissionType: EMChatRoomPermissionType.Owner,
            ),
            membersLoader: (_, {cursor = '', pageSize = 50}) async =>
                EMCursorResult<String>('', const ['owner-001']),
            ownerChanger: (_, _) async {
              changeOwnerCalled = true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('owner-001'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('转移聊天室'));
    await tester.pumpAndSettle();

    expect(changeOwnerCalled, isFalse);
    expect(find.text('转移聊天室失败: 不能转移给当前所有者'), findsOneWidget);
    expect(find.text('已转移聊天室给 owner-001'), findsNothing);
  });
}
