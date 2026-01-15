import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class VersionManager extends ChangeNotifier {
  static final VersionManager _instance = VersionManager._internal();
  factory VersionManager() => _instance;
  VersionManager._internal();

  bool _hasNewVersion = false;
  bool get hasNewVersion => _hasNewVersion;

  String _latestVersion = '';
  String get latestVersion => _latestVersion;

  String _releaseNotes = '';
  String get releaseNotes => _releaseNotes;

  // 检查频率限制，避免频繁请求
  DateTime? _lastCheckTime;
  static const Duration _checkInterval = Duration(minutes: 10);

  Future<void> checkVersion() async {
    if (_lastCheckTime != null &&
        DateTime.now().difference(_lastCheckTime!) < _checkInterval) {
      return;
    }

    _lastCheckTime = DateTime.now();

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.github.com/repos/dujiepeng/qa_demo/releases/latest',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String tagName = data['tag_name'] ?? '';

        // 移除可能的 'v' 前缀
        final remoteVersion = tagName.replaceAll('v', '');
        final localVersion = AppConfig.appVersion.replaceAll('v', '');

        if (_compareVersions(remoteVersion, localVersion) > 0) {
          _hasNewVersion = true;
          _latestVersion = remoteVersion;

          try {
            final changelogResponse = await http.get(
              Uri.parse(
                'https://raw.githubusercontent.com/dujiepeng/qa_demo/main/changelog.md',
              ),
            );
            if (changelogResponse.statusCode == 200) {
              _releaseNotes = utf8.decode(changelogResponse.bodyBytes);
            } else {
              _releaseNotes = data['body'] ?? '';
            }
          } catch (e) {
            _releaseNotes = data['body'] ?? '';
            debugPrint('Failed to fetch changelog: $e');
          }

          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Version check failed: $e');
    }
  }

  // 简单的版本比较算法
  // 返回 1: v1 > v2
  // 返回 -1: v1 < v2
  // 返回 0: v1 == v2
  int _compareVersions(String v1, String v2) {
    try {
      // 移除构建号 (+号及后面部分)
      v1 = v1.split('+')[0];
      v2 = v2.split('+')[0];

      List<int> n1 = v1.split('.').map((s) => int.parse(s)).toList();
      List<int> n2 = v2.split('.').map((s) => int.parse(s)).toList();

      for (int i = 0; i < 3; i++) {
        int num1 = i < n1.length ? n1[i] : 0;
        int num2 = i < n2.length ? n2[i] : 0;

        if (num1 > num2) return 1;
        if (num1 < num2) return -1;
      }
    } catch (e) {
      debugPrint('Error comparing versions: $e');
    }
    return 0;
  }
}
