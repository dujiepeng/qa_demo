import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/pages/chatroom/room_members_page.dart';

void main() {
  testWidgets('member actions can add chatroom member to block list', (
    tester,
  ) async {
    String? blockedRoomId;
    List<String>? blockedMembers;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoomMembersPage(
            roomId: 'room-001',
            currentUserIdLoader: () async => 'bob',
            membersLoader: (_, {cursor = '', pageSize = 50}) async =>
                EMCursorResult<String>('', const ['alice']),
            memberBlocker: (roomId, members) async {
              blockedRoomId = roomId;
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

    expect(blockedRoomId, 'room-001');
    expect(blockedMembers, ['alice']);
    expect(find.text('已将 alice 加入黑名单'), findsOneWidget);
  });

  testWidgets('member actions can remove chatroom member from room', (
    tester,
  ) async {
    String? removedRoomId;
    List<String>? removedMembers;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoomMembersPage(
            roomId: 'room-001',
            currentUserIdLoader: () async => 'bob',
            membersLoader: (_, {cursor = '', pageSize = 50}) async =>
                EMCursorResult<String>('', const ['alice']),
            memberRemover: (roomId, members) async {
              removedRoomId = roomId;
              removedMembers = members;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('alice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('移出聊天室'));
    await tester.pumpAndSettle();

    expect(removedRoomId, 'room-001');
    expect(removedMembers, ['alice']);
    expect(find.text('已将 alice 移出聊天室'), findsOneWidget);
  });

  testWidgets('member actions do not show remove room action for self', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoomMembersPage(
            roomId: 'room-001',
            currentUserIdLoader: () async => 'alice',
            membersLoader: (_, {cursor = '', pageSize = 50}) async =>
                EMCursorResult<String>('', const ['alice']),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('alice'));
    await tester.pumpAndSettle();

    expect(find.text('移出聊天室'), findsNothing);
  });
}
