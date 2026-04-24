import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:qa_flutter/common/utils/connection_status_overlay_controller.dart';
import 'package:qa_flutter/common/utils/log_service.dart';
import 'package:qa_flutter/common/utils/offline_message_counter.dart';
import 'package:qa_flutter/common/utils/other_logged_in_devices_controller.dart';
import 'package:qa_flutter/common/widgets/common_gradient_background.dart';
import 'package:qa_flutter/common/widgets/layout/mobile_log_overlay.dart';
import 'package:qa_flutter/common/utils/version_manager.dart';
import 'package:qa_flutter/config/app_config.dart';
import 'package:qa_flutter/main.dart';
import 'package:qa_flutter/mobile/login_page_mobile.dart';
import 'package:qa_flutter/mobile/page_mobile.dart';
import 'package:qa_flutter/theme/app_settings.dart';

void main() {
  setUp(() async {
    PackageInfo.setMockInitialValues(
      appName: 'QA Flutter',
      packageName: 'com.example.qa_flutter',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    await AppConfig.init();
  });

  testWidgets('mobile login page shows version check action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: AppSettings()),
          ChangeNotifierProvider.value(value: VersionManager()),
        ],
        child: const MaterialApp(home: LoginPageMobile()),
      ),
    );

    expect(find.byIcon(Icons.system_update_alt_outlined), findsOneWidget);
  });

  testWidgets('MyApp provides shared gradient background behind routes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: AppSettings()),
          ChangeNotifierProvider.value(value: VersionManager()),
          ChangeNotifierProvider(create: (_) => LogService()),
          ChangeNotifierProvider(create: (_) => OfflineMessageCounter()),
          ChangeNotifierProvider(
            create: (_) => ConnectionStatusOverlayController(),
          ),
          ChangeNotifierProvider(create: (_) => OtherLoggedInDevicesController()),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pump();

    expect(find.byType(CommonGradientBackground), findsWidgets);
  });

  testWidgets('MyApp shows mobile log overlay on non-login routes only', (
    WidgetTester tester,
  ) async {
    final settings = AppSettings()..isLoggedIn = false;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: VersionManager()),
          ChangeNotifierProvider(create: (_) => LogService()),
          ChangeNotifierProvider(create: (_) => OfflineMessageCounter()),
          ChangeNotifierProvider(
            create: (_) => ConnectionStatusOverlayController(),
          ),
          ChangeNotifierProvider(create: (_) => OtherLoggedInDevicesController()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.bug_report_outlined), findsNothing);

    settings.isLoggedIn = true;
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/me_page');
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.bug_report_outlined), findsOneWidget);
  });

  testWidgets('MyApp global mobile log overlay can expand safely', (
    WidgetTester tester,
  ) async {
    final settings = AppSettings()
      ..isLoggedIn = true
      ..isInit = true;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider(
            create: (_) => ConnectionStatusOverlayController(),
          ),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(430, 844)),
            child: MobileLogOverlay(child: PageMobile()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.bug_report_outlined));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
