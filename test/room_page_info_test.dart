import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/common/widgets/info_dialog.dart';
import 'package:qa_flutter/pages/chatroom/room_page.dart';
import 'package:qa_flutter/theme/app_settings.dart';
import 'package:qa_flutter/theme/app_settings.dart' as app;

void main() {
  testWidgets('chatroom info button shows user room and server info', (
    tester,
  ) async {
    final settings = AppSettings()
      ..useCustomAppKey = true
      ..applyConfig(
        app.ServerConfig(
          envName: 'QA',
          appKey: 'test#demo',
          restServer: 'https://rest.example.com',
          msyncServer: 'tcp.example.com',
          msyncPort: 18000,
          wsServer: 'im.example.com',
          wsPort: 18080,
          isMsync: false,
        ),
      );

    await tester.pumpWidget(
      MaterialApp(
        home: RoomPage(
          roomId: 'room-001',
          userInfoLoader: () async => const RoomInfoDialogUserInfo(
            currentUserId: 'alice',
            deviceId: 'device-001',
          ),
          roomInfoLoader: (_) async => EMChatRoom(
            roomId: 'room-001',
            name: '测试聊天室',
            description: '聊天室描述',
            announcement: '欢迎进入',
            owner: 'owner-001',
            memberCount: 32,
            adminList: const ['admin-a', 'admin-b'],
            isAllMemberMuted: true,
            permissionType: EMChatRoomPermissionType.Admin,
          ),
          settingsOverride: settings,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    expect(find.text('用户信息'), findsOneWidget);
    expect(find.text('当前用户: alice'), findsOneWidget);
    expect(find.text('设备ID: device-001'), findsOneWidget);

    expect(find.text('聊天室信息'), findsOneWidget);
    expect(find.text('聊天室ID: room-001'), findsOneWidget);
    expect(find.text('名称: 测试聊天室'), findsOneWidget);
    expect(find.text('描述: 聊天室描述'), findsOneWidget);
    expect(find.text('公告: 欢迎进入'), findsOneWidget);
    expect(find.text('Owner: owner-001'), findsOneWidget);
    expect(find.text('成员数: 32'), findsOneWidget);
    expect(find.text('管理员数: 2'), findsOneWidget);
    expect(find.text('全员禁言: 是'), findsOneWidget);
    expect(find.text('权限类型: Admin'), findsOneWidget);

    expect(find.text('服务器配置'), findsOneWidget);
    expect(find.text('集群环境: QA'), findsOneWidget);
    expect(find.text('AppKey: test#demo'), findsOneWidget);
    expect(find.text('REST: https://rest.example.com'), findsOneWidget);
    expect(find.text('IM 服务器: im.example.com:18080'), findsOneWidget);
    expect(find.text('连接方式: WebSocket'), findsOneWidget);
  });
}
