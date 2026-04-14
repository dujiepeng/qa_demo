import 'dart:async';

import 'package:flutter/services.dart';

typedef LogUpdateStreamFactory = Stream<Object?> Function(String logPath);

const _sdkLogUpdateChannelName = 'qa_flutter/sdk_log_updates';

Stream<Object?> watchSdkLogUpdates(String logPath) {
  const channel = EventChannel(_sdkLogUpdateChannelName);
  return channel.receiveBroadcastStream(logPath);
}
