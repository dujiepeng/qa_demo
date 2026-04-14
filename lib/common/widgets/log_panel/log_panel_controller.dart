import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../utils/log_file_helper.dart';
import '../../utils/log_panel_sync.dart';
import '../../utils/sdk_log_update_stream.dart';

const initialLogPanelSyncInterval = Duration(seconds: 1);
const maxRetainedLogPanelCharacters = 120000;

typedef PrepareLogFileForPanelCallback = Future<LogFileOpenResult> Function();
typedef ReadLogPanelStateCallback =
    Future<LogPanelFileState> Function(
      String logPath, {
      LogPanelFileState? previous,
      int maxRetainedCharacters,
    });

class LogPanelController {
  LogPanelController({
    PrepareLogFileForPanelCallback? prepareLogFile,
    ReadLogPanelStateCallback? readLogState,
    LogUpdateStreamFactory? logUpdateStreamFactory,
    this.enableFallbackPolling = true,
    this.onStateChanged,
  }) : _prepareLogFile = prepareLogFile ?? prepareLogFileForViewing,
       _readLogState = readLogState ?? readLogPanelState,
       _logUpdateStreamFactory = logUpdateStreamFactory ?? watchSdkLogUpdates;

  final PrepareLogFileForPanelCallback _prepareLogFile;
  final ReadLogPanelStateCallback _readLogState;
  final LogUpdateStreamFactory _logUpdateStreamFactory;
  final bool enableFallbackPolling;
  final VoidCallback? onStateChanged;

  Timer? _logTimer;
  StreamSubscription<Object?>? _logUpdateSubscription;
  String _content = '正在加载 SDK 日志...';
  String? _lastLogPath;
  bool _eventUpdatesEnabled = false;
  bool _monitoringActive = true;
  bool _syncInProgress = false;
  bool _syncQueued = false;
  LogPanelFileState? _fileState;

  String get content => _content;
  String? get lastLogPath => _lastLogPath;
  LogPanelFileState? get fileState => _fileState;

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
    try {
      final nextState = await _readLogState(
        _lastLogPath!,
        previous: _fileState,
        maxRetainedCharacters: maxRetainedLogPanelCharacters,
      );
      _fileState = nextState;
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
        unawaited(syncLogs(triggeredByEvent: true));
      },
      onError: (_, __) {
        _eventUpdatesEnabled = false;
      },
    );
  }
}
