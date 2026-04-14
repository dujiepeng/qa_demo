import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_flutter/common/widgets/log_panel/log_panel_visibility_observer.dart';

void main() {
  test('maps app lifecycle states to foreground visibility', () {
    expect(isAppLifecycleForeground(AppLifecycleState.resumed), isTrue);
    expect(isAppLifecycleForeground(AppLifecycleState.inactive), isFalse);
    expect(isAppLifecycleForeground(AppLifecycleState.hidden), isFalse);
    expect(isAppLifecycleForeground(AppLifecycleState.paused), isFalse);
    expect(isAppLifecycleForeground(AppLifecycleState.detached), isFalse);
  });

  test('notifies only when effective visibility changes', () {
    final values = <bool>[];
    final observer = LogPanelVisibilityObserver(
      onVisibilityChanged: values.add,
    );

    observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
    observer.didPushNext();
    observer.didPopNext();
    observer.didChangeAppLifecycleState(AppLifecycleState.paused);
    observer.didPop();

    expect(values, <bool>[false, true, false]);
  });
}
