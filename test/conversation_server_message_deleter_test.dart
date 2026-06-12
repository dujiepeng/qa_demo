import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/common/utils/conversation_server_message_deleter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(
    'com.chat.im/chat_conversation',
    JSONMethodCodec(),
  );

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('delete by time passes conversation params to native sdk', () async {
    MethodCall? nativeCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          nativeCall = call;
          return <String, dynamic>{};
        });

    await deleteConversationServerMessagesByTime(
      EMConversation.fromJson({
        'convId': 'alice',
        'type': EMConversationType.Chat.index,
        'isThread': false,
      }),
      beforeMs: 3600000,
    );

    expect(nativeCall, isNotNull);
    expect(nativeCall!.method, 'conversationDeleteServerMessageWithTime');
    expect(nativeCall!.arguments, {
      'convId': 'alice',
      'type': EMConversationType.Chat.index,
      'isThread': false,
      'beforeTs': 3600000,
    });
  });
}
