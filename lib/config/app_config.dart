import 'package:package_info_plus/package_info_plus.dart';

/// 应用配置类
/// 使用 package_info_plus 动态读取 pubspec.yaml 中的版本号
class AppConfig {
  static PackageInfo? _packageInfo;

  /// 初始化应用配置
  /// 需要在 main() 函数中调用
  static Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  /// 获取应用版本号 (格式: major.minor.patch+buildNumber)
  /// 例如: "1.35.0+101"
  static String get appVersion {
    if (_packageInfo == null) {
      throw StateError('AppConfig 未初始化,请在 main() 函数中调用 AppConfig.init()');
    }
    return '${_packageInfo!.version}+${_packageInfo!.buildNumber}';
  }

  /// 获取应用名称
  static String get appName => _packageInfo?.appName ?? '';

  /// 获取包名
  static String get packageName => _packageInfo?.packageName ?? '';

  /// 获取构建号
  static String get buildNumber => _packageInfo?.buildNumber ?? '';

  /// 获取版本号 (不含构建号)
  static String get version => _packageInfo?.version ?? '';
}
