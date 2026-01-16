import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';

class ChatEventManager extends StatefulWidget {
  final Widget child;
  const ChatEventManager({super.key, required this.child});

  @override
  State<ChatEventManager> createState() => _ChatEventManagerState();
}

class _ChatEventManagerState extends State<ChatEventManager> {
  final String _eventKey = 'GLOBAL_EVENT_MANAGER';

  @override
  void initState() {
    super.initState();
    _addListeners();
  }

  @override
  void dispose() {
    EMClient.getInstance.removeConnectionEventHandler(_eventKey);
    super.dispose();
  }

  void _addListeners() {
    EMClient.getInstance.addConnectionEventHandler(
      _eventKey,
      EMConnectionEventHandler(
        onConnected: () {
          debugPrint('ChatEventManager: Connected');
        },
        onDisconnected: () {
          debugPrint('ChatEventManager: Disconnected');
        },
        onUserDidLoginFromOtherDevice: (deviceName) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('当前账号在其他设备登录: $deviceName')));
          }
        },
        onTokenWillExpire: () {
          debugPrint('ChatEventManager: Token will expire');
        },
        onTokenDidExpire: () {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Token 已过期，请重新登录')));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
