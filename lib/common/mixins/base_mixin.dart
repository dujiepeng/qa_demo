import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:path_provider/path_provider.dart';
import '../widgets/log_view.dart';

/// 测试页面的基础 Mixin，提供常用的日志处理和文件获取功能
mixin BaseMixin<T extends StatefulWidget> on State<T> {
  LogController get logController;

  void addLog(String content) => logController.addLog(content);
  void addAppErrLog(String content) =>
      logController.addLog(content, color: Colors.red);
  void addSendLog(String content, {Object? attachment, String? tag}) =>
      logController.addLog(
        content,
        color: Colors.green,
        attachment: attachment,
        tag: tag,
      );
  void addReceiveLog(String content, {Object? attachment, String? tag}) =>
      logController.addLog(
        content,
        color: Colors.blue,
        attachment: attachment,
        tag: tag,
      );

  /// 获取 asset 文件路径，用于发送媒体消息
  Future<String> getAssetFilePath(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final fileName = assetPath.split('/').last;
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file.path;
  }
}
