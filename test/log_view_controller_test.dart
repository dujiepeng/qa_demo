import 'package:flutter/material.dart';
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

  test('updates content style color and overlay for a specific entry', () {
    final controller = LogController();
    final entry = controller.addLog('hello');

    controller.updateEntry(
      entry,
      style: LogStyle.none,
      color: Colors.yellow,
      overlayLabel: 'ACK已发送',
      overlayStyle: LogOverlayStyle.success,
    );

    final updated = controller.entities.single;
    expect(updated.style, LogStyle.none);
    expect(updated.color, Colors.yellow);
    expect(updated.overlayLabel, 'ACK已发送');
    expect(updated.overlayStyle, LogOverlayStyle.success);
  });

  test('changeEntities applies overlay patch to matching entries', () {
    final controller = LogController();
    final first = controller.addLog('first');
    final second = controller.addLog('second');

    controller.changeEntities(
      [first, second],
      overlayLabel: '批量已更新',
      overlayStyle: LogOverlayStyle.warning,
    );

    expect(first.overlayLabel, '批量已更新');
    expect(first.overlayStyle, LogOverlayStyle.warning);
    expect(second.overlayLabel, '批量已更新');
    expect(second.overlayStyle, LogOverlayStyle.warning);
  });
}
