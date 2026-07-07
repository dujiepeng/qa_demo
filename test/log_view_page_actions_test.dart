import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:qa_flutter/common/utils/log_file_helper.dart';
import 'package:qa_flutter/common/widgets/log_view.dart';
import 'package:qa_flutter/common/widgets/log_view_actions.dart';
import 'package:qa_flutter/common/log_content_page.dart';

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

  testWidgets('log content page can copy log path', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LogContentPage(logPath: '/tmp/test.log'),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('复制日志路径'));
    await tester.pump();

    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    expect(clipboard?.text, '/tmp/test.log');
  });

  testWidgets('log content page can export and copy adb command', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LogContentPage(
          logPath: '/tmp/test.log',
          exportLogFile: (_) async => const LogFileExportResult(
            status: LogFileExportStatus.exported,
            exportPath: '/sdcard/Android/data/com.example.qa_flutter/files/qa_flutter_logs/test.log',
            message: '导出完成',
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('导出完整日志'));
    await tester.pump();

    expect(find.textContaining('导出路径:'), findsOneWidget);
    expect(find.textContaining('分享文本已复制'), findsOneWidget);

    var clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    expect(
      clipboard?.text,
      r'adb -s emulator-5556 pull "/sdcard/Android/data/com.example.qa_flutter/files/qa_flutter_logs/test.log" "$HOME/Downloads/"',
    );

    await tester.tap(find.byTooltip('复制 adb pull 命令'));
    await tester.pump();

    clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    expect(
      clipboard?.text,
      r'adb -s emulator-5556 pull "/sdcard/Android/data/com.example.qa_flutter/files/qa_flutter_logs/test.log" "$HOME/Downloads/"',
    );
  });

}
