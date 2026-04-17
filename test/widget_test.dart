import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:qa_flutter/common/utils/connection_status_overlay_controller.dart';
import 'package:qa_flutter/common/utils/log_service.dart';
import 'package:qa_flutter/common/utils/offline_message_counter.dart';
import 'package:qa_flutter/common/utils/other_logged_in_devices_controller.dart';
import 'package:qa_flutter/common/widgets/common_gradient_background.dart';
import 'package:qa_flutter/common/utils/version_manager.dart';
import 'package:qa_flutter/config/app_config.dart';
import 'package:qa_flutter/main.dart';
import 'package:qa_flutter/mobile/login_page_mobile.dart';
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
}
