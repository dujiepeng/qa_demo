import 'package:flutter/material.dart';

import '../log_content_page.dart';
import '../utils/log_file_helper.dart';

typedef PrepareLogFileCallback = Future<LogFileOpenResult> Function();
typedef PushLogPageCallback =
    Future<void> Function(BuildContext context, String logPath);

Future<void>? _pendingLogPageOpen;

Future<void> openSdkLogPage(
  BuildContext context, {
  PrepareLogFileCallback? prepareLogFile,
  PushLogPageCallback? pushLogPage,
}) async {
  if (_pendingLogPageOpen != null) {
    return _pendingLogPageOpen!;
  }

  final future = _openSdkLogPageInternal(
    context,
    prepareLogFile: prepareLogFile ?? prepareLogFileForViewing,
    pushLogPage:
        pushLogPage ??
        (context, logPath) => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LogContentPage(logPath: logPath),
          ),
        ),
  );
  _pendingLogPageOpen = future;

  try {
    await future;
  } finally {
    if (identical(_pendingLogPageOpen, future)) {
      _pendingLogPageOpen = null;
    }
  }
}

Future<void> _openSdkLogPageInternal(
  BuildContext context, {
  required PrepareLogFileCallback prepareLogFile,
  required PushLogPageCallback pushLogPage,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final progressRoute = DialogRoute<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => const AlertDialog(
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('正在准备日志...'),
        ],
      ),
    ),
  );

  navigator.push(progressRoute);
  final result = await prepareLogFile();

  if (progressRoute.isActive) {
    navigator.removeRoute(progressRoute);
  }

  if (!context.mounted) return;

  if (result.status == LogFileOpenStatus.ready && result.logPath != null) {
    await pushLogPage(context, result.logPath!);
    return;
  }

  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(result.message)));
}

@visibleForTesting
void debugResetLogPageLauncherState() {
  _pendingLogPageOpen = null;
}
