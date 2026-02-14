import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// 日志管理服务，用于在 UI 上实时展示日志内容
class LogService extends ChangeNotifier {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  final List<String> _logs = [];
  
  /// 获取所有日志内容
  List<String> get logs => List.unmodifiable(_logs);

  /// 添加一条新日志
  void log(String message) {
    final time = DateFormat('HH:mm:ss.SSS').format(DateTime.now());
    _logs.add('[$time] $message');
    // 保持日志数量在合理范围内，避免内存溢出
    if (_logs.length > 500) {
      _logs.removeAt(0);
    }
    notifyListeners();
  }

  /// 清空日志
  void clear() {
    _logs.clear();
    notifyListeners();
  }
}
