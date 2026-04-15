import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qa_flutter/common/widgets/layout/mobile_log_overlay.dart';
import 'package:qa_flutter/theme/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings();
    await settings.setLogOverlayMinimized(false);
    await settings.updateLogBubblePlacement(
      onRightSide: true,
      verticalRatio: 0.7,
    );
    settings.isLoggedIn = false;
    settings.isInit = false;
  });

  testWidgets('mobile overlay respects minimized state from settings', (
    tester,
  ) async {
    final settings = AppSettings()
      ..isLoggedIn = true
      ..isInit = false;
    await settings.setLogOverlayMinimized(true);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(390, 844)),
            child: MobileLogOverlay(
              child: Scaffold(body: Center(child: Text('content'))),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.bug_report_outlined), findsOneWidget);
    expect(find.byIcon(Icons.minimize), findsNothing);
  });

  testWidgets('mobile overlay defaults to minimized bubble on fresh settings', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings()
      ..isLoggedIn = true
      ..isInit = false;
    await settings.loadSettings();
    settings.isLoggedIn = true;
    settings.isInit = false;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(390, 844)),
            child: MobileLogOverlay(
              child: Scaffold(body: Center(child: Text('content'))),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.bug_report_outlined), findsOneWidget);
    expect(find.byIcon(Icons.minimize), findsNothing);
  });

  testWidgets('mobile overlay can minimize into bubble and restore', (
    tester,
  ) async {
    final settings = AppSettings()
      ..isLoggedIn = true
      ..isInit = false;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(390, 844)),
            child: MobileLogOverlay(
              child: Scaffold(body: Center(child: Text('content'))),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.minimize), findsOneWidget);

    await tester.tap(find.byIcon(Icons.minimize));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.bug_report_outlined), findsOneWidget);
    expect(find.text('日志'), findsNothing);

    await tester.tap(find.byIcon(Icons.bug_report_outlined));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.bug_report_outlined), findsNothing);
    expect(find.byIcon(Icons.minimize), findsOneWidget);
  });

  testWidgets('mobile overlay does not overflow when resized to minimum height', (
    tester,
  ) async {
    final settings = AppSettings()
      ..isLoggedIn = true
      ..isInit = true;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(390, 280)),
            child: MobileLogOverlay(
              child: Scaffold(body: Center(child: Text('content'))),
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(GestureDetector).first, const Offset(0, 400));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
