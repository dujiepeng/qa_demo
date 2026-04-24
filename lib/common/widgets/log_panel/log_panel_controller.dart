import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../utils/log_file_helper.dart';
import '../../utils/log_panel_sync.dart';
import '../../utils/sdk_log_update_stream.dart';

const initialLogPanelSyncInterval = Duration(seconds: 1);
const maxRetainedLogPanelCharacters = 120000;
const compactRetainedLogPanelCharacters = 40000;
const logEventDebounceDuration = Duration(milliseconds: 40);

typedef PrepareLogFileForPanelCallback = Future<LogFileOpenResult> Function();
typedef ReadLogPanelStateCallback =
    Future<LogPanelFileState> Function(
      String logPath, {
      LogPanelFileState? previous,
      int maxRetainedCharacters,
    });

class LogPanelSyncStats {
  const LogPanelSyncStats({
    required this.syncCount,
    required this.eventSyncCount,
    required this.debouncedEventBurstCount,
    required this.lastSyncDuration,
    required this.lastContentLength,
    required this.lastLineCount,
  });

  final int syncCount;
  final int eventSyncCount;
  final int debouncedEventBurstCount;
  final Duration lastSyncDuration;
  final int lastContentLength;
  final int lastLineCount;
}

class LogPanelController {
  LogPanelController({
    PrepareLogFileForPanelCallback? prepareLogFile,
    ReadLogPanelStateCallback? readLogState,
    LogUpdateStreamFactory? logUpdateStreamFactory,
    this.maxRetainedCharacters = maxRetainedLogPanelCharacters,
    this.enableFallbackPolling = true,
    this.onStateChanged,
    this.onStatsChanged,
  }) : _prepareLogFile = prepareLogFile ?? prepareLogFileForViewing,
       _readLogState = readLogState ?? readLogPanelState,
       _logUpdateStreamFactory = logUpdateStreamFactory ?? watchSdkLogUpdates;

  final PrepareLogFileForPanelCallback _prepareLogFile;
  final ReadLogPanelStateCallback _readLogState;
  final LogUpdateStreamFactory _logUpdateStreamFactory;
  final int maxRetainedCharacters;
  final bool enableFallbackPolling;
  final VoidCallback? onStateChanged;
  final ValueChanged<LogPanelSyncStats>? onStatsChanged;

  Timer? _logTimer;
  Timer? _eventDebounceTimer;
  StreamSubscription<Object?>? _logUpdateSubscription;
  String _content = '正在加载 SDK 日志...';
  String? _lastLogPath;
  bool _eventUpdatesEnabled = false;
  bool _monitoringActive = true;
  bool _syncInProgress = false;
  bool _syncQueued = false;
  int _syncCount = 0;
  int _eventSyncCount = 0;
  int _debouncedEventBurstCount = 0;
  int _pendingEventCount = 0;
  Duration _lastSyncDuration = Duration.zero;
  int _lastContentLength = 0;
  int _lastLineCount = 0;
  LogPanelFileState? _fileState;

  String get content => _content;
  String? get lastLogPath => _lastLogPath;
  LogPanelFileState? get fileState => _fileState;
  LogPanelSyncStats get stats => LogPanelSyncStats(
    syncCount: _syncCount,
    eventSyncCount: _eventSyncCount,
    debouncedEventBurstCount: _debouncedEventBurstCount,
    lastSyncDuration: _lastSyncDuration,
    lastContentLength: _lastContentLength,
    lastLineCount: _lastLineCount,
  );

  Future<void> initialize() async {
    final result = await _prepareLogFile();
    if (result.status != LogFileOpenStatus.ready || result.logPath == null) {
      return;
    }

    _lastLogPath = result.logPath;
    _subscribeToLogUpdates(result.logPath!);
    await syncLogs();
    _startLogSync();
  }

