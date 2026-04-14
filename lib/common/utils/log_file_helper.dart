import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';

enum LogFileOpenStatus { ready, unavailable }

class LogFileOpenResult {
  const LogFileOpenResult({
    required this.status,
    this.logPath,
    this.message = '',
  });

  final LogFileOpenStatus status;
  final String? logPath;
  final String message;
}

typedef CompressLogsCallback = Future<String> Function();

String? _cachedReadableLogPath;
Future<LogFileOpenResult>? _pendingPreparation;
const Duration _defaultLogPrepareTimeout = Duration(seconds: 5);
const Duration _defaultFailureCooldown = Duration(seconds: 2);
_CachedUnavailableResult? _cachedUnavailableResult;

class _CachedUnavailableResult {
  const _CachedUnavailableResult({
    required this.result,
    required this.recordedAt,
  });

  final LogFileOpenResult result;
  final DateTime recordedAt;
}

Future<LogFileOpenResult> prepareLogFileForViewing({
  CompressLogsCallback? compressLogs,
  Duration timeout = _defaultLogPrepareTimeout,
  Duration failureCooldown = _defaultFailureCooldown,
}) async {
  final cachedPath = _cachedReadableLogPath;
  if (cachedPath != null && await _isUsableReadablePath(cachedPath)) {
    return LogFileOpenResult(
      status: LogFileOpenStatus.ready,
      logPath: cachedPath,
    );
  }

  final cachedUnavailable = _cachedUnavailableResult;
  if (cachedUnavailable != null &&
      DateTime.now().difference(cachedUnavailable.recordedAt) <
          failureCooldown) {
    return cachedUnavailable.result;
  }

  if (_pendingPreparation != null) {
    return _pendingPreparation!;
  }

  final runCompressLogs = compressLogs ?? EMClient.getInstance.compressLogs;
  final future = _prepareLogFileForViewingInternal(
    runCompressLogs: runCompressLogs,
    timeout: timeout,
  );
  _pendingPreparation = future;

  try {
    return await future;
  } finally {
    if (identical(_pendingPreparation, future)) {
      _pendingPreparation = null;
    }
  }
}

Future<LogFileOpenResult> _prepareLogFileForViewingInternal({
  required CompressLogsCallback runCompressLogs,
  required Duration timeout,
}) async {
  try {
    final rawPath = (await runCompressLogs().timeout(timeout)).trim();
    _cachedUnavailableResult = null;
    if (rawPath.isEmpty) {
      return _cacheUnavailableResult(
        const LogFileOpenResult(
          status: LogFileOpenStatus.unavailable,
          message: '未获取到日志路径',
        ),
      );
    }

    final resolvedPath = await _resolveReadableLogPath(rawPath);
    if (resolvedPath == null) {
      return _cacheUnavailableResult(
        LogFileOpenResult(
          status: LogFileOpenStatus.unavailable,
          message: '未找到可读取的日志文件: $rawPath',
        ),
      );
    }

    _cachedReadableLogPath = resolvedPath;
    return LogFileOpenResult(
      status: LogFileOpenStatus.ready,
      logPath: resolvedPath,
    );
  } on TimeoutException {
    return _cacheUnavailableResult(
      const LogFileOpenResult(
        status: LogFileOpenStatus.unavailable,
        message: '日志导出超时，请稍后重试',
      ),
    );
  } catch (e) {
    return _cacheUnavailableResult(
      LogFileOpenResult(
        status: LogFileOpenStatus.unavailable,
        message: '日志导出失败: $e',
      ),
    );
  }
}

Future<bool> _isUsableReadablePath(String path) async {
  final resolved = await _resolveReadableLogPath(path);
  final isUsable = resolved != null && resolved == path;
  if (!isUsable && identical(_cachedReadableLogPath, path)) {
    _cachedReadableLogPath = null;
  }
  return isUsable;
}

@visibleForTesting
void debugResetLogFilePreparationCache() {
  _cachedReadableLogPath = null;
  _pendingPreparation = null;
  _cachedUnavailableResult = null;
}

LogFileOpenResult _cacheUnavailableResult(LogFileOpenResult result) {
  _cachedUnavailableResult = _CachedUnavailableResult(
    result: result,
    recordedAt: DateTime.now(),
  );
  return result;
}

Future<String?> _resolveReadableLogPath(String rawPath) async {
  final entityType = await FileSystemEntity.type(rawPath);
  switch (entityType) {
    case FileSystemEntityType.file:
      return _resolveFromFile(File(rawPath));
    case FileSystemEntityType.directory:
      return _findCandidateLogFile(Directory(rawPath));
    case FileSystemEntityType.notFound:
      final parent = File(rawPath).parent;
      if (await parent.exists()) {
        return _findCandidateLogFile(parent);
      }
      return null;
    case FileSystemEntityType.link:
      return _resolveReadableLogPath(
        await File(rawPath).resolveSymbolicLinks(),
      );
    case FileSystemEntityType.unixDomainSock:
    case FileSystemEntityType.pipe:
      return null;
  }

  return null;
}

Future<String?> _resolveFromFile(File file) async {
  if (_isReadableLogFile(file.path)) {
    return file.path;
  }

  return _findCandidateLogFile(file.parent);
}

bool _isReadableLogFile(String path) {
  final lowerPath = path.toLowerCase();
  return lowerPath.endsWith('.log') || lowerPath.endsWith('.txt');
}

int _candidatePriority(String path) {
  final lowerName = path.split(Platform.pathSeparator).last.toLowerCase();
  if (lowerName == 'easemob.log') return 0;
  if (lowerName == 'sdk.log') return 1;
  if (lowerName.endsWith('.log')) return 2;
  if (lowerName.endsWith('.txt')) return 3;
  return 4;
}

Future<String?> _findCandidateLogFile(Directory directory) async {
  if (!await directory.exists()) return null;

  final directPreferred = <String>['easemob.log', 'sdk.log'];
  for (final fileName in directPreferred) {
    final candidate = File(
      '${directory.path}${Platform.pathSeparator}$fileName',
    );
    if (await candidate.exists()) {
      return candidate.path;
    }
  }

  String? bestCandidate;
  await for (final entity in directory.list(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File) continue;
    final path = entity.path;
    if (!_isReadableLogFile(path)) continue;

    if (bestCandidate == null ||
        _candidatePriority(path) < _candidatePriority(bestCandidate)) {
      bestCandidate = path;
    }

    if (_candidatePriority(path) == 0) {
      return path;
    }
  }

  return bestCandidate;
}
