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
  // 好友申请列表 (存储 userId 和 reason 的 Map)
  final List<Map<String, String>> friendInvitations = [];

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
          // 记录详细申请信息
          friendInvitations.add({
            'userId': userId,
            'reason': reason ?? '',
            'time': DateTime.now().toString(),
          });
          // 更新好友申请计数，通知外部更新
          friendRequestCount.value = friendInvitations.length;
        },
        onContactDeleted: (userId) {
          debugPrint('ChatEventManager: Contact deleted: $userId');
        },
        onContactAdded: (userId) {
          debugPrint('ChatEventManager: Contact added: $userId');
          _removeInvitation(userId);
        },
        onFriendRequestAccepted: (userId) {
          debugPrint('ChatEventManager: Friend request accepted by $userId');
          _removeInvitation(userId);
        },
        onFriendRequestDeclined: (userId) {
          debugPrint('ChatEventManager: Friend request declined by $userId');
          _removeInvitation(userId);
        },
      ),
    );
    debugPrint('ChatEventManager: Contact event handler registered.');
  }

  // 移除特定用户的好友申请记录
  void _removeInvitation(String userId) {
    if (friendInvitations.any((inv) => inv['userId'] == userId)) {
      friendInvitations.removeWhere((inv) => inv['userId'] == userId);
      // 同步更新计数器
      friendRequestCount.value = friendInvitations.length;
      debugPrint('ChatEventManager: Removed invitation record for $userId');
    }
  }

  void dispose() {
    EMClient.getInstance.contactManager.removeEventHandler(
      'GLOBAL_CONTACT_HANDLER',
    );
    debugPrint('ChatEventManager: Listeners disposed.');
  }
}
