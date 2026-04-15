import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_flutter/common/widgets/log_view.dart';
import 'package:qa_flutter/common/widgets/log_view_actions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    String? clipboardText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardText = (call.arguments as Map)['text'] as String?;
            return null;
          }
          if (call.method == 'Clipboard.getData') {
            return <String, dynamic>{'text': clipboardText};
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test(
    'copy action copies full log line without returning overlay label',
    () async {
      final entry = LogEntry(content: 'hello', timestamp: '(123) 10:00:00.000');

      final result = await LogViewActions.copyEntry().onSelected(entry);
      final clipboard = await Clipboard.getData(Clipboard.kTextPlain);

      expect(result, isNull);
      expect(clipboard?.text, '(123) 10:00:00.000: hello');
    },
  );
}
