import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:qa_flutter/common/utils/version_manager.dart';
import 'package:qa_flutter/config/app_config.dart';
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
}
