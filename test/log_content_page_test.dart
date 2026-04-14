import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qa_flutter/common/utils/log_content_loader.dart';

void main() {
  test('returns readable error when log file is missing', () async {
    final tempDir = await Directory.systemTemp.createTemp('missing-log');
    addTearDown(() => tempDir.delete(recursive: true));
    final missingPath = '${tempDir.path}/missing.log';

    final snapshot = await loadLogContentSnapshot(
      logPath: missingPath,
      chunkSizeBytes: 64,
    );

    expect(snapshot.statusMessage, contains('Log file not found'));
    expect(snapshot.lines, isEmpty);
  });

  test('loads large logs incrementally', () async {
    final tempDir = await Directory.systemTemp.createTemp('log-content-page');
    addTearDown(() => tempDir.delete(recursive: true));

    final file = File('${tempDir.path}/easemob.log');
    final content = List.generate(40, (index) => 'line-$index').join('\n');
    await file.writeAsString(content);

    final tailSnapshot = await loadLogContentSnapshot(
      logPath: file.path,
      chunkSizeBytes: 64,
    );

    expect(tailSnapshot.lines, contains('line-39'));
    expect(tailSnapshot.lines, isNot(contains('line-0')));
    expect(tailSnapshot.hasMoreContent, isTrue);

    final nextSnapshot = await loadLogContentSnapshot(
      logPath: file.path,
      chunkSizeBytes: 64,
      loadMore: true,
      loadedFromByte: tailSnapshot.loadedFromByte,
      existingLines: tailSnapshot.lines,
    );

    expect(nextSnapshot.hasMoreContent, isTrue);
    expect(nextSnapshot.lines.length, greaterThan(tailSnapshot.lines.length));

    final fullSnapshot = await loadLogContentSnapshot(
      logPath: file.path,
      chunkSizeBytes: 512,
      loadMore: true,
      loadedFromByte: nextSnapshot.loadedFromByte,
      existingLines: nextSnapshot.lines,
    );

    expect(fullSnapshot.lines, contains('line-0'));
  });
}
