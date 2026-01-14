import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static final AppSettings _instance = AppSettings._internal();
  factory AppSettings() => _instance;
  AppSettings._internal();

  bool useCustomAppKey = false;
  String appKey = 'easemob#dutest';

  bool useCustomServer = false;
  String imServer = '';
  int imPort = 6717;
  String restServer = '';

  bool isDarkMode = true; // 默认开启深色模式

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

  // 从本地加载存储的配置
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    useCustomAppKey = prefs.getBool(_keyUseCustomAppKey) ?? false;
    appKey = prefs.getString(_keyAppKey) ?? 'easemob#dutest';
    useCustomServer = prefs.getBool(_keyUseCustomServer) ?? false;
    imServer = prefs.getString(_keyImServer) ?? '';
    imPort = prefs.getInt(_keyImPort) ?? 6717;
    restServer = prefs.getString(_keyRestServer) ?? '';
    isDarkMode = prefs.getBool(_keyIsDarkMode) ?? true;

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
    await prefs.setBool(_keyIsDarkMode, isDarkMode);

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
}
