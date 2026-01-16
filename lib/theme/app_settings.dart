import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AppSettings extends ChangeNotifier {
  static final AppSettings _instance = AppSettings._internal();
  factory AppSettings() => _instance;
  AppSettings._internal();

  bool useCustomAppKey = false;
  String appKey = 'easemob#dutest';

  bool useCustomServer = false;
  String imServer = '';
  int imPort = 6717;
  String restServer = '';

  bool _isDarkMode = true; // 默认开启深色模式
  bool get isDarkMode => _isDarkMode;
  set isDarkMode(bool value) {
    if (_isDarkMode != value) {
      _isDarkMode = value;
      notifyListeners();
    }
  }

  bool isLoggedIn = false; // 登录状态

  bool _isTestMode = false; // 测试模式
  bool get isTestMode => _isTestMode;
  set isTestMode(bool value) {
    if (_isTestMode != value) {
      _isTestMode = value;
      notifyListeners();
    }
  }

  bool isDirty = false;

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
  static const String _keyIsDarkMode = 'is_dark_mode';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyIsTestMode = 'is_test_mode';

  // 从本地加载存储的配置
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    useCustomAppKey = prefs.getBool(_keyUseCustomAppKey) ?? false;
    appKey = prefs.getString(_keyAppKey) ?? 'easemob#dutest';
    useCustomServer = prefs.getBool(_keyUseCustomServer) ?? false;
    imServer = prefs.getString(_keyImServer) ?? '';
    imPort = prefs.getInt(_keyImPort) ?? 6717;
    restServer = prefs.getString(_keyRestServer) ?? '';
    _isDarkMode = prefs.getBool(_keyIsDarkMode) ?? true;
    isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    _isTestMode = prefs.getBool(_keyIsTestMode) ?? false;

    // 加载历史记录
    final historyJson = prefs.getStringList(_keyConfigHistory);
    if (historyJson != null) {
      configHistory = historyJson
          .map((e) => ServerConfig.fromJson(jsonDecode(e)))
          .toList();
    }

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
    await prefs.setString(_keyAppKey, appKey);
    await prefs.setBool(_keyUseCustomServer, useCustomServer);
    await prefs.setString(_keyImServer, imServer);
    await prefs.setInt(_keyImPort, imPort);
    await prefs.setString(_keyRestServer, restServer);
    await prefs.setBool(_keyIsDarkMode, _isDarkMode);
    await prefs.setBool(_keyIsLoggedIn, isLoggedIn);
    await prefs.setBool(_keyIsTestMode, _isTestMode);

    // 保存历史记录
    final historyJson = configHistory
        .map((e) => jsonEncode(e.toJson()))
        .toList();
    await prefs.setStringList(_keyConfigHistory, historyJson);

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
    final newConfig = ServerConfig(
      appKey: appKey,
      useCustomAppKey: useCustomAppKey,
      useCustomServer: useCustomServer,
      imServer: imServer,
      imPort: imPort,
      restServer: restServer,
    );

    // 如果已存在相同的 AppKey，先移除旧的
    configHistory.removeWhere((config) => config.appKey == appKey);
    // 插入到头部
    configHistory.insert(0, newConfig);
    // 限制历史记录数量，例如 20 条
    if (configHistory.length > 20) {
      configHistory = configHistory.sublist(0, 20);
    }
  }

  void removeConfigFromHistory(String targetAppKey) {
    configHistory.removeWhere((config) => config.appKey == targetAppKey);
    isDirty = true;
    saveSettings(); // 这里直接保存一下，避免删除后重启又回来了
  }

  void applyConfig(ServerConfig config) {
    useCustomAppKey = config.useCustomAppKey;
    appKey = config.appKey;
    useCustomServer = config.useCustomServer;
    imServer = config.imServer;
    imPort = config.imPort;
    restServer = config.restServer;
    notifyListeners();
  }
}

class ServerConfig {
  final String appKey;
  final bool useCustomAppKey;
  final bool useCustomServer;
  final String imServer;
  final int imPort;
  final String restServer;

  ServerConfig({
    required this.appKey,
    required this.useCustomAppKey,
    required this.useCustomServer,
    required this.imServer,
    required this.imPort,
    required this.restServer,
  });

  Map<String, dynamic> toJson() => {
    'appKey': appKey,
    'useCustomAppKey': useCustomAppKey,
    'useCustomServer': useCustomServer,
    'imServer': imServer,
    'imPort': imPort,
    'restServer': restServer,
  };

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      appKey: json['appKey'] as String,
      useCustomAppKey: json['useCustomAppKey'] as bool,
      useCustomServer: json['useCustomServer'] as bool,
      imServer: json['imServer'] as String,
      imPort: json['imPort'] as int,
      restServer: json['restServer'] as String,
    );
  }
}
