import 'package:flutter/services.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';

const _conversationChannel = MethodChannel(
  'com.chat.im/chat_conversation',
  JSONMethodCodec(),
);

Future<void> deleteConversationServerMessagesByTime(
  EMConversation conversation, {
  required int beforeMs,
}) async {
  final result = await _conversationChannel.invokeMapMethod<String, dynamic>(
    'conversationDeleteServerMessageWithTime',
    {
      'convId': conversation.id,
      'type': conversation.type.index,
      'isThread': conversation.isChatThread,
      'beforeTs': beforeMs,
    },
  );
  EMError.hasErrorFromResult(result ?? const <String, dynamic>{});
}
