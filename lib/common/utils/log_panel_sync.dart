import 'dart:convert';
import 'dart:io';

class LogPanelFileState {
  const LogPanelFileState({
    required this.content,
    required this.fileLength,
    required this.unchangedCount,
    required this.nextPollInterval,
  });

  final String content;
  final int fileLength;
  final int unchangedCount;
  final Duration nextPollInterval;
}

const Duration _minPollInterval = Duration(seconds: 1);
const Duration _maxPollInterval = Duration(seconds: 8);
const Duration eventDrivenFallbackInterval = Duration(seconds: 12);

Future<LogPanelFileState> readLogPanelState(
  String logPath, {
  LogPanelFileState? previous,
  int maxRetainedCharacters = 120000,
}) async {
  final file = File(logPath);
  if (!await file.exists()) {
    return const LogPanelFileState(
      content: '',
      fileLength: 0,
      unchangedCount: 0,
      nextPollInterval: _minPollInterval,
    );
  }

  final length = await file.length();
  if (previous == null) {
    return LogPanelFileState(
      content: _trimToLatest(
        await file.readAsString(),
        maxRetainedCharacters: maxRetainedCharacters,
      ),
      fileLength: length,
      unchangedCount: 0,
      nextPollInterval: _minPollInterval,
    );
  }

  if (length == previous.fileLength) {
    final unchangedCount = previous.unchangedCount + 1;
    return LogPanelFileState(
      content: previous.content,
      fileLength: previous.fileLength,
      unchangedCount: unchangedCount,
      nextPollInterval: _backoffFor(unchangedCount),
    );
  }

  if (length > previous.fileLength) {
    final newBytes = await file
        .openRead(previous.fileLength, length)
        .fold<List<int>>(<int>[], (buffer, chunk) {
          buffer.addAll(chunk);
          return buffer;
        });
    final appended = utf8.decode(newBytes, allowMalformed: true);
    return LogPanelFileState(
      content: _trimToLatest(
        previous.content + appended,
        maxRetainedCharacters: maxRetainedCharacters,
      ),
      fileLength: length,
      unchangedCount: 0,
      nextPollInterval: _minPollInterval,
    );
  }

  return LogPanelFileState(
    content: _trimToLatest(
      await file.readAsString(),
      maxRetainedCharacters: maxRetainedCharacters,
    ),
    fileLength: length,
    unchangedCount: 0,
    nextPollInterval: _minPollInterval,
  );
}

String _trimToLatest(String content, {required int maxRetainedCharacters}) {
  if (content.length <= maxRetainedCharacters) {
    return content;
  }

  return content.substring(content.length - maxRetainedCharacters);
}

Duration _backoffFor(int unchangedCount) {
  final seconds = 1 << unchangedCount.clamp(0, 3);
  return Duration(seconds: seconds).compareTo(_maxPollInterval) > 0
      ? _maxPollInterval
      : Duration(seconds: seconds);
}

Duration effectiveLogPanelSyncDelay(
  Duration suggestedDelay, {
  required bool eventUpdatesEnabled,
}) {
  if (!eventUpdatesEnabled) {
    return suggestedDelay;
  }
  return suggestedDelay < eventDrivenFallbackInterval
      ? eventDrivenFallbackInterval
      : suggestedDelay;
}
