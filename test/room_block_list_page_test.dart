import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_flutter/pages/chatroom/room_block_list_page.dart';

void main() {
  testWidgets('chatroom block list page removes member from block list', (
    tester,
  ) async {
    String? unblockedRoomId;
    List<String>? unblockedMembers;
    int? requestedPageSize;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoomBlockListPage(
            roomId: 'room-001',
            blockListLoader: (_, {pageNum = 1, pageSize = 50}) async {
              requestedPageSize = pageSize;
              return ['alice'];
            },
            memberUnblocker: (roomId, members) async {
              unblockedRoomId = roomId;
              unblockedMembers = members;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('黑名单 (1)'), findsOneWidget);
    expect(find.text('alice'), findsOneWidget);
    expect(requestedPageSize, 50);

    await tester.tap(find.text('alice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('移出黑名单'));
    await tester.pumpAndSettle();

    expect(unblockedRoomId, 'room-001');
    expect(unblockedMembers, ['alice']);
    expect(find.text('已将 alice 移出黑名单'), findsOneWidget);
  });
}
