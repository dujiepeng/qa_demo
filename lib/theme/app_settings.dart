import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config/server_config.dart';

class AppSettings extends ChangeNotifier {
  static final AppSettings _instance = AppSettings._internal();
  factory AppSettings() => _instance;
  AppSettings._internal();

  // AppKey 相关
  static final String defaultAppKey = ServerEnvironment.tke.appKey; // 默认 AppKey
  static const String defaultCustomAppKey = 'easemob-demo#sdk111'; // 自定义模式默认值

  bool useCustomAppKey = false;
  String _customAppKey = defaultCustomAppKey; // 存储用户自定义的 AppKey

  // 当前环境配置优先，避免切到非 TKE 环境时仍使用 TKE 默认 AppKey。
  String get appKey {
    final envAppKey = _customEnvDict[activeEnvName]?['appKey'] as String?;
    if (envAppKey != null && envAppKey.isNotEmpty) {
      return envAppKey;
    }
    ServerEnvironment? builtInEnv;
    for (final env in ServerEnvironment.environments) {
      if (env.name == activeEnvName) {
        builtInEnv = env;
        break;
      }
    }
    if (builtInEnv != null && builtInEnv.appKey.isNotEmpty) {
      return builtInEnv.appKey;
    }
    return useCustomAppKey ? _customAppKey : defaultAppKey;
  }

  set appKey(String value) {
    if (useCustomAppKey) {
      _customAppKey = value;
    }
  }

  bool useCustomServer = false;
  String imServer = '';
  int imPort = 0;
  String restServer = '';

  final bool _isDarkMode = true; // 强制开启深色模式
  bool get isDarkMode => _isDarkMode;

  bool _isLoggedIn = false; // 登录状态
  bool get isLoggedIn => _isLoggedIn;
  set isLoggedIn(bool value) {
    if (_isLoggedIn != value) {
      _isLoggedIn = value;
      notifyListeners();
    }
  }

  bool _isInit = false; // 初始化状态
  bool get isInit => _isInit;
  set isInit(bool value) {
    if (_isInit != value) {
      _isInit = value;
      notifyListeners();
    }
  }

  bool _isMode = true; // 测试模式
  bool get isMode => _isMode;
  set isMode(bool value) {
    if (_isMode != value) {
      _isMode = value;
      notifyListeners();
    }
  }

  bool _isLogOverlayMinimized = true;
  bool get isLogOverlayMinimized => _isLogOverlayMinimized;

  bool _logBubbleOnRightSide = true;
  bool get logBubbleOnRightSide => _logBubbleOnRightSide;

  double _logBubbleVerticalRatio = 0.7;
  double get logBubbleVerticalRatio => _logBubbleVerticalRatio;

  bool isDirty = false;
  String lastLoginUserId = '';
  String lastLoginPassword = '';

  // 当前选中的集群名称，例如 TKE / NGI / 开发沙箱
  String activeEnvName = 'TKE';

  // 当前集群连接方式快捷读取
  bool get isMsync => _customEnvDict[activeEnvName]?['isMsync'] ?? true;

  // 用于存储各个集群自定义后的字典缓存
  Map<String, Map<String, dynamic>> _customEnvDict = {};

  Map<String, dynamic>? getCustomEnv(String envName) {
    return _customEnvDict[envName];
  }

  void saveCustomEnv(String envName, Map<String, dynamic> data) {
    _customEnvDict[envName] = data;
  }

  // 配置快照，用于对比
  late bool _origUseCustomAppKey;
  late String _origAppKey;
  late bool _origUseCustomServer;
  late String _origImServer;
  late int _origImPort;
  late String _origRestServer;

  // 持久化存储键名
  static const String _keyUseCustomAppKey = 'use_custom_app_key';
  static const String _keyAppKey = 'app_key';
  static const String _keyUseCustomServer = 'use_custom_server';
  static const String _keyImServer = 'im_server';
  static const String _keyImPort = 'im_port';
  static const String _keyRestServer = 'rest_server';
  static const String _keyActiveEnvName = 'active_env_name';
  static const String _keyCustomEnvs = 'custom_envs';
  static const String _keyLogOverlayMinimized = 'log_overlay_minimized';
  static const String _keyLogBubbleOnRightSide = 'log_bubble_on_right_side';
  static const String _keyLogBubbleVerticalRatio = 'log_bubble_vertical_ratio';
  static const String _legacyKeyIsLoggedIn = 'is_logged_in';
  static const String _keyLastLoginUserId = 'last_login_user_id';
  static const String _keyLastLoginPassword = 'last_login_password';

