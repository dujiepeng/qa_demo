import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:provider/provider.dart';
import '../common/mixins/login_logic_mixin.dart';
import '../common/utils/connection_status_overlay_controller.dart';
import '../common/utils/offline_message_counter.dart';
import '../common/utils/other_logged_in_devices_controller.dart';
import '../common/utils/version_manager.dart';
import '../common/widgets/update_dialog.dart';
import 'single/contact_api.dart';
import '../common/widgets/responsive_layout.dart';
import '../mobile/home_page_mobile.dart';
import '../pad/home_page_pad.dart';
import '../theme/app_settings.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _connectionHandlerId = 'home_page_connection_status_overlay';
  static const _offlineMessageHandlerId = 'home_page_offline_message_counter';
  bool _connectionHandlerAttached = false;
  bool _offlineMessageHandlerAttached = false;

  @override
  void initState() {
    super.initState();
    VersionManager().addListener(_checkAndShowUpdateDialog);
    // 冷启动时，已登录状态会直接跳到 /home，跳过登录页的 SDK 初始化流程。
    // 此处补一次 ensureSdkInit，确保 SDK 在任何情况下都被正确初始化。
    // 若 isInit 已为 true（正常登录流程进入），则此调用为空操作，不影响性能。
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final settings = context.read<AppSettings>();
      await ensureSdkInit(settings);
      if (!mounted) return;
      _attachConnectionStatusHandler();
      _attachOfflineMessageCounter();
    });
  }

  @override
  void dispose() {
    if (_connectionHandlerAttached) {
      EMClient.getInstance.removeConnectionEventHandler(_connectionHandlerId);
    }
    if (_offlineMessageHandlerAttached) {
      EMClient.getInstance.chatManager.removeEventHandler(
        _offlineMessageHandlerId,
      );
    }
    VersionManager().removeListener(_checkAndShowUpdateDialog);
    super.dispose();
  }

  void _attachOfflineMessageCounter() {
    if (_offlineMessageHandlerAttached) {
      return;
    }
    final counter = context.read<OfflineMessageCounter>();
    EMClient.getInstance.chatManager.addEventHandler(
      _offlineMessageHandlerId,
      EMChatEventHandler(
        onMessagesReceived: (messages) {
          debugPrint('onMessagesReceived: ${messages.length}');
          counter.recordMessages(messages);
        },
      ),
    );
    _offlineMessageHandlerAttached = true;
  }

  void _attachConnectionStatusHandler() {
    if (_connectionHandlerAttached) {
      return;
    }
    final overlayController = context.read<ConnectionStatusOverlayController>();
    final otherDevicesController = context
        .read<OtherLoggedInDevicesController>();
    final settings = context.read<AppSettings>();
    EMClient.getInstance.addConnectionEventHandler(
      _connectionHandlerId,
      EMConnectionEventHandler(
        onConnected: () {
          overlayController.showMessage('连接状态：已连接');
        },
        onDisconnected: () {
          overlayController.showMessage('连接状态：已断开');
        },
        onUserDidLoginFromOtherDevice: (info) {
          final deviceName = info.deviceName.trim();
          otherDevicesController.recordDeviceLogin(deviceName);
          final userId = settings.lastLoginUserId.trim();
          final password = settings.lastLoginPassword.trim();
          if (userId.isNotEmpty && password.isNotEmpty) {
            otherDevicesController.refreshFromServer(
              loadDevices: () =>
                  fetchLoggedInDevices(userId: userId, password: password),
            );
          }
          overlayController.showMessage('连接状态：当前账号在其他设备登录 ($deviceName)');
        },
        onUserDidRemoveFromServer: () {
          overlayController.showMessage('连接状态：账号已被服务器移除');
        },
        onUserDidForbidByServer: () {
          overlayController.showMessage('连接状态：账号已被服务器禁止连接');
        },
        onUserKickedByOtherDevice: () {
          overlayController.showMessage('连接状态：当前账号被其他设备踢下线');
        },
        onTokenWillExpire: () {
          overlayController.showMessage('连接状态：Token 即将过期');
        },
        onTokenDidExpire: () {
          overlayController.showMessage('连接状态：Token 已过期');
        },
        onAppActiveNumberReachLimit: () {
          overlayController.showMessage('连接状态：应用活跃用户数已达上限');
        },
        onOfflineMessageSyncStart: () {
          overlayController.showMessage('连接状态：开始同步离线消息');
        },
        onOfflineMessageSyncFinish: () {
          overlayController.showMessage('连接状态：离线消息同步完成');
        },
      ),
    );
    _connectionHandlerAttached = true;
  }

  bool _hasShownUpdateDialog = false;

  void _checkAndShowUpdateDialog() {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    final source = VersionManager().lastCheckSource;
    final isAutomaticCheck =
        source == VersionCheckSource.startupSilent ||
        source == VersionCheckSource.loginSilent;

    if (route?.isCurrent != true) return;
    if (!isAutomaticCheck) return;

    if (VersionManager().hasNewVersion && !_hasShownUpdateDialog) {
      _hasShownUpdateDialog = true;
      UpdateDialog.show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: HomePageMobile(),
      tablet: HomePagePad(),
    );
  }
}
