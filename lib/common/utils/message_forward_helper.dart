import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import '../widgets/log_view.dart';

ChatType parseForwardChatType(String rawValue) {
  final value = rawValue.trim().toLowerCase();
  switch (value) {
    case '':
    case 'chat':
    case 'single':
    case 'user':
    case '单聊':
      return ChatType.Chat;
    case 'group':
    case 'groupchat':
    case '群聊':
    case '群组':
      return ChatType.GroupChat;
    case 'room':
    case 'chatroom':
    case '聊天室':
      return ChatType.ChatRoom;
    default:
      throw ArgumentError('未知转发类型: $rawValue');
  }
}

String forwardChatTypeHint() {
  return 'chat / group / room';
}

List<String> parseForwardMessageIds(String rawValue) {
  final ids = rawValue
      .split(RegExp(r'[,，\n]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList();
  if (ids.isEmpty) {
    throw ArgumentError('请输入要合并转发的消息 ID');
  }
  return ids;
}

List<String> successfulLocalMessageIdsForCombineForward({
  required Iterable<LogEntry> entries,
  required ChatType chatType,
  required String conversationId,
}) {
  final normalizedConversationId = conversationId.trim();
  final ids = <String>[];
  final seen = <String>{};
  for (final entry in entries) {
    final attachment = entry.attachment;
    if (entry.tag != 'message' || attachment is! EMMessage) {
      continue;
    }
    if (attachment.chatType != chatType ||
        attachment.conversationId != normalizedConversationId ||
        attachment.status != MessageStatus.SUCCESS ||
        attachment.msgId.isEmpty) {
      continue;
    }
    if (seen.add(attachment.msgId)) {
      ids.add(attachment.msgId);
    }
  }
  return ids;
}

EMMessage createForwardMessage({
  required EMMessage source,
  required String targetId,
  required ChatType chatType,
}) {
  final trimmedTargetId = targetId.trim();
  if (trimmedTargetId.isEmpty) {
    throw ArgumentError('请输入转发目标 ID');
  }
  final message = EMMessage.createSendMessage(
    to: trimmedTargetId,
    chatType: chatType,
    body: source.body,
  );
  final attributes = source.attributes;
  if (attributes != null) {
    message.attributes = Map<String, dynamic>.from(attributes);
  }
  return message;
}

EMMessage createCombineForwardMessage({
  required String targetId,
  required ChatType chatType,
  required List<String> msgIds,
  String? title,
  String? summary,
  String? compatibleText,
}) {
  final trimmedTargetId = targetId.trim();
  if (trimmedTargetId.isEmpty) {
    throw ArgumentError('请输入转发目标 ID');
  }
  if (msgIds.isEmpty) {
    throw ArgumentError('请输入要合并转发的消息 ID');
  }
  return EMMessage.createCombineSendMessage(
    targetId: trimmedTargetId,
    chatType: chatType,
    msgIds: msgIds,
    title: _nullIfBlank(title),
    summary: _nullIfBlank(summary),
    compatibleText: _nullIfBlank(compatibleText),
  );
}

String? _nullIfBlank(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