  // 从本地加载存储的配置
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    useCustomAppKey = prefs.getBool(_keyUseCustomAppKey) ?? false;
    _customAppKey = prefs.getString(_keyAppKey) ?? defaultCustomAppKey;
    useCustomServer = prefs.getBool(_keyUseCustomServer) ?? false;
    imServer = prefs.getString(_keyImServer) ?? '';
    imPort = prefs.getInt(_keyImPort) ?? 0;
    restServer = prefs.getString(_keyRestServer) ?? '';
    // 加载历史记录 (为保持老版本兼容暂时留下，新版本UI不展示了)
    final historyJson = prefs.getStringList(_keyConfigHistory);
    if (historyJson != null) {
      configHistory = historyJson
          .map((e) => ServerConfig.fromJson(jsonDecode(e)))
          .toList();
    }

    // 加载多集群配置
    activeEnvName = prefs.getString(_keyActiveEnvName) ?? 'TKE';
    final customEnvsRaw = prefs.getString(_keyCustomEnvs);
    if (customEnvsRaw != null) {
      try {
        final decoded = jsonDecode(customEnvsRaw) as Map<String, dynamic>;
        _customEnvDict = decoded.map(
          (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
        );

        // 使用加载的多集群配置强覆盖遗留的内存字段
        final currentEnv = _customEnvDict[activeEnvName];
        if (currentEnv != null) {
          useCustomAppKey = true;
          useCustomServer = true;
          _customAppKey = currentEnv['appKey'] as String? ?? _customAppKey;
          restServer = currentEnv['restServer'] as String? ?? restServer;
          imServer = currentEnv['msyncServer'] as String? ?? imServer;
          imPort = currentEnv['msyncPort'] as int? ?? imPort;
        }
      } catch (e) {
        _customEnvDict = {};
      }
    }

    // 同时也装载那些基础的黑白模式/选中状态
    // 强制使用深色模式
    // _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
    // 冷启动时总是回到登录页，不复用上次进程保存的登录路由状态。
    isLoggedIn = false;
    await prefs.remove(_legacyKeyIsLoggedIn);
    _isMode = prefs.getBool('is_mode') ?? true;
    _isLogOverlayMinimized = prefs.getBool(_keyLogOverlayMinimized) ?? true;
    _logBubbleOnRightSide = prefs.getBool(_keyLogBubbleOnRightSide) ?? true;
    _logBubbleVerticalRatio = _clampBubbleRatio(
      prefs.getDouble(_keyLogBubbleVerticalRatio) ?? 0.7,
    );
    lastLoginUserId = prefs.getString(_keyLastLoginUserId) ?? '';
    lastLoginPassword = prefs.getString(_keyLastLoginPassword) ?? '';

    _updateSnapshot();
    isDirty = true;
  }

  // 更新快照
  void _updateSnapshot() {
    _origUseCustomAppKey = useCustomAppKey;
    _origAppKey = appKey;
    _origUseCustomServer = useCustomServer;
    _origImServer = imServer;
    _origImPort = imPort;
    _origRestServer = restServer;
  }