  Future<void> setMonitoringActive(bool isActive) async {
    if (_monitoringActive == isActive) {
      return;
    }

    _monitoringActive = isActive;
    if (!isActive) {
      _logTimer?.cancel();
      _logUpdateSubscription?.cancel();
      _logUpdateSubscription = null;
      return;
    }

    if (_lastLogPath == null) {
      return;
    }

    _subscribeToLogUpdates(_lastLogPath!);
    await syncLogs();
    _startLogSync();
  }

  Future<void> syncLogs({bool triggeredByEvent = false}) async {
    if (_lastLogPath == null || !_monitoringActive) return;
    if (_syncInProgress) {
      if (triggeredByEvent) {
        _syncQueued = true;
      }
      return;
    }

    _syncInProgress = true;
    final stopwatch = Stopwatch()..start();
    try {
      final nextState = await _readLogState(
        _lastLogPath!,
        previous: _fileState,
        maxRetainedCharacters: maxRetainedCharacters,
      );
      stopwatch.stop();
      _fileState = nextState;
      _syncCount += 1;
      if (triggeredByEvent) {
        _eventSyncCount += 1;
      }
      _lastSyncDuration = stopwatch.elapsed;
      _lastContentLength = nextState.content.length;
      _lastLineCount = nextState.content.isEmpty ? 0 : '\n'.allMatches(nextState.content).length + 1;
      _emitStats();
      if (nextState.content != _content) {
        _content = nextState.content;
        onStateChanged?.call();
      }
    } finally {
      _syncInProgress = false;
      if (_syncQueued) {
        _syncQueued = false;
        unawaited(syncLogs());
      }
    }
  }

  Future<void> clearLog() async {
    if (_lastLogPath == null) return;

    final file = File(_lastLogPath!);
    if (!await file.exists()) {
      return;
    }

    await file.writeAsString('');
    _content = '';
    _fileState = const LogPanelFileState(
      content: '',
      fileLength: 0,
      unchangedCount: 0,
      nextPollInterval: Duration(seconds: 1),
    );
    onStateChanged?.call();
  }

  void dispose() {
    _logTimer?.cancel();
    _eventDebounceTimer?.cancel();
    _logUpdateSubscription?.cancel();
  }

  void _startLogSync() {
    if (!enableFallbackPolling) {
      return;
    }
    _logTimer?.cancel();
    _scheduleNextSync(initialLogPanelSyncInterval);
  }

  void _scheduleNextSync(Duration delay) {
    _logTimer?.cancel();
    _logTimer = Timer(delay, () async {
      await syncLogs();
      if (_monitoringActive) {
        _scheduleNextSync(_nextSyncDelay());
      }
    });
  }

  Duration _nextSyncDelay() {
    final delay = _fileState?.nextPollInterval ?? initialLogPanelSyncInterval;
    return effectiveLogPanelSyncDelay(
      delay,
      eventUpdatesEnabled: _eventUpdatesEnabled,
    );
  }

  void _subscribeToLogUpdates(String logPath) {
    if (!_monitoringActive) {
      return;
    }
    _logUpdateSubscription?.cancel();
    _eventUpdatesEnabled = true;
    _logUpdateSubscription = _logUpdateStreamFactory(logPath).listen(
      (_) {
        _scheduleEventDrivenSync();
      },
      onError: (_, __) {
        _eventUpdatesEnabled = false;
      },
    );
  }

  void _scheduleEventDrivenSync() {
    if (!_monitoringActive) {
      return;
    }
    _eventDebounceTimer?.cancel();
    _eventDebounceTimer = Timer(logEventDebounceDuration, () {
      if (_pendingEventCount > 1) {
        _debouncedEventBurstCount += 1;
      }
      _pendingEventCount = 0;
      unawaited(syncLogs(triggeredByEvent: true));
    });
    _pendingEventCount += 1;
  }

  void _emitStats() {
    onStatsChanged?.call(stats);
    assert(() {
      debugPrint(
        'LogPanel sync stats: total=$_syncCount event=$_eventSyncCount '
        'debounced=$_debouncedEventBurstCount durationMs=${_lastSyncDuration.inMilliseconds} '
        'chars=$_lastContentLength lines=$_lastLineCount',
      );
      return true;
    }());
  }
}
