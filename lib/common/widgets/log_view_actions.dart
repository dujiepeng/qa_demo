import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'log_view.dart';

class LogViewActions {
  static LogAction copyEntry({
    String id = 'copy',
    String title = '复制',
    IconData icon = Icons.copy_outlined,
    Color? foregroundColor,
    String Function(LogEntry entry)? textBuilder,
    Future<void> Function(LogEntry entry)? onCopied,
  }) {
    return LogAction(
      id: id,
      title: title,
      icon: icon,
      foregroundColor: foregroundColor,
      onSelected: (entry) async {
        final text =
            textBuilder?.call(entry) ?? '${entry.timestamp}: ${entry.content}';
        await Clipboard.setData(ClipboardData(text: text));
        await onCopied?.call(entry);
        return null;
      },
    );
  }
}
