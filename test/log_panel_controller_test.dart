import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qa_flutter/common/utils/log_file_helper.dart';
import 'package:qa_flutter/common/utils/log_panel_sync.dart';
import 'package:qa_flutter/common/widgets/log_panel/log_panel_controller.dart';

void main() {
  test('loads initial content during initialization', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'log-panel-controller-init',
    );
    addTearDown(() => tempDir.delete(recursive: true));

    final logFile = File('${tempDir.path}/easemob.log');
    await logFile.writeAsString('line1');

    final controller = LogPanelController(
      prepareLogFile: () async => LogFileOpenResult(
        status: LogFileOpenStatus.ready,
        logPath: logFile.path,
      ),
      logUpdateStreamFactory: (_) => const Stream<Object?>.empty(),
    );
    addTearDown(controller.dispose);

    await controller.initialize();

    expect(controller.content, 'line1');
  });

  test('catches up appended logs after monitoring resumes', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'log-panel-controller-resume',
    );
    addTearDown(() => tempDir.delete(recursive: true));

    final logFile = File('${tempDir.path}/easemob.log');
    await logFile.writeAsString('line1');

    final updates = StreamController<Object?>.broadcast();
    addTearDown(() => updates.close());

    final controller = LogPanelController(
      prepareLogFile: () async => LogFileOpenResult(
        status: LogFileOpenStatus.ready,
        logPath: logFile.path,
      ),
      logUpdateStreamFactory: (_) => updates.stream,
      enableFallbackPolling: false,
    );
    addTearDown(controller.dispose);

    await controller.initialize();
    await controller.setMonitoringActive(false);

    await logFile.writeAsString('line1\nline2');

    await controller.setMonitoringActive(true);

    expect(controller.content, 'line1\nline2');
  });

  test('clearing log resets controller state and file content', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'log-panel-controller-clear',
    );
    addTearDown(() => tempDir.delete(recursive: true));

    final logFile = File('${tempDir.path}/easemob.log');
    await logFile.writeAsString('line1');

    final controller = LogPanelController(
      prepareLogFile: () async => LogFileOpenResult(
        status: LogFileOpenStatus.ready,
        logPath: logFile.path,
      ),
      logUpdateStreamFactory: (_) => const Stream<Object?>.empty(),
    );
    addTearDown(controller.dispose);

    await controller.initialize();
    await controller.clearLog();

    expect(controller.content, isEmpty);
    expect(await logFile.readAsString(), isEmpty);
    expect(
      controller.fileState,
      const LogPanelFileState(
        content: '',
        fileLength: 0,
        unchangedCount: 0,
        nextPollInterval: Duration(seconds: 1),
      ),
    );
  });

  test('coalesces burst log update events into a single file sync', () async {
    final updates = StreamController<Object?>.broadcast();
    addTearDown(() => updates.close());

    var content = 'line1';
    var readCalls = 0;

    final controller = LogPanelController(
      prepareLogFile: () async => const LogFileOpenResult(
        status: LogFileOpenStatus.ready,
        logPath: '/tmp/mock.log',
      ),
      readLogState: (
        logPath, {
        previous,
        maxRetainedCharacters = 120000,
      }) async {
        readCalls += 1;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return LogPanelFileState(
          content: content,
          fileLength: content.length,
          unchangedCount: 0,
          nextPollInterval: const Duration(seconds: 1),
        );
      },
      logUpdateStreamFactory: (_) => updates.stream,
      enableFallbackPolling: false,
    );
    addTearDown(controller.dispose);

    await controller.initialize();
    expect(readCalls, 1);

    content = 'line1\nline2';
    updates.add(null);
    updates.add(null);
    updates.add(null);

    await Future<void>.delayed(const Duration(milliseconds: 140));

    expect(controller.content, 'line1\nline2');
    expect(readCalls, 2);
  });

  test('reports sync stats for debug observation', () async {
    final updates = StreamController<Object?>.broadcast();
    addTearDown(() => updates.close());

    LogPanelSyncStats? latestStats;
    var content = 'line1';

    final controller = LogPanelController(
      prepareLogFile: () async => const LogFileOpenResult(
        status: LogFileOpenStatus.ready,
        logPath: '/tmp/mock.log',
      ),
      readLogState: (
        logPath, {
        previous,
        maxRetainedCharacters = 120000,
      }) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return LogPanelFileState(
          content: content,
          fileLength: content.length,
          unchangedCount: 0,
          nextPollInterval: const Duration(seconds: 1),
        );
      },
      logUpdateStreamFactory: (_) => updates.stream,
      enableFallbackPolling: false,
      onStatsChanged: (stats) {
        latestStats = stats;
      },
    );
    addTearDown(controller.dispose);

    await controller.initialize();
    expect(latestStats, isNotNull);
    expect(latestStats!.syncCount, 1);
    expect(latestStats!.lastContentLength, content.length);
    expect(latestStats!.lastLineCount, 1);

    content = 'line1\nline2';
    updates.add(null);
    updates.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 140));

    expect(latestStats!.syncCount, 2);
    expect(latestStats!.eventSyncCount, 1);
    expect(latestStats!.debouncedEventBurstCount, 1);
    expect(latestStats!.lastLineCount, 2);
    expect(latestStats!.lastSyncDuration, greaterThan(Duration.zero));
  });
}
