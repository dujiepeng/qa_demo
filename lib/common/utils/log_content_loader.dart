import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

class LogContentSnapshot {
  const LogContentSnapshot({
    required this.lines,
    required this.fileSize,
    required this.loadedFromByte,
    required this.hasMoreContent,
    this.statusMessage,
  });

  final List<String> lines;
  final int fileSize;
  final int loadedFromByte;
  final bool hasMoreContent;
  final String? statusMessage;
}

Future<LogContentSnapshot> loadLogContentSnapshot({
  required String logPath,
  required int chunkSizeBytes,
  bool loadMore = false,
  int loadedFromByte = 0,
  List<String> existingLines = const [],
}) async {
  final entityType = await FileSystemEntity.type(logPath);
  if (entityType != FileSystemEntityType.file) {
    return LogContentSnapshot(
      lines: const [],
      fileSize: 0,
      loadedFromByte: 0,
      hasMoreContent: false,
      statusMessage: 'Log file not found at: $logPath',
    );
  }

  final file = File(logPath);
  final fileSize = await file.length();
  final start = loadMore
      ? math.max(loadedFromByte - chunkSizeBytes, 0)
      : math.max(fileSize - chunkSizeBytes, 0);

  final content = await _readFileRange(
    file,
    start: start,
    end: fileSize,
    dropFirstPartialLine: start > 0,
  );
  final nextLines = content.isEmpty ? <String>[] : content.split('\n');

  return LogContentSnapshot(
    lines: loadMore ? [...nextLines, ...existingLines] : nextLines,
    fileSize: fileSize,
    loadedFromByte: start,
    hasMoreContent: start > 0,
  );
}

Future<String> _readFileRange(
  File file, {
  required int start,
  required int end,
  required bool dropFirstPartialLine,
}) async {
  final bytes = await file.openRead(start, end).fold<List<int>>(<int>[], (
    buffer,
    chunk,
  ) {
    buffer.addAll(chunk);
    return buffer;
  });

  if (bytes.isEmpty) return '';

  var text = utf8.decode(bytes, allowMalformed: true);
  if (dropFirstPartialLine) {
    final firstNewline = text.indexOf('\n');
    if (firstNewline >= 0) {
      text = text.substring(firstNewline + 1);
    }
  }

  return text.trimRight();
}
