import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qa_flutter/common/utils/connection_status_overlay_controller.dart';
import 'package:qa_flutter/common/widgets/connection_status_overlay.dart';
import 'package:qa_flutter/theme/app_settings.dart';

void main() {
  testWidgets('shows centered connection status message when visible', (
    tester,
  ) async {
    final controller = ConnectionStatusOverlayController()
      ..showMessage('连接状态：已连接');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: AppSettings()),
          ChangeNotifierProvider.value(value: controller),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ConnectionStatusOverlay()),
        ),
      ),
    );

    expect(find.text('连接状态：已连接'), findsOneWidget);

    controller.hide();
    await tester.pump();
  });
}
