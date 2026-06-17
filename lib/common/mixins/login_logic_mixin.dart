import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';

import '../../theme/app_settings.dart';
import '../../theme/app_colors.dart';

/// 确保 SDK 已初始化的全局工具函数。
/// 可以被 LoginLogicMixin 和 HomePage 共同调用。
/// 如果 SDK 已经初始化（isInit=true），则什么都不做直接返回。
Future<void> ensureSdkInit(AppSettings settings) async {
  // 如果已经初始化过，直接跳过，避免重复 init
  if (settings.isInit) return;

  // 根据当前配置构建 EMOptions
  EMOptions options;
  if (settings.activeEnvName != 'ebs') {
    // 非 ebs 的开发/私有集群，在构造时直接传入详细信息
    final isWs = !settings.isMsync;
    final activeConf = settings.activeConfig;

    final serverHost = isWs
        ? (activeConf?.wsServer ?? settings.imServer)
        : (activeConf?.msyncServer ?? settings.imServer);
    final serverPort = isWs
        ? (activeConf?.wsPort ?? settings.imPort)
        : (activeConf?.msyncPort ?? settings.imPort);
    final enableTls = activeConf?.enableTls ?? true;
    final webSocketServer = isWs
        ? _joinWebSocketServerAndPath(serverHost, activeConf?.wsPath ?? '')
        : serverHost;

    if (isWs) {
      options = EMOptions.withAppKey(
        settings.appKey,
        autoLogin: false,
        debugMode: true,
        restServer: settings.restServer,
        enableDNSConfig: false,
        usingHttpsOnly: false,
        webSocketPort: serverPort,
        webSocketServer: webSocketServer,
        enableTLS: enableTls,
        requireDeliveryAck: true,
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
        requireDeliveryAck: true,
      );
    }

    debugPrint(
      'ensureSdkInit: Initializing with CUSTOM server (${settings.activeEnvName}): ${isWs ? webSocketServer : serverHost}:$serverPort, Mode: ${isWs ? 'WebSocket' : 'TCP'}',
    );
  } else {
    // ebs 公有云环境，只传 AppKey
    options = EMOptions.withAppKey(
      settings.appKey,
      autoLogin: false,
      debugMode: true,
      requireDeliveryAck: true,
    );
    debugPrint('ensureSdkInit: Initializing with ONLINE (ebs) environment');
  }

  await EMClient.getInstance.init(options);
  // 标记初始化完成，通知依赖此状态的 Widget 刷新
  settings.isInit = true;
  settings.isDirty = false;
  debugPrint('ensureSdkInit: SDK Initialized with AppKey: ${settings.appKey}');
}

String _joinWebSocketServerAndPath(String server, String path) {
  final trimmedServer = server.trim();
  final trimmedPath = path.trim();
  if (trimmedPath.isEmpty) {
    return trimmedServer;
  }
  final normalizedPath = trimmedPath.startsWith('/')
      ? trimmedPath
      : '/$trimmedPath';
  return '${trimmedServer.replaceFirst(RegExp(r'/+$'), '')}$normalizedPath';
}

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
      // 确保 SDK 已初始化。
      // 复用 ensureSdkInit 工具函数，避免重复的初始化逻辑。
      await ensureSdkInit(settings);

      try {
        await EMClient.getInstance.logout();
      } catch (_) {}
      await EMClient.getInstance.loginWithPassword(uid, pwd);

      // 登录成功，更新系统状态
      settings.isLoggedIn = true;
      settings.lastLoginUserId = uid;
      settings.lastLoginPassword = pwd;
      await settings.saveSettings();

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
