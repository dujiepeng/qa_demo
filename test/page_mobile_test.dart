import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qa_flutter/common/utils/connection_status_overlay_controller.dart';
import 'package:qa_flutter/common/utils/offline_message_counter.dart';
import 'package:qa_flutter/mobile/home_page_mobile.dart';
import 'package:qa_flutter/mobile/page_mobile.dart';
import 'package:qa_flutter/theme/app_settings.dart';

void main() {
  Widget buildMobileApp(Widget home) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: AppSettings()),
        ChangeNotifierProvider.value(value: ConnectionStatusOverlayController()),
      ],
      child: MaterialApp(home: home),
    );
  }

  testWidgets('mobile feature list shows contacts entry', (tester) async {
    await tester.pumpWidget(buildMobileApp(const PageMobile()));

    expect(find.text('联系人'), findsOneWidget);
  });

  testWidgets('mobile feature list shows blacklist entry', (tester) async {
    await tester.pumpWidget(buildMobileApp(const PageMobile()));

    expect(find.text('黑名单'), findsOneWidget);
  });

  testWidgets('mobile feature list shows my entry', (tester) async {
    await tester.pumpWidget(buildMobileApp(const PageMobile()));

    await tester.drag(find.byType(GridView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('我的'), findsOneWidget);
  });

  testWidgets('mobile feature list shows offline message count', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildMobileApp(const PageMobile(offlineMessageCount: 3)),
    );

    expect(find.text('离线消息: 3'), findsOneWidget);
  });

  testWidgets('mobile home shows feature list content', (tester) async {
    final settings = AppSettings()
      ..isLoggedIn = true
      ..isInit = false;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: ConnectionStatusOverlayController()),
          ChangeNotifierProvider.value(value: OfflineMessageCounter()),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(390, 844)),
            child: HomePageMobile(),
          ),
        ),
      ),
    );

    expect(find.text('功能列表'), findsOneWidget);
    expect(find.text('离线消息: 0'), findsOneWidget);
  });

  testWidgets('mobile home falls back to zero when counter provider is absent', (
    tester,
  ) async {
    final settings = AppSettings()
      ..isLoggedIn = false
      ..isInit = false;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: ConnectionStatusOverlayController()),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(390, 844)),
            child: HomePageMobile(),
          ),
        ),
      ),
    );

    expect(find.text('功能列表'), findsOneWidget);
    expect(find.text('离线消息: 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
