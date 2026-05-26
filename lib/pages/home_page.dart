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
  static const _contactHandlerId = 'home_page_contact_events';
  bool _connectionHandlerAttached = false;
  bool _offlineMessageHandlerAttached = false;
  bool _contactHandlerAttached = false;

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
      _attachContactEventHandler();
      await EMClient.getInstance.startCallback();
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
    if (_contactHandlerAttached) {
      EMClient.getInstance.contactManager.removeEventHandler(_contactHandlerId);
    }
    VersionManager().removeListener(_checkAndShowUpdateDialog);
    super.dispose();
  }

  void _attachContactEventHandler() {
    if (_contactHandlerAttached) {
      return;
    }
    final overlayController = context.read<ConnectionStatusOverlayController>();
    EMClient.getInstance.contactManager.addEventHandler(
      _contactHandlerId,
      EMContactEventHandler(
        onContactInvited: (userId, reason) {
          final reasonText = reason?.trim();
          final suffix = reasonText == null || reasonText.isEmpty
              ? ''
              : ' ($reasonText)';
          overlayController.showMessage('收到好友申请: $userId$suffix');
        },
        onFriendRequestAccepted: (userId) {
          overlayController.showMessage('好友申请已被接受: $userId');
        },
        onFriendRequestDeclined: (userId) {
          overlayController.showMessage('好友申请已被拒绝: $userId');
        },
        onContactAdded: (userId) {
          overlayController.showMessage('好友已添加: $userId');
        },
        onContactDeleted: (userId) {
          overlayController.showMessage('好友已删除: $userId');
        },
      ),
    );
    _contactHandlerAttached = true;
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
    Future<void> refreshConnectionLight() {
      return overlayController.refreshConnectionLight(
        () => EMClient.getInstance.isConnected(),
      );
    }
    EMClient.getInstance.addConnectionEventHandler(
      _connectionHandlerId,
      EMConnectionEventHandler(
        onConnected: () {
          overlayController.showMessage('连接状态：已连接');
          refreshConnectionLight();
        },
        onDisconnected: () {
          overlayController.showMessage('连接状态：已断开');
          refreshConnectionLight();
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
          refreshConnectionLight();
        },
        onUserDidRemoveFromServer: () {
          overlayController.showMessage('连接状态：账号已被服务器移除');
          refreshConnectionLight();
        },
        onUserDidForbidByServer: () {
          overlayController.showMessage('连接状态：账号已被服务器禁止连接');
          refreshConnectionLight();
        },
        onUserDidChangePassword: () {
          overlayController.showMessage('连接状态：密码已变更');
          refreshConnectionLight();
        },
        onUserDidLoginTooManyDevice: () {
          overlayController.showMessage('连接状态：登录设备数超限');
          refreshConnectionLight();
        },
        onUserKickedByOtherDevice: () {
          overlayController.showMessage('连接状态：当前账号被其他设备踢下线');
          refreshConnectionLight();
        },
        onUserAuthenticationFailed: () {
          overlayController.showMessage('连接状态：鉴权失败');
          refreshConnectionLight();
        },
        onTokenWillExpire: () {
          overlayController.showMessage('连接状态：Token 即将过期');
          refreshConnectionLight();
        },
        onTokenDidExpire: () {
          overlayController.showMessage('连接状态：Token 已过期');
          refreshConnectionLight();
        },
        onAppActiveNumberReachLimit: () {
          overlayController.showMessage('连接状态：应用活跃用户数已达上限');
          refreshConnectionLight();
        },
        onOfflineMessageSyncStart: () {
          overlayController.showMessage('连接状态：开始同步离线消息');
          refreshConnectionLight();
        },
        onOfflineMessageSyncFinish: () {
          overlayController.showMessage('连接状态：离线消息同步完成');
          refreshConnectionLight();
        },
      ),
    );
    refreshConnectionLight();
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
