import 'package:flutter_test/flutter_test.dart';
import 'package:qa_flutter/common/utils/offline_message_counter.dart';

void main() {
  test('records only messages whose onlineState is false', () {
    final counter = OfflineMessageCounter();

    counter.recordOnlineStates([false, true, null, false]);

    expect(counter.count, 2);
  });

  test('reset clears current session count', () {
    final counter = OfflineMessageCounter();

    counter.recordOnlineStates([false, false]);
    counter.reset();

    expect(counter.count, 0);
  });
}
