import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qa_flutter/common/utils/log_file_helper.dart';
import 'package:qa_flutter/common/log_content_page.dart';

void main() {
  test('readFullLogFile returns the full log content', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'log-content-full-copy',
    );
    addTearDown(() => tempDir.delete(recursive: true));

    final logFile = File('${tempDir.path}/easemob.log');
    await logFile.writeAsString('line1\nline2\nline3\nline4');

    final content = await readFullLogFile(logFile.path);

    expect(content, 'line1\nline2\nline3\nline4');
  });

  test('copyFullLogForClipboard copies small full log content', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'log-content-small-copy',
    );
    addTearDown(() => tempDir.delete(recursive: true));

    final logFile = File('${tempDir.path}/easemob.log');
    await logFile.writeAsString('line1\nline2');

    String? copiedText;
    final result = await copyFullLogForClipboard(
      logPath: logFile.path,
      copyText: (text) async {
        copiedText = text;
      },
      maxClipboardBytes: 128,
    );

    expect(result.status, FullLogCopyStatus.copiedContent);
    expect(copiedText, 'line1\nline2');
  });

  test('copyFullLogForClipboard exports large log and copies path', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'log-content-large-copy',
    );
    addTearDown(() => tempDir.delete(recursive: true));

    final logFile = File('${tempDir.path}/easemob.log');
    await logFile.writeAsString('line1\nline2\nline3');

    String? copiedText;
    final result = await copyFullLogForClipboard(
      logPath: logFile.path,
      copyText: (text) async {
        copiedText = text;
      },
      exportLogFile: (_) async => const LogFileExportResult(
        status: LogFileExportStatus.exported,
        exportPath: '/sdcard/Download/qa_flutter_logs/easemob.log',
        message: '导出完成',
      ),
      maxClipboardBytes: 4,
    );

    expect(result.status, FullLogCopyStatus.exportedPath);
    expect(
      copiedText,
      r'adb -s emulator-5556 pull "/sdcard/Download/qa_flutter_logs/easemob.log" "$HOME/Downloads/"',
    );
    expect(result.message, contains('分享文本'));
  });
}
