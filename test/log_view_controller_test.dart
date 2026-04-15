import 'package:flutter_test/flutter_test.dart';
import 'package:qa_flutter/common/widgets/log_view.dart';

void main() {
  test('updates overlay label and clears it for a specific entry', () {
    final controller = LogController();
    final entry = controller.addLog('hello');

    controller.updateEntry(entry, overlayLabel: '已复制');
    expect(controller.entities.single.overlayLabel, '已复制');

    controller.updateEntry(entry, clearOverlay: true);
    expect(controller.entities.single.overlayLabel, isNull);
  });
}
