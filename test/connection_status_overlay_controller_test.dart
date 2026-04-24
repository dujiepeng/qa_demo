import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_flutter/common/utils/connection_status_overlay_controller.dart';

void main() {
  test('showMessage displays message then auto hides after 3 seconds', () {
    fakeAsync((async) {
      final controller = ConnectionStatusOverlayController();

      controller.showMessage('连接状态：已连接');
      expect(controller.message, '连接状态：已连接');
      expect(controller.isVisible, isTrue);

      async.elapse(const Duration(seconds: 3));

      expect(controller.message, isNull);
      expect(controller.isVisible, isFalse);
    });
  });

  test('refreshConnectionLight updates connected state', () async {
    final controller = ConnectionStatusOverlayController();

    await controller.refreshConnectionLight(() async => true);
    expect(controller.isConnected, isTrue);

    await controller.refreshConnectionLight(() async => false);
    expect(controller.isConnected, isFalse);
  });
}
