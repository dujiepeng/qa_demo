// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:im_flutter_sdk_interface/im_flutter_sdk_interface.dart';
import 'package:provider/provider.dart';
import 'package:qa_flutter/common/utils/connection_status_overlay_controller.dart';
import 'package:qa_flutter/common/utils/offline_message_counter.dart';
import 'package:qa_flutter/common/utils/other_logged_in_devices_controller.dart';
import 'package:qa_flutter/common/utils/version_manager.dart';
import 'package:qa_flutter/pages/group/group_invitation_store.dart';
import 'package:qa_flutter/pages/home_page.dart';
import 'package:qa_flutter/theme/app_settings.dart';

class _TestClient extends Client {
  final _chatManager = _TestManager();
  final _contactManager = _TestManager();
  final _groupManager = _TestGroupManager();
  bool startCallbackCalled = false;

  @override
  ChatManager get chatManager => _chatManager;

  @override
  ContactManager get contactManager => _contactManager;

  @override
  GroupManager get groupManager => _groupManager;

  @override
  Future<dynamic> callNativeMethod(String method, [dynamic params]) async {
    if (method == 'startCallback') {
      startCallbackCalled = true;
      return {};
    }
    if (method == 'isConnected') {
      return {'isConnected': false};
    }
    return {};
  }

  @override
  void updateNativeHandler(handler) {}
}

class _TestManager extends ContactManager implements ChatManager {
  @override
  Future<dynamic> callNativeMethod(String method, [dynamic params]) async {
    return {};
  }

  @override
  void updateNativeHandler(handler) {}
}

class _TestGroupManager extends GroupManager {
  @override
  Future<dynamic> callNativeMethod(String method, [dynamic params]) async {
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
    EMClient.getInstance.groupManager.clearEventHandlers();
    GroupInvitationStore.instance.clear();
  });

  tearDown(() {
    EMClient.getInstance.contactManager.clearEventHandlers();
    EMClient.getInstance.groupManager.clearEventHandlers();
    GroupInvitationStore.instance.clear();
    Client.instance = previousClient;
  });

  testWidgets('home page shows contact invitation from global SDK callback', (
    tester,
  ) async {
    final settings = AppSettings()
      ..isLoggedIn = true
      ..isInit = true;
    final overlayController = ConnectionStatusOverlayController();
    addTearDown(overlayController.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: VersionManager()),
          ChangeNotifierProvider.value(value: overlayController),
          ChangeNotifierProvider(create: (_) => OfflineMessageCounter()),
          ChangeNotifierProvider(
            create: (_) => OtherLoggedInDevicesController(),
          ),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(390, 844)),
            child: HomePage(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(testClient.startCallbackCalled, isTrue);

    EMClient.getInstance.contactManager
        .getEventHandler('home_page_contact_events')
        ?.onContactInvited
        ?.call('user-a', 'hello');

    expect(overlayController.message, '收到好友申请: user-a (hello)');
    overlayController.hide();
  });

  testWidgets('home page shows multi-device conversation event callback', (
    tester,
  ) async {
    final settings = AppSettings()
      ..isLoggedIn = true
      ..isInit = true;
    final overlayController = ConnectionStatusOverlayController();
    addTearDown(overlayController.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: VersionManager()),
          ChangeNotifierProvider.value(value: overlayController),
          ChangeNotifierProvider(create: (_) => OfflineMessageCounter()),
          ChangeNotifierProvider(
            create: (_) => OtherLoggedInDevicesController(),
          ),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(390, 844)),
            child: HomePage(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(testClient.startCallbackCalled, isTrue);

    EMClient.getInstance
        .getMultiDeviceEventHandler('home_page_multi_device_events')
        ?.onConversationEvent
        ?.call(
          EMMultiDevicesEvent.CONVERSATION_DELETE,
          'conversation-a',
          EMConversationType.Chat,
        );

    expect(
      overlayController.message,
      '多端会话事件: CONVERSATION_DELETE，会话: conversation-a，类型: Chat',
    );
    overlayController.hide();
  });

  testWidgets('home page shows multi-device remote messages removed callback', (
    tester,
  ) async {
    final settings = AppSettings()
      ..isLoggedIn = true
      ..isInit = true;
    final overlayController = ConnectionStatusOverlayController();
    addTearDown(overlayController.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: VersionManager()),
          ChangeNotifierProvider.value(value: overlayController),
          ChangeNotifierProvider(create: (_) => OfflineMessageCounter()),
          ChangeNotifierProvider(
            create: (_) => OtherLoggedInDevicesController(),
          ),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(390, 844)),
            child: HomePage(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(testClient.startCallbackCalled, isTrue);

    EMClient.getInstance
        .getMultiDeviceEventHandler('home_page_multi_device_events')
        ?.onRemoteMessagesRemoved
        ?.call('conversation-a', 'device-a');

    expect(overlayController.message, '多端漫游消息删除: conversation-a，设备: device-a');
    overlayController.hide();
  });

  testWidgets('home page shows group invitation from global SDK callback', (
    tester,
  ) async {
    final settings = AppSettings()
      ..isLoggedIn = true
      ..isInit = true;
    final overlayController = ConnectionStatusOverlayController();
    addTearDown(overlayController.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: VersionManager()),
          ChangeNotifierProvider.value(value: overlayController),
          ChangeNotifierProvider(create: (_) => OfflineMessageCounter()),
          ChangeNotifierProvider(
            create: (_) => OtherLoggedInDevicesController(),
          ),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(390, 844)),
            child: HomePage(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(testClient.startCallbackCalled, isTrue);

    EMClient.getInstance.groupManager
        .getEventHandler('home_page_group_events')
        ?.onInvitationReceivedFromGroup
        ?.call('group-001', '测试群', 'owner-a', 'join us');

    expect(overlayController.message, '收到群组邀请: 测试群，邀请人: owner-a (join us)');
    overlayController.hide();
  });

  testWidgets('home page shows group join request from global SDK callback', (
    tester,
  ) async {
    final settings = AppSettings()
      ..isLoggedIn = true
      ..isInit = true;
    final overlayController = ConnectionStatusOverlayController();
    addTearDown(overlayController.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: VersionManager()),
          ChangeNotifierProvider.value(value: overlayController),
          ChangeNotifierProvider(create: (_) => OfflineMessageCounter()),
          ChangeNotifierProvider(
            create: (_) => OtherLoggedInDevicesController(),
          ),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(390, 844)),
            child: HomePage(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(testClient.startCallbackCalled, isTrue);

    EMClient.getInstance.groupManager
        .getEventHandler('home_page_group_events')
        ?.onRequestToJoinReceivedFromGroup
        ?.call('group-001', '测试群', 'applicant-a', 'approve me');

    expect(
      overlayController.message,
      '收到入群申请: 测试群，申请人: applicant-a (approve me)',
    );
    expect(GroupInvitationStore.instance.joinRequests.length, 1);
    expect(
      GroupInvitationStore.instance.joinRequests.single.applicant,
      'applicant-a',
    );
    overlayController.hide();
  });
}
