import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AppSettings extends ChangeNotifier {
  static final AppSettings _instance = AppSettings._internal();
  factory AppSettings() => _instance;
  AppSettings._internal();

  // AppKey 相关
  static const String defaultAppKey = 'easemob#dutest'; // 默认 AppKey（不可修改）
  static const String defaultCustomAppKey = 'easemob-demo#sdk111'; // 自定义模式默认值

  bool useCustomAppKey = false;
  String _customAppKey = defaultCustomAppKey; // 存储用户自定义的 AppKey

  // 根据 useCustomAppKey 返回对应的 AppKey
  String get appKey => useCustomAppKey ? _customAppKey : defaultAppKey;
  set appKey(String value) {
    if (useCustomAppKey) {
      _customAppKey = value;
    }
  }

  bool useCustomServer = false;
  String imServer = '81.70.142.13';
  int imPort = 4300;
  String restServer = 'https://a1-hsb.easemob.com';

  bool _isDarkMode = true; // 默认开启深色模式
  bool get isDarkMode => _isDarkMode;
  set isDarkMode(bool value) {
    if (_isDarkMode != value) {
      _isDarkMode = value;
      notifyListeners();
    }
  }

  bool _isLoggedIn = false; // 登录状态
  bool get isLoggedIn => _isLoggedIn;
  set isLoggedIn(bool value) {
    if (_isLoggedIn != value) {
      _isLoggedIn = value;
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

  bool isDirty = false;

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

  // 从本地加载存储的配置
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    useCustomAppKey = prefs.getBool(_keyUseCustomAppKey) ?? false;
    _customAppKey = prefs.getString(_keyAppKey) ?? defaultCustomAppKey;
    useCustomServer = prefs.getBool(_keyUseCustomServer) ?? false;
    imServer = prefs.getString(_keyImServer) ?? '81.70.142.13';
    imPort = prefs.getInt(_keyImPort) ?? 4300;
    restServer =
        prefs.getString(_keyRestServer) ?? 'https://a1-hsb.easemob.com';
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
    _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
    isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    _isMode = prefs.getBool('is_mode') ?? true;

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

    await prefs.setBool('is_dark_mode', _isDarkMode);
    await prefs.setBool('is_logged_in', isLoggedIn);
    await prefs.setBool('is_mode', _isMode);

    _updateSnapshot();
    isDirty = true;
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

  void addCurrentConfigToHistory() {
    final currentDict = _customEnvDict[activeEnvName];
    if (currentDict == null) return;

    final newConfig = ServerConfig(
      envName: activeEnvName,
      appKey: appKey,
      restServer: currentDict['restServer'] as String? ?? restServer,
      msyncServer: currentDict['msyncServer'] as String? ?? imServer,
      msyncPort: currentDict['msyncPort'] as int? ?? imPort,
      wsServer: currentDict['wsServer'] as String? ?? '',
      wsPort: currentDict['wsPort'] as int? ?? 443,
      isMsync: currentDict['isMsync'] as bool? ?? true,
    );

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
    _customEnvDict[activeEnvName]!['appKey'] = config.appKey;
    _customEnvDict[activeEnvName]!['restServer'] = config.restServer;
    _customEnvDict[activeEnvName]!['msyncServer'] = config.msyncServer;
    _customEnvDict[activeEnvName]!['msyncPort'] = config.msyncPort;
    _customEnvDict[activeEnvName]!['wsServer'] = config.wsServer;
    _customEnvDict[activeEnvName]!['wsPort'] = config.wsPort;
    _customEnvDict[activeEnvName]!['isMsync'] = config.isMsync;

    // 强制旧变量更新
    appKey = config.appKey;
    restServer = config.restServer;
    imServer = config.msyncServer;
    imPort = config.msyncPort;

    notifyListeners();
  }
}

class ServerConfig {
  final String envName;
  final String appKey;
  final String restServer;
  final String msyncServer;
  final int msyncPort;
  final String wsServer;
  final int wsPort;
  final bool isMsync;

  ServerConfig({
    required this.envName,
    required this.appKey,
    required this.restServer,
    required this.msyncServer,
    required this.msyncPort,
    required this.wsServer,
    required this.wsPort,
    required this.isMsync,
  });

  Map<String, dynamic> toJson() => {
    'envName': envName,
    'appKey': appKey,
    'restServer': restServer,
    'msyncServer': msyncServer,
    'msyncPort': msyncPort,
    'wsServer': wsServer,
    'wsPort': wsPort,
    'isMsync': isMsync,
  };

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      envName: json['envName'] as String? ?? 'TKE',
      appKey: json['appKey'] as String? ?? '',
      restServer: json['restServer'] as String? ?? '',
      msyncServer: json['msyncServer'] as String? ?? '',
      msyncPort: json['msyncPort'] as int? ?? 6717,
      wsServer: json['wsServer'] as String? ?? '',
      wsPort: json['wsPort'] as int? ?? 443,
      isMsync: json['isMsync'] as bool? ?? true,
    );
  }
}
