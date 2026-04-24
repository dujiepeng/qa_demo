import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:qa_flutter/config/app_config.dart';
import 'package:qa_flutter/common/utils/version_manager.dart';
import 'package:qa_flutter/common/widgets/me_page_content.dart';
import 'package:qa_flutter/theme/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  testWidgets('settings page shows check new version action', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: AppSettings()),
          ChangeNotifierProvider.value(value: VersionManager()),
        ],
        child: const MaterialApp(home: MePageContent()),
      ),
    );

    expect(find.text('检查新版本'), findsOneWidget);
  });

  testWidgets(
    'manual check keeps settings page mounted and shows result dialog',
    (tester) async {
      final manager = VersionManager();
      manager.debugSetCheckRunner(({
        required bool force,
        required bool notifyOnChecking,
        required VersionCheckSource source,
      }) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return const VersionCheckResult(
          status: VersionCheckStatus.upToDate,
          message: '当前已是最新版本',
        );
      });
      addTearDown(() => manager.debugSetCheckRunner(null));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: AppSettings()),
            ChangeNotifierProvider.value(value: manager),
          ],
          child: const MaterialApp(home: MePageContent(showAppBar: true)),
        ),
      );

      await tester.tap(find.text('检查新版本'));
      await tester.pump();

      expect(find.text('正在检查新版本...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump();

      expect(find.text('设置'), findsOneWidget);
      expect(find.text('版本检查'), findsOneWidget);
      expect(find.text('当前已是最新版本'), findsOneWidget);
    },
  );

  testWidgets('logout action does not throw when session providers are absent', (
    tester,
  ) async {
    final settings = AppSettings()..isLoggedIn = false;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: VersionManager()),
        ],
        child: MaterialApp(
          routes: {
            '/login': (_) => const Scaffold(body: Text('login-page')),
          },
          home: const MePageContent(showAppBar: true),
        ),
      ),
    );

    await tester.tap(find.text('退出登录'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(settings.isLoggedIn, isFalse);
  });
}