  // 将当前配置保存到本地
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseCustomAppKey, useCustomAppKey);
    await prefs.setString(_keyAppKey, _customAppKey); // 保存自定义 AppKey
    await prefs.setBool(_keyUseCustomServer, useCustomServer);
    await prefs.setString(_keyImServer, imServer);
    await prefs.setInt(_keyImPort, imPort);
    await prefs.setString(_keyRestServer, restServer);
    // 保存历史记录
    final historyJson = configHistory
        .map((e) => jsonEncode(e.toJson()))
        .toList();
    await prefs.setStringList(_keyConfigHistory, historyJson);

    // 保存多环境配置
    await prefs.setString(_keyActiveEnvName, activeEnvName);
    await prefs.setString(_keyCustomEnvs, jsonEncode(_customEnvDict));

    // 强制使用深色模式
    await prefs.remove(_legacyKeyIsLoggedIn);
    await prefs.setBool('is_mode', _isMode);
    await prefs.setBool(_keyLogOverlayMinimized, _isLogOverlayMinimized);
    await prefs.setBool(_keyLogBubbleOnRightSide, _logBubbleOnRightSide);
    await prefs.setDouble(
      _keyLogBubbleVerticalRatio,
      _clampBubbleRatio(_logBubbleVerticalRatio),
    );
    await prefs.setString(_keyLastLoginUserId, lastLoginUserId);
    await prefs.setString(_keyLastLoginPassword, lastLoginPassword);

    _updateSnapshot();
    isDirty = true;
  }

  Future<void> setLogOverlayMinimized(bool value) async {
    if (_isLogOverlayMinimized == value) {
      return;
    }
    _isLogOverlayMinimized = value;
    notifyListeners();
    await _saveLogOverlayState();
  }

  Future<void> updateLogBubblePlacement({
    bool? onRightSide,
    double? verticalRatio,
  }) async {
    final nextOnRightSide = onRightSide ?? _logBubbleOnRightSide;
    final nextVerticalRatio = _clampBubbleRatio(
      verticalRatio ?? _logBubbleVerticalRatio,
    );
    if (_logBubbleOnRightSide == nextOnRightSide &&
        _logBubbleVerticalRatio == nextVerticalRatio) {
      return;
    }
    _logBubbleOnRightSide = nextOnRightSide;
    _logBubbleVerticalRatio = nextVerticalRatio;
    notifyListeners();
    await _saveLogOverlayState();
  }

  double _clampBubbleRatio(double value) => value.clamp(0.0, 1.0);

  Future<void> _saveLogOverlayState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLogOverlayMinimized, _isLogOverlayMinimized);
    await prefs.setBool(_keyLogBubbleOnRightSide, _logBubbleOnRightSide);
    await prefs.setDouble(
      _keyLogBubbleVerticalRatio,
      _clampBubbleRatio(_logBubbleVerticalRatio),
    );
  }

  // 检查当前内存状态是否与快照不一致
  bool hasChanged({
    required bool currentUseCustomAppKey,
    required String currentAppKey,
    required bool currentUseCustomServer,
    required String currentImServer,
    required int currentImPort,
    required String currentRestServer,
  }) {
    return currentUseCustomAppKey != _origUseCustomAppKey ||
        currentAppKey != _origAppKey ||
        currentUseCustomServer != _origUseCustomServer ||
        currentImServer != _origImServer ||
        currentImPort != _origImPort ||
        currentRestServer != _origRestServer;
  }

  // 配置历史相关
  List<ServerConfig> configHistory = [];
  static const String _keyConfigHistory = 'config_history';

  ServerConfig? get activeConfig {
    final currentDict = _customEnvDict[activeEnvName];
    if (currentDict == null) return null;
    return ServerConfig(
      envName: activeEnvName,
      appKey: appKey,
      restServer: currentDict['restServer'] as String?,
      msyncServer: currentDict['msyncServer'] as String?,
      msyncPort: currentDict['msyncPort'] as int?,
      wsServer: currentDict['wsServer'] as String?,
      wsPort: currentDict['wsPort'] as int?,
      wsPath: currentDict['wsPath'] as String?,
      dnsUrl: currentDict['dnsUrl'] as String?,
      isMsync: currentDict['isMsync'] as bool?,
      enableTls: currentDict['enableTls'] as bool?,
    );
  }

  void addCurrentConfigToHistory() {
    final newConfig = activeConfig;
    if (newConfig == null) return;
    // 如果已存在相同集群、AppKey 和连接方式的记录，先移除旧的
    configHistory.removeWhere(
      (config) =>
          config.envName == activeEnvName &&
          config.appKey == appKey &&
          config.isMsync == newConfig.isMsync,
    );
    // 插入到头部
    configHistory.insert(0, newConfig);
    // 限制历史记录数量，例如 20 条
    if (configHistory.length > 20) {
      configHistory = configHistory.sublist(0, 20);
    }
  }

  void removeConfigFromHistory(ServerConfig targetConfig) {
    configHistory.removeWhere(
      (config) =>
          config.envName == targetConfig.envName &&
          config.appKey == targetConfig.appKey &&
          config.isMsync == targetConfig.isMsync,
    );
    isDirty = true;
    saveSettings(); // 这里直接保存一下，避免删除后重启又回来了
  }

  void applyConfig(ServerConfig config) {
    activeEnvName = config.envName;

    // 把记录写入字典
    if (_customEnvDict[activeEnvName] == null) {
      _customEnvDict[activeEnvName] = {};
    }
    _customEnvDict[activeEnvName]!
      ..clear()
      ..['appKey'] = config.appKey;
    _putIfNotNull(
      _customEnvDict[activeEnvName]!,
      'restServer',
      config.restServer,
    );
    _putIfNotNull(
      _customEnvDict[activeEnvName]!,
      'msyncServer',
      config.msyncServer,
    );
    _putIfNotNull(
      _customEnvDict[activeEnvName]!,
      'msyncPort',
      config.msyncPort,
    );
    _putIfNotNull(_customEnvDict[activeEnvName]!, 'wsServer', config.wsServer);
    _putIfNotNull(_customEnvDict[activeEnvName]!, 'wsPort', config.wsPort);
    _putIfNotNull(_customEnvDict[activeEnvName]!, 'wsPath', config.wsPath);
    _putIfNotNull(_customEnvDict[activeEnvName]!, 'dnsUrl', config.dnsUrl);
    _putIfNotNull(_customEnvDict[activeEnvName]!, 'isMsync', config.isMsync);
    _putIfNotNull(
      _customEnvDict[activeEnvName]!,
      'enableTls',
      config.enableTls,
    );

    // 强制旧变量更新
    appKey = config.appKey;
    restServer = config.restServer ?? restServer;
    imServer = config.msyncServer ?? imServer;
    imPort = config.msyncPort ?? imPort;

    notifyListeners();
  }
}

