import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import '../../theme/app_settings.dart';

/// 通用信息弹窗工具类。
/// 调用 [InfoDialog.show] 以异步获取当前用户信息和服务器配置，并展示弹窗。
/// 所有需要展示「信息」按钮的测试页面均可复用此工具。
class InfoDialog {
  InfoDialog._(); // 工具类，禁止实例化

  /// 异步拉取用户信息和服务器配置，然后在给定 [context] 上展示信息弹窗。
  /// [settings] 用于读取当前服务器配置信息。
  static Future<void> show(
    BuildContext context,
    AppSettings settings,
  ) async {
    // 1. 异步获取 IM 用户数据
    final currentUser = await EMClient.getInstance.getCurrentUserId();
    final deviceId = await EMClient.getInstance.getCurrentDeviceId();

    // 2. 从 AppSettings 读取服务器配置
    final env = settings.activeEnvName;
    final appKey = settings.appKey;
    final rest = settings.restServer;
    final activeConf = settings.activeConfig;
    final isMsync = settings.isMsync;
    // 根据连接方式选择对应的服务器地址和端口
    final serverHost = isMsync
        ? (activeConf?.msyncServer ?? settings.imServer)
        : (activeConf?.wsServer ?? settings.imServer);
    final serverPort = isMsync
        ? (activeConf?.msyncPort ?? settings.imPort)
        : (activeConf?.wsPort ?? settings.imPort);
    final connMode = isMsync ? 'TCP (MSYNC)' : 'WebSocket';

    // 3. 检查 context 是否仍有效（防止页面已销毁）
    if (!context.mounted) return;

    // 4. 展示弹窗
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户信息区
            const Text(
              '用户信息',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('当前用户: $currentUser'),
            const SizedBox(height: 4),
            Text('设备ID: $deviceId'),
            const Divider(height: 20),
            // 服务器配置区
            const Text(
              '服务器配置',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('集群环境: $env'),
            const SizedBox(height: 4),
            Text('AppKey: $appKey'),
            const SizedBox(height: 4),
            Text('REST: $rest'),
            const SizedBox(height: 4),
            Text('IM 服务器: $serverHost:$serverPort'),
            const SizedBox(height: 4),
            Text('连接方式: $connMode'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
