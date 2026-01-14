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

  bool isDirty = false; // 用于标记配置是否发生变化，是否需要重新初始化 SDK

  // 持久化存储键名
  static const String _keyUseCustomAppKey = 'use_custom_app_key';
  static const String _keyAppKey = 'app_key';
  static const String _keyUseCustomServer = 'use_custom_server';
  static const String _keyImServer = 'im_server';
  static const String _keyImPort = 'im_port';
  static const String _keyRestServer = 'rest_server';

  // 从本地加载存储的配置
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    useCustomAppKey = prefs.getBool(_keyUseCustomAppKey) ?? false;
    appKey = prefs.getString(_keyAppKey) ?? 'easemob#dutest';
    useCustomServer = prefs.getBool(_keyUseCustomServer) ?? false;
    imServer = prefs.getString(_keyImServer) ?? '';
    imPort = prefs.getInt(_keyImPort) ?? 6717;
    restServer = prefs.getString(_keyRestServer) ?? '';
    // 加载完成后，主动标记一次 dirty，确保下次登录（或启动）时使用加载的内容进行初始化
    isDirty = true;
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
    isDirty = true;
  }

  // 检查传入的配置是否与当前内存中的一致
  bool hasChanged({
    required bool newUseCustomAppKey,
    required String newAppKey,
    required bool newUseCustomServer,
    required String newImServer,
    required int newImPort,
    required String newRestServer,
  }) {
    return newUseCustomAppKey != useCustomAppKey ||
        newAppKey != appKey ||
        newUseCustomServer != useCustomServer ||
        newImServer != imServer ||
        newImPort != imPort ||
        newRestServer != restServer;
  }
}
