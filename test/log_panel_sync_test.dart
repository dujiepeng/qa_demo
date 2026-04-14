import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qa_flutter/common/utils/log_panel_sync.dart';

void main() {
  test('appends only new content when log file grows', () async {
    final tempDir = await Directory.systemTemp.createTemp('log-panel-sync');
    addTearDown(() => tempDir.delete(recursive: true));

    final file = File('${tempDir.path}/easemob.log');
    await file.writeAsString('a\nb');

    final initial = await readLogPanelState(file.path);
    expect(initial.content, 'a\nb');
    expect(initial.nextPollInterval, const Duration(seconds: 1));

    await file.writeAsString('a\nb\nc\nd');
    final updated = await readLogPanelState(file.path, previous: initial);

    expect(updated.content, 'a\nb\nc\nd');
    expect(updated.nextPollInterval, const Duration(seconds: 1));
  });

  test('backs off polling interval when file is unchanged', () async {
    final tempDir = await Directory.systemTemp.createTemp('log-panel-backoff');
    addTearDown(() => tempDir.delete(recursive: true));

    final file = File('${tempDir.path}/easemob.log');
    await file.writeAsString('steady');

    final initial = await readLogPanelState(file.path);
    final second = await readLogPanelState(file.path, previous: initial);
    final third = await readLogPanelState(file.path, previous: second);

    expect(second.nextPollInterval, const Duration(seconds: 2));
    expect(third.nextPollInterval, const Duration(seconds: 4));
  });

  test('falls back to full reload when file shrinks', () async {
    final tempDir = await Directory.systemTemp.createTemp('log-panel-truncate');
    addTearDown(() => tempDir.delete(recursive: true));

    final file = File('${tempDir.path}/easemob.log');
    await file.writeAsString('before-truncate');

    final initial = await readLogPanelState(file.path);

    await file.writeAsString('after');
    final updated = await readLogPanelState(file.path, previous: initial);

    expect(updated.content, 'after');
    expect(updated.nextPollInterval, const Duration(seconds: 1));
  });

  test(
    'keeps only the latest log content when exceeding retention limit',
    () async {
      final tempDir = await Directory.systemTemp.createTemp('log-panel-trim');
      addTearDown(() => tempDir.delete(recursive: true));

      final file = File('${tempDir.path}/easemob.log');
      await file.writeAsString('12345');

      final initial = await readLogPanelState(
        file.path,
        maxRetainedCharacters: 5,
      );
      await file.writeAsString('1234567890');

      final updated = await readLogPanelState(
        file.path,
        previous: initial,
        maxRetainedCharacters: 5,
      );

      expect(updated.content, '67890');
    },
  );

  test('uses a slower fallback interval when native file events are active', () {
    expect(
      effectiveLogPanelSyncDelay(
        const Duration(seconds: 2),
        eventUpdatesEnabled: true,
      ),
      eventDrivenFallbackInterval,
    );
    expect(
      effectiveLogPanelSyncDelay(
        const Duration(seconds: 16),
        eventUpdatesEnabled: true,
      ),
      const Duration(seconds: 16),
    );
    expect(
      effectiveLogPanelSyncDelay(
        const Duration(seconds: 2),
        eventUpdatesEnabled: false,
      ),
      const Duration(seconds: 2),
    );
  });
}
