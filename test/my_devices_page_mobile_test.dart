import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/mobile/my_devices_page_mobile.dart';
import 'package:qa_flutter/mobile/my_models.dart';
import 'package:provider/provider.dart';
import 'package:qa_flutter/common/utils/other_logged_in_devices_controller.dart';
import 'package:qa_flutter/theme/app_settings.dart';

void main() {
  testWidgets('device page renders real device fields', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MyDevicesPageMobile(
          devices: const [
            MyDeviceInfo(
              deviceName: 'iPhone 15 Pro',
              resource: 'mobile',
              sourceLabel: '当前设备',
            ),
            MyDeviceInfo(deviceName: 'MacBook Pro', resource: 'desktop'),
          ],
        ),
      ),
    );

    expect(find.text('iPhone 15 Pro'), findsOneWidget);
    expect(find.text('MacBook Pro'), findsOneWidget);
    expect(find.text('当前设备'), findsOneWidget);
    expect(find.text('Resource：mobile'), findsOneWidget);
    expect(find.textContaining('UUID：'), findsNothing);
  });

  testWidgets('device page loads real device fields from callback', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MyDevicesPageMobile(
          loadDevices: () async => [
            EMDeviceInfo('mobile_01', 'uuid-1', 'iPhone 15 Pro'),
            EMDeviceInfo('web_02', 'uuid-2', 'Chrome'),
          ],
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('iPhone 15 Pro'), findsOneWidget);
    expect(find.text('Chrome'), findsOneWidget);
    expect(find.text('Resource：mobile_01'), findsOneWidget);
    expect(find.textContaining('UUID：'), findsNothing);
  });

  testWidgets('device page refresh pulls latest devices from server', (
    tester,
  ) async {
    var loadCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MyDevicesPageMobile(
          loadDevices: () async {
            loadCount++;
            if (loadCount == 1) {
              return [EMDeviceInfo('mobile_01', 'uuid-1', 'iPhone 15 Pro')];
            }
            return [EMDeviceInfo('web_02', 'uuid-2', 'Chrome')];
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(loadCount, 1);
    expect(find.text('iPhone 15 Pro'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(loadCount, 2);
    expect(find.text('Chrome'), findsOneWidget);
    expect(find.text('iPhone 15 Pro'), findsNothing);
  });

  testWidgets(
    'device page loads real devices on open from stored credentials',
    (tester) async {
      final settings = AppSettings();
      settings.lastLoginUserId = 'qa_user';
      settings.lastLoginPassword = 'secret';

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider.value(value: settings)],
          child: MaterialApp(
            home: MyDevicesPageMobile(
              loadStoredDevices: (userId, password) async {
                expect(userId, 'qa_user');
                expect(password, 'secret');
                return [EMDeviceInfo('mobile_01', 'uuid-1', 'iPhone 15 Pro')];
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('iPhone 15 Pro'), findsOneWidget);
      expect(find.text('Resource：mobile_01'), findsOneWidget);
    },
  );

  test('controller refreshes real devices from server callback', () async {
    final controller = OtherLoggedInDevicesController();

    await controller.refreshFromServer(
      loadDevices: () async => [
        EMDeviceInfo('mobile', 'uuid-1', 'iPhone 15 Pro'),
        EMDeviceInfo('web', 'uuid-2', 'Chrome'),
      ],
    );

    expect(controller.deviceCount, 2);
    expect(controller.latestDeviceName, 'iPhone 15 Pro');
    expect(controller.devices.first.resource, 'mobile');
  });

  testWidgets('device page kicks device after password input', (tester) async {
    final settings = AppSettings();
    settings.lastLoginUserId = 'qa_user';

    String? kickedUserId;
    String? kickedPassword;
    String? kickedResource;

    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider.value(value: settings)],
        child: MaterialApp(
          home: MyDevicesPageMobile(
            devices: const [
              MyDeviceInfo(deviceName: 'Chrome', resource: 'web_02'),
            ],
            kickDevice: (userId, password, resource) async {
              kickedUserId = userId;
              kickedPassword = password;
              kickedResource = resource;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('踢下线'));
    await tester.pumpAndSettle();

    expect(find.text('踢下线'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'secret');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(kickedUserId, 'qa_user');
    expect(kickedPassword, 'secret');
    expect(kickedResource, 'web_02');
    expect(find.text('Chrome'), findsNothing);
  });
}
