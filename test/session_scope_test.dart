import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qa_flutter/common/session_scope.dart';
import 'package:qa_flutter/common/utils/connection_status_overlay_controller.dart';
import 'package:qa_flutter/common/utils/log_service.dart';
import 'package:qa_flutter/common/utils/offline_message_counter.dart';
import 'package:qa_flutter/common/utils/other_logged_in_devices_controller.dart';
import 'package:qa_flutter/theme/app_settings.dart';

void main() {
  testWidgets('QaSessionScope only provides session controllers after login', (
    tester,
  ) async {
    final settings = AppSettings()..isLoggedIn = false;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: MaterialApp(
          home: QaSessionScope(
            child: Builder(
              builder: (context) {
                final hasCounter =
                    Provider.of<OfflineMessageCounter?>(
                      context,
                      listen: false,
                    ) !=
                    null;
                return Text(hasCounter ? 'has-session' : 'no-session');
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('no-session'), findsOneWidget);

    settings.isLoggedIn = true;
    await tester.pump();

    expect(find.text('has-session'), findsOneWidget);
  });

  testWidgets('clearQaSessionState resets all session controller state', (
    tester,
  ) async {
    final settings = AppSettings()..isLoggedIn = true;
    final logService = LogService()..log('hello');
    final counter = OfflineMessageCounter()..recordOnlineStates([false, false]);
    final overlayController = ConnectionStatusOverlayController()
      ..showMessage('连接状态：已连接')
      ..refreshConnectionLight(() async => true);
    final otherDevicesController = OtherLoggedInDevicesController()
      ..recordDeviceLogin('Chrome');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: logService),
          ChangeNotifierProvider.value(value: counter),
          ChangeNotifierProvider.value(value: overlayController),
          ChangeNotifierProvider.value(value: otherDevicesController),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Column(
                children: [
                  Text(
                    '${context.watch<OfflineMessageCounter>().count}/'
                    '${context.watch<OtherLoggedInDevicesController>().deviceCount}/'
                    '${context.watch<ConnectionStatusOverlayController>().isVisible}/'
                    '${context.watch<ConnectionStatusOverlayController>().isConnected}/'
                    '${context.watch<LogService>().logs.length}',
                  ),
                  ElevatedButton(
                    onPressed: () => clearQaSessionState(context),
                    child: const Text('clear'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('2/1/true/true/1'), findsOneWidget);

    await tester.tap(find.text('clear'));
    await tester.pump();

    expect(find.text('0/0/false/null/0'), findsOneWidget);
  });
}
