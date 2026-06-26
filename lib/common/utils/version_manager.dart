import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';

enum VersionCheckStatus { idle, checking, hasUpdate, upToDate, networkError }

enum VersionCheckSource {
  startupSilent,
  loginSilent,
  manualSettings,
  manualLogin,
}

class VersionCheckResult {
  const VersionCheckResult({
    required this.status,
    this.latestVersion = '',
    this.releaseNotes = '',
    this.downloadUrl = '',
    this.message = '',
  });

  final VersionCheckStatus status;
  final String latestVersion;
  final String releaseNotes;
  final String downloadUrl;
  final String message;
}

typedef VersionCheckRunner =
    Future<VersionCheckResult> Function({
      required bool force,
      required bool notifyOnChecking,
      required VersionCheckSource source,
    });

class VersionManager extends ChangeNotifier {
  static final VersionManager _instance = VersionManager._internal();
  factory VersionManager() => _instance;
  VersionManager._internal();

  VersionCheckStatus _status = VersionCheckStatus.idle;
  VersionCheckStatus get status => _status;

  VersionCheckSource _lastCheckSource = VersionCheckSource.startupSilent;
  VersionCheckSource get lastCheckSource => _lastCheckSource;

  bool _hasNewVersion = false;
  bool get hasNewVersion => _hasNewVersion;

  String _latestVersion = '';
  String get latestVersion => _latestVersion;

  String _releaseNotes = '';
  String get releaseNotes => _releaseNotes;

  String _downloadUrl = '';
  String get downloadUrl => _downloadUrl;

  String _lastMessage = '';
  String get lastMessage => _lastMessage;

  // 检查频率限制，避免频繁请求
  DateTime? _lastCheckTime;
  static const Duration _checkInterval = Duration(minutes: 10);

  VersionCheckRunner? _debugCheckRunner;

  Future<void> silentCheck({
    VersionCheckSource source = VersionCheckSource.startupSilent,
  }) async {
    await _runCheck(force: false, notifyOnChecking: false, source: source);
  }

  Future<VersionCheckResult> checkWithResult({
    bool force = true,
    required VersionCheckSource source,
  }) async {
    return _runCheck(force: force, notifyOnChecking: true, source: source);
  }

  Future<void> checkVersion() async {
    await silentCheck();
  }

  @visibleForTesting
  VersionCheckResult debugParseReleaseResponse({
    required int statusCode,
    required String body,
    required String localVersion,
  }) {
    return _parseReleaseResponse(
      statusCode: statusCode,
      body: body,
      localVersion: localVersion,
    );
  }

  @visibleForTesting
  void debugApplyResult(
    VersionCheckResult result, {
    VersionCheckSource source = VersionCheckSource.startupSilent,
  }) {
    _applyResult(result, source: source);
  }

  @visibleForTesting
  void debugSetCheckRunner(VersionCheckRunner? runner) {
    _debugCheckRunner = runner;
  }

  @visibleForTesting
  void debugSetLastCheckTime(DateTime? time) {
    _lastCheckTime = time;
  }