void _putIfNotNull(Map<String, dynamic> target, String key, Object? value) {
  if (value != null) {
    target[key] = value;
  }
}

class ServerConfig {
  final String envName;
  final String appKey;
  final String? restServer;
  final String? msyncServer;
  final int? msyncPort;
  final String? wsServer;
  final int? wsPort;
  final String? wsPath;
  final String? dnsUrl;
  final bool? isMsync;
  final bool? enableTls;

  ServerConfig({
    required this.envName,
    required this.appKey,
    this.restServer,
    this.msyncServer,
    this.msyncPort,
    this.wsServer,
    this.wsPort,
    this.wsPath,
    this.dnsUrl,
    this.isMsync,
    this.enableTls,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'envName': envName, 'appKey': appKey};
    _putIfNotNull(json, 'restServer', restServer);
    _putIfNotNull(json, 'msyncServer', msyncServer);
    _putIfNotNull(json, 'msyncPort', msyncPort);
    _putIfNotNull(json, 'wsServer', wsServer);
    _putIfNotNull(json, 'wsPort', wsPort);
    _putIfNotNull(json, 'wsPath', wsPath);
    _putIfNotNull(json, 'dnsUrl', dnsUrl);
    _putIfNotNull(json, 'isMsync', isMsync);
    _putIfNotNull(json, 'enableTls', enableTls);
    return json;
  }

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    String envName = json['envName'] as String? ?? 'TKE';
    return ServerConfig(
      envName: envName,
      appKey: json['appKey'] as String? ?? '',
      restServer: json['restServer'] as String?,
      msyncServer: json['msyncServer'] as String?,
      msyncPort: json['msyncPort'] as int?,
      wsServer: json['wsServer'] as String?,
      wsPort: json['wsPort'] as int?,
      wsPath: json['wsPath'] as String?,
      dnsUrl: json['dnsUrl'] as String?,
      isMsync: json['isMsync'] as bool?,
      enableTls: json['enableTls'] as bool?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServerConfig &&
        other.envName == envName &&
        other.appKey == appKey &&
        other.restServer == restServer &&
        other.msyncServer == msyncServer &&
        other.msyncPort == msyncPort &&
        other.wsServer == wsServer &&
        other.wsPort == wsPort &&
        other.wsPath == wsPath &&
        other.dnsUrl == dnsUrl &&
        other.isMsync == isMsync &&
        other.enableTls == enableTls;
  }

  @override
  int get hashCode {
    return envName.hashCode ^
        appKey.hashCode ^
        restServer.hashCode ^
        msyncServer.hashCode ^
        msyncPort.hashCode ^
        wsServer.hashCode ^
        wsPort.hashCode ^
        wsPath.hashCode ^
        dnsUrl.hashCode ^
        isMsync.hashCode ^
        enableTls.hashCode;
  }
}
