import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';

class ChatEventManager {
  static ChatEventManager? _instance;
  ChatEventManager._internal();

  factory ChatEventManager.getInstance() {
    _instance ??= ChatEventManager._internal();
    return _instance!;
  }

  // 好友申请数量通知器
  final ValueNotifier<int> friendRequestCount = ValueNotifier<int>(0);

  void init() {
    debugPrint('ChatEventManager: Initializing listeners...');
    _addContactListener();
    EMClient.getInstance.startCallback();
  }

  void _addContactListener() {
    EMClient.getInstance.contactManager.addEventHandler(
      'GLOBAL_CONTACT_HANDLER',
      EMContactEventHandler(
        onContactInvited: (userId, reason) {
          debugPrint(
            'ChatEventManager: Received contact invitation from $userId, reason: $reason',
          );
          // 增加好友申请计数，通知外部更新
          friendRequestCount.value++;
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