  Future<VersionCheckResult> _runCheck({
    required bool force,
    required bool notifyOnChecking,
    required VersionCheckSource source,
  }) async {
    final shouldThrottle =
        !force &&
        source != VersionCheckSource.startupSilent &&
        source != VersionCheckSource.loginSilent;
    if (shouldThrottle &&
        _lastCheckTime != null &&
        DateTime.now().difference(_lastCheckTime!) < _checkInterval) {
      return _snapshotResult();
    }

    if (_debugCheckRunner != null) {
      final result = await _debugCheckRunner!(
        force: force,
        notifyOnChecking: notifyOnChecking,
        source: source,
      );
      _applyResult(result, source: source);
      return result;
    }

    if (notifyOnChecking) {
      _status = VersionCheckStatus.checking;
      notifyListeners();
    }

    _lastCheckTime = DateTime.now();

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.github.com/repos/dujiepeng/qa_demo/releases/latest',
        ),
      );

      var result = _parseReleaseResponse(
        statusCode: response.statusCode,
        body: response.body,
        localVersion: AppConfig.appVersion,
      );

      if (result.status == VersionCheckStatus.hasUpdate) {
        final changelog = await _fetchChangelog(result.releaseNotes);
        result = VersionCheckResult(
          status: result.status,
          latestVersion: result.latestVersion,
          releaseNotes: changelog,
          downloadUrl: result.downloadUrl,
          message: result.message,
        );
      }

      _applyResult(result, source: source);
      return result;
    } catch (e) {
      final result = VersionCheckResult(
        status: VersionCheckStatus.networkError,
        message: '网络不可达，请稍后重试',
      );
      _applyResult(result, source: source);
      debugPrint('Version check failed: $e');
      return result;
    }
  }

  Future<String> _fetchChangelog(String fallback) async {
    try {
      final changelogResponse = await http.get(
        Uri.parse(
          'https://raw.githubusercontent.com/dujiepeng/qa_demo/dev/changelog.md',
        ),
      );
      if (changelogResponse.statusCode == 200) {
        return utf8.decode(changelogResponse.bodyBytes);
      }
    } catch (e) {
      debugPrint('Failed to fetch changelog: $e');
    }
    return fallback;
  }

  VersionCheckResult _parseReleaseResponse({
    required int statusCode,
    required String body,
    required String localVersion,
  }) {
    if (statusCode != 200) {
      return const VersionCheckResult(
        status: VersionCheckStatus.networkError,
        message: '网络不可达，请稍后重试',
      );
    }

    try {
      final data = json.decode(body);
      final tagName = (data['tag_name'] as String? ?? '').replaceFirst(
        RegExp(r'^v'),
        '',
      );
      final normalizedLocalVersion = localVersion.replaceFirst(
        RegExp(r'^v'),
        '',
      );

      if (_compareVersions(tagName, normalizedLocalVersion) > 0) {
        return VersionCheckResult(
          status: VersionCheckStatus.hasUpdate,
          latestVersion: tagName,
          releaseNotes: data['body'] as String? ?? '',
          downloadUrl: _extractDownloadUrl(data),
          message: '发现新版本',
        );
      }

      return const VersionCheckResult(
        status: VersionCheckStatus.upToDate,
        message: '当前已是最新版本',
      );
    } catch (e) {
      debugPrint('Error parsing release response: $e');
      return const VersionCheckResult(
        status: VersionCheckStatus.networkError,
        message: '网络不可达，请稍后重试',
      );
    }
  }

  String _extractDownloadUrl(dynamic data) {
    if (data is! Map<String, dynamic>) return '';

    final assets = data['assets'];
    if (assets is List) {
      for (final asset in assets) {
        if (asset is Map<String, dynamic>) {
          final name = asset['name'] as String? ?? '';
          if (name.endsWith('.apk')) {
            return asset['browser_download_url'] as String? ?? '';
          }
        }
      }

      if (assets.isNotEmpty && assets.first is Map<String, dynamic>) {
        return (assets.first as Map<String, dynamic>)['browser_download_url']
                as String? ??
            '';
      }
    }

    return data['html_url'] as String? ?? '';
  }

  VersionCheckResult _snapshotResult() {
    return VersionCheckResult(
      status: _status,
      latestVersion: _latestVersion,
      releaseNotes: _releaseNotes,
      downloadUrl: _downloadUrl,
      message: _lastMessage,
    );
  }

  void _applyResult(
    VersionCheckResult result, {
    required VersionCheckSource source,
  }) {
    _status = result.status;
    _lastMessage = result.message;
    _lastCheckSource = source;

    if (result.status == VersionCheckStatus.hasUpdate) {
      _hasNewVersion = true;
      _latestVersion = result.latestVersion;
      _releaseNotes = result.releaseNotes;
      _downloadUrl = result.downloadUrl;
    } else if (result.status == VersionCheckStatus.upToDate) {
      _hasNewVersion = false;
      _latestVersion = '';
      _releaseNotes = '';
      _downloadUrl = '';
    }

    notifyListeners();
  }

  // 版本比较算法
  // 返回 1: v1 > v2
  // 返回 -1: v1 < v2
  // 返回 0: v1 == v2
  int _compareVersions(String v1, String v2) {
    try {
      // 分离版本号和构建号
      final v1Parts = v1.split('+');
      final v2Parts = v2.split('+');

      final v1Version = v1Parts[0]; // 例如: "1.35.0"
      final v2Version = v2Parts[0];

      final v1Build = v1Parts.length > 1
          ? int.tryParse(v1Parts[1]) ?? 0
          : 0; // 例如: 99
      final v2Build = v2Parts.length > 1 ? int.tryParse(v2Parts[1]) ?? 0 : 0;

      // 比较主版本号 (major.minor.patch)
      List<int> n1 = v1Version.split('.').map((s) => int.parse(s)).toList();
      List<int> n2 = v2Version.split('.').map((s) => int.parse(s)).toList();

      // 比较 major.minor.patch
      for (int i = 0; i < 3; i++) {
        int num1 = i < n1.length ? n1[i] : 0;
        int num2 = i < n2.length ? n2[i] : 0;

        if (num1 > num2) return 1;
        if (num1 < num2) return -1;
      }

      // 如果主版本号相同,比较构建号
      if (v1Build > v2Build) return 1;
      if (v1Build < v2Build) return -1;
    } catch (e) {
      debugPrint('Error comparing versions: $e');
    }
    return 0;
  }
}
