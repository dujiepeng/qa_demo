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
}
