import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';

import '../../theme/app_settings.dart';
import '../../theme/app_colors.dart';

/// 提取出的公用登录逻辑，供 Mobile 和 Pad 的 LoginPage 使用
mixin LoginLogicMixin<T extends StatefulWidget> on State<T> {
  final TextEditingController uidController = TextEditingController();
  final TextEditingController pwdController = TextEditingController();
  bool isLoading = false;
  final settings = AppSettings();

  @override
  void dispose() {
    uidController.dispose();
    pwdController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    final uid = uidController.text.trim();
    final pwd = pwdController.text.trim();

    if (uid.isEmpty || pwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter UID and Password',
            style: TextStyle(color: AppColors.textPrimary(settings.isDarkMode)),
          ),
          backgroundColor: AppColors.primary(settings.isDarkMode),
        ),
      );
      return;
    }

    setState(() => isLoading = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      // 使用设置中的服务器配置进行初始化
      if (settings.isDirty) {
        EMOptions options;
        if (settings.activeEnvName != 'ebs') {
          // 非ebs的开发/私有集群，在构造时直接传入详细信息

          final isWs = !settings.isMsync;
          final activeConf = settings.activeConfig;

          final serverHost = isWs
              ? (activeConf?.wsServer ?? settings.imServer)
              : (activeConf?.msyncServer ?? settings.imServer);
          final serverPort = isWs
              ? (activeConf?.wsPort ?? settings.imPort)
              : (activeConf?.msyncPort ?? settings.imPort);

          if (isWs) {
            options = EMOptions.withAppKey(
              settings.appKey,
              autoLogin: false,
              debugMode: true,
              restServer: settings.restServer,
              enableDNSConfig: false,
              usingHttpsOnly: false,
              webSocketPort: serverPort,
              webSocketServer: serverHost,
              enableTLS: true,
            );
          } else {
            options = EMOptions.withAppKey(
              settings.appKey,
              autoLogin: false,
              debugMode: true,
              imServer: serverHost,
              imPort: serverPort,
              restServer: settings.restServer,
              enableDNSConfig: false,
              usingHttpsOnly: false,
              enableTLS: false,
            );
          }

          debugPrint(
            'LoginLogicMixin: Initializing with CUSTOM server (${settings.activeEnvName}): $serverHost:$serverPort, Mode: ${isWs ? 'WebSocket' : 'TCP'}',
          );
        } else {
          // ebs环境配置
          options = EMOptions.withAppKey(
            settings.appKey,
            autoLogin: false,
            debugMode: true,
          );
          debugPrint('LoginLogicMixin: Initializing with ONLINE environment');
        }

        await EMClient.getInstance.init(options);
        settings.isDirty = false;
        debugPrint(
          'LoginLogicMixin: SDK Initialized with AppKey: ${settings.appKey}',
        );
      }

      await EMClient.getInstance.logout();
      await EMClient.getInstance.loginWithPassword(uid, pwd);

      if (!mounted) return;
      navigator.pushReplacementNamed('/home');
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Login Failed: $e',
            style: TextStyle(color: AppColors.textPrimary(settings.isDarkMode)),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
}
