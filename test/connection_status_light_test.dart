import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qa_flutter/common/utils/connection_status_overlay_controller.dart';
import 'package:qa_flutter/common/widgets/connection_status_light.dart';
import 'package:qa_flutter/theme/app_settings.dart';

void main() {
  testWidgets('connection status light shows green when connected', (
    tester,
  ) async {
    final controller = ConnectionStatusOverlayController();
    await controller.refreshConnectionLight(() async => true);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: AppSettings()),
          ChangeNotifierProvider.value(value: controller),
        ],
        child: const MaterialApp(
          home: Scaffold(body: Center(child: ConnectionStatusLight())),
        ),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container).last);
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, Colors.green);
  });

  testWidgets('connection status light shows red when disconnected', (
    tester,
  ) async {
    final controller = ConnectionStatusOverlayController();
    await controller.refreshConnectionLight(() async => false);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: AppSettings()),
          ChangeNotifierProvider.value(value: controller),
        ],
        child: const MaterialApp(
          home: Scaffold(body: Center(child: ConnectionStatusLight())),
        ),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container).last);
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, Colors.red);
  });

  testWidgets('connection status light falls back to unknown when provider is absent', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider.value(value: AppSettings())],
        child: const MaterialApp(
          home: Scaffold(body: Center(child: ConnectionStatusLight())),
        ),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container).last);
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, isNot(Colors.green));
    expect(decoration.color, isNot(Colors.red));
    expect(tester.takeException(), isNull);
  });
}
