import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qa_flutter/common/utils/log_file_helper.dart';

void main() {
  setUp(() {
    debugResetLogFilePreparationCache();
  });

  group('prepareLogFileForViewing', () {
    test('returns readable log file when sdk returns a directory', () async {
      final tempDir = await Directory.systemTemp.createTemp('log-helper-dir');
      addTearDown(() => tempDir.delete(recursive: true));

      final logFile = File('${tempDir.path}/easemob.log');
      await logFile.writeAsString('hello');

      final result = await prepareLogFileForViewing(
        compressLogs: () async => tempDir.path,
      );

      expect(result.status, LogFileOpenStatus.ready);
      expect(result.logPath, logFile.path);
    });

    test(
      'falls back to sibling easemob.log when sdk returns archive path',
      () async {
        final tempDir = await Directory.systemTemp.createTemp('log-helper-zip');
        addTearDown(() => tempDir.delete(recursive: true));

        final archive = File('${tempDir.path}/log.gz');
        final logFile = File('${tempDir.path}/easemob.log');
        await archive.writeAsString('archive');
        await logFile.writeAsString('hello');

        final result = await prepareLogFileForViewing(
          compressLogs: () async => archive.path,
        );

        expect(result.status, LogFileOpenStatus.ready);
        expect(result.logPath, logFile.path);
      },
    );

    test('returns readable error when sdk throws', () async {
      final result = await prepareLogFileForViewing(
        compressLogs: () => throw Exception('boom'),
      );

      expect(result.status, LogFileOpenStatus.unavailable);
      expect(result.message, contains('boom'));
    });

    test(
      'reuses cached log path without calling native helper again',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'log-helper-cache',
        );
        addTearDown(() => tempDir.delete(recursive: true));

        final logFile = File('${tempDir.path}/easemob.log');
        await logFile.writeAsString('hello');

        var calls = 0;
        Future<String> compress() async {
          calls++;
          return logFile.path;
        }

        final first = await prepareLogFileForViewing(compressLogs: compress);
        final second = await prepareLogFileForViewing(compressLogs: compress);

        expect(first.status, LogFileOpenStatus.ready);
        expect(second.status, LogFileOpenStatus.ready);
        expect(calls, 1);
      },
    );

    test('refreshes cache when cached path is no longer readable', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'log-helper-refresh',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final firstLog = File('${tempDir.path}/easemob.log');
      final secondLog = File('${tempDir.path}/sdk.log');
      await firstLog.writeAsString('one');
      await secondLog.writeAsString('two');

      var calls = 0;
      final result1 = await prepareLogFileForViewing(
        compressLogs: () async {
          calls++;
          return firstLog.path;
        },
      );
      await firstLog.delete();

      final result2 = await prepareLogFileForViewing(
        compressLogs: () async {
          calls++;
          return secondLog.path;
        },
      );

      expect(result1.logPath, isNotNull);
      expect(result2.logPath, secondLog.path);
      expect(calls, 2);
    });

    test('returns timeout error when native helper hangs', () async {
      final completer = Completer<String>();
      final result = await prepareLogFileForViewing(
        compressLogs: () => completer.future,
        timeout: const Duration(milliseconds: 10),
      );

      expect(result.status, LogFileOpenStatus.unavailable);
      expect(result.message, contains('超时'));
    });

    test('throttles repeated failures for a short cooldown window', () async {
      var calls = 0;

      Future<String> compress() async {
        calls++;
        throw Exception('boom');
      }

      final first = await prepareLogFileForViewing(compressLogs: compress);
      final second = await prepareLogFileForViewing(compressLogs: compress);

      expect(first.status, LogFileOpenStatus.unavailable);
      expect(second.status, LogFileOpenStatus.unavailable);
      expect(calls, 1);
    });

    test('retries native export after failure cooldown expires', () async {
      var calls = 0;

      Future<String> compress() async {
        calls++;
        throw Exception('boom');
      }

      await prepareLogFileForViewing(
        compressLogs: compress,
        failureCooldown: const Duration(milliseconds: 20),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await prepareLogFileForViewing(
        compressLogs: compress,
        failureCooldown: const Duration(milliseconds: 20),
      );

      expect(calls, 2);
    });
  });
}
