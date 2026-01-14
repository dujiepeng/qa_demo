import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';

class ChatEventManager {
  static ChatEventManager? _instance;
  ChatEventManager._internal();

  factory ChatEventManager.getInstance() {
    _instance ??= ChatEventManager._internal();
    return _instance!;
  }

  void init() {
    debugPrint('ChatEventManager: Initializing listeners...');
    _addContactListener();
  }

  void _addContactListener() {
    EMClient.getInstance.contactManager.addEventHandler(
      'GLOBAL_CONTACT_HANDLER',
      EMContactEventHandler(
        onContactInvited: (userId, reason) {
          debugPrint(
            'ChatEventManager: Received contact invitation from $userId, reason: $reason',
          );
          // 后续可以增加全局弹窗或通知逻辑
        },
        onContactDeleted: (userId) {
          debugPrint('ChatEventManager: Contact deleted: $userId');
        },
        onContactAdded: (userId) {
          debugPrint('ChatEventManager: Contact added: $userId');
        },
        onFriendRequestAccepted: (userId) {
          debugPrint('ChatEventManager: Friend request accepted by $userId');
        },
        onFriendRequestDeclined: (userId) {
          debugPrint('ChatEventManager: Friend request declined by $userId');
        },
      ),
    );
    debugPrint('ChatEventManager: Contact event handler registered.');
  }

  void dispose() {
    EMClient.getInstance.contactManager.removeEventHandler(
      'GLOBAL_CONTACT_HANDLER',
    );
    debugPrint('ChatEventManager: Listeners disposed.');
  }
}
