import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qa_flutter/common/utils/log_file_helper.dart';
import 'package:qa_flutter/common/utils/log_panel_sync.dart';
import 'package:qa_flutter/common/utils/app_route_observer.dart';
import 'package:qa_flutter/common/widgets/log_panel/log_panel.dart';
import 'package:qa_flutter/common/widgets/layout/mobile_log_overlay.dart';
import 'package:qa_flutter/theme/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings();
    await settings.setLogOverlayMinimized(true);
    await settings.updateLogBubblePlacement(
      onRightSide: true,
      verticalRatio: 0.7,
    );
    settings.isLoggedIn = false;
    settings.isInit = false;
  });

  testWidgets('mobile overlay respects minimized state from settings', (
    tester,
  ) async {
    final settings = AppSettings()
      ..isLoggedIn = true
      ..isInit = false;
    await settings.setLogOverlayMinimized(true);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(390, 844)),
            child: MobileLogOverlay(
              child: Scaffold(body: Center(child: Text('content'))),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.bug_report_outlined), findsOneWidget);
    expect(find.byIcon(Icons.minimize), findsNothing);
  });

  testWidgets('mobile overlay defaults to minimized bubble on fresh settings', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings()
      ..isLoggedIn = true
      ..isInit = false;
    await settings.loadSettings();
    settings.isLoggedIn = true;
    settings.isInit = false;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(390, 844)),
            child: MobileLogOverlay(
              child: Scaffold(body: Center(child: Text('content'))),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.bug_report_outlined), findsOneWidget);
    expect(find.byIcon(Icons.minimize), findsNothing);
  });

  testWidgets('mobile overlay can minimize into bubble and restore', (
    tester,
  ) async {
    final settings = AppSettings()
      ..isLoggedIn = true
      ..isInit = false;
    await settings.setLogOverlayMinimized(false);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(390, 844)),
            child: MobileLogOverlay(
              child: Scaffold(body: Center(child: Text('content'))),
            ),
          ),
        ),
      ),
    );

    expect(find.text('最小化'), findsOneWidget);

    await tester.tap(find.text('最小化'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.bug_report_outlined), findsOneWidget);
    expect(find.text('日志'), findsNothing);

    await tester.tap(find.byIcon(Icons.bug_report_outlined));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.bug_report_outlined), findsNothing);
    expect(find.text('最小化'), findsOneWidget);
  });

  testWidgets('mobile overlay forces minimized on first build', (tester) async {
    final settings = AppSettings()
      ..isLoggedIn = true
      ..isInit = false;
    await settings.setLogOverlayMinimized(false);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(390, 844)),
            child: MobileLogOverlay(
              child: Scaffold(body: Center(child: Text('content'))),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.bug_report_outlined), findsOneWidget);
    expect(find.text('最小化'), findsNothing);
    expect(settings.isLogOverlayMinimized, isTrue);
  });

  testWidgets('mobile overlay minimizes when app goes to background', (
    tester,
  ) async {
    final settings = AppSettings()
      ..isLoggedIn = true
      ..isInit = false;
    await settings.setLogOverlayMinimized(false);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(390, 844)),
            child: MobileLogOverlay(
              child: Scaffold(body: Center(child: Text('content'))),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('最小化'), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.bug_report_outlined), findsOneWidget);
    expect(find.text('最小化'), findsNothing);
    expect(settings.isLogOverlayMinimized, isTrue);
  });

  testWidgets('mobile overlay minimizes when route changes away', (
    tester,
  ) async {
    final settings = AppSettings()
      ..isLoggedIn = true
      ..isInit = false;
    await settings.setLogOverlayMinimized(true);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: MaterialApp(
          navigatorObservers: [appRouteObserver],
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: MobileLogOverlay(
              child: Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(tester.element(find.text('next'))).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const Scaffold(body: Center(child: Text('second'))),
                        ),
                      );
                    },
                    child: const Text('next'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.bug_report_outlined));
    await tester.pumpAndSettle();
    expect(find.text('最小化'), findsOneWidget);

    await tester.tap(find.text('next'));
    await tester.pumpAndSettle();

    expect(find.text('second'), findsOneWidget);
    expect(settings.isLogOverlayMinimized, isTrue);
  });

  testWidgets(
    'mobile overlay does not overflow when resized to minimum height',
    (tester) async {
      final settings = AppSettings()
        ..isLoggedIn = true
        ..isInit = true;
      await settings.setLogOverlayMinimized(false);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: settings,
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: Size(390, 280)),
              child: MobileLogOverlay(
                child: Scaffold(body: Center(child: Text('content'))),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.bug_report_outlined));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byType(GestureDetector).first,
        const Offset(0, 400),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'mobile overlay does not overflow with search and filter expanded at minimum height',
    (tester) async {
      final settings = AppSettings()
        ..isLoggedIn = true
        ..isInit = true;
      await settings.setLogOverlayMinimized(false);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: settings,
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: Size(390, 280)),
              child: MobileLogOverlay(
                child: Scaffold(body: Center(child: Text('content'))),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.bug_report_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.filter_alt_outlined));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(GestureDetector).first,
        const Offset(0, 400),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('mobile overlay minimized bubble can be dragged', (tester) async {
    final settings = AppSettings()
      ..isLoggedIn = true
      ..isInit = false;
    await settings.setLogOverlayMinimized(true);
    await settings.updateLogBubblePlacement(
      onRightSide: true,
      verticalRatio: 0.2,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(390, 844)),
            child: MobileLogOverlay(
              child: Scaffold(body: Center(child: Text('content'))),
            ),
          ),
        ),
      ),
    );

    final bubbleFinder = find.byIcon(Icons.bug_report_outlined);
    final before = tester.getTopLeft(bubbleFinder);

    await tester.drag(bubbleFinder, const Offset(-120, 180));
    await tester.pumpAndSettle();

    final after = tester.getTopLeft(bubbleFinder);
    expect(after.dy, greaterThan(before.dy));
    expect(settings.logBubbleVerticalRatio, greaterThan(0.2));
  });

  testWidgets('log panel filters visible lines by keyword', (tester) async {
    var content = 'alpha line\nbeta target\ncharlie target';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: LogPanel(
              isDark: true,
              prepareLogFile: () async => const LogFileOpenResult(
                status: LogFileOpenStatus.ready,
                logPath: '/tmp/mock.log',
              ),
              readLogState: (logPath, {previous, maxRetainedCharacters = 120000}) async {
                return LogPanelFileState(
                  content: content,
                  fileLength: content.length,
                  unchangedCount: 0,
                  nextPollInterval: const Duration(seconds: 1),
                );
              },
              enableFallbackPolling: false,
              logUpdateStreamFactory: (_) => const Stream<Object?>.empty(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.filter_alt_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'target');
    await tester.pumpAndSettle();

    expect(find.textContaining('beta target'), findsOneWidget);
    expect(find.textContaining('charlie target'), findsOneWidget);
    expect(find.textContaining('alpha line'), findsNothing);
  });

  testWidgets('log panel updates filtered results when new matching logs arrive', (
    tester,
  ) async {
    final controller = StreamController<Object?>();
    var content = 'alpha line';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: LogPanel(
              isDark: true,
              prepareLogFile: () async => const LogFileOpenResult(
                status: LogFileOpenStatus.ready,
                logPath: '/tmp/mock.log',
              ),
              readLogState: (logPath, {previous, maxRetainedCharacters = 120000}) async {
                return LogPanelFileState(
                  content: content,
                  fileLength: content.length,
                  unchangedCount: 0,
                  nextPollInterval: const Duration(seconds: 1),
                );
              },
              enableFallbackPolling: false,
              logUpdateStreamFactory: (_) => controller.stream,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.filter_alt_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'target');
    await tester.pumpAndSettle();

    expect(find.text('无匹配日志'), findsOneWidget);

    content = 'alpha line\nnew target line';
    controller.add(null);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.textContaining('new target line'), findsOneWidget);
    expect(find.text('无匹配日志'), findsNothing);

    await controller.close();
  });

  testWidgets('log panel copies filtered visible content', (tester) async {
    const content = 'alpha line\nbeta target\ncharlie target';
    String? copiedText;
    final messenger = TestDefaultBinaryMessengerBinding
        .instance
        .defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copiedText = (call.arguments as Map)['text'] as String?;
      }
      if (call.method == 'Clipboard.getData') {
        return <String, dynamic>{'text': copiedText};
      }
      return null;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: LogPanel(
              isDark: true,
              prepareLogFile: () async => const LogFileOpenResult(
                status: LogFileOpenStatus.ready,
                logPath: '/tmp/mock.log',
              ),
              readLogState: (logPath, {previous, maxRetainedCharacters = 120000}) async {
                return const LogPanelFileState(
                  content: content,
                  fileLength: content.length,
                  unchangedCount: 0,
                  nextPollInterval: Duration(seconds: 1),
                );
              },
              enableFallbackPolling: false,
              logUpdateStreamFactory: (_) => const Stream<Object?>.empty(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.filter_alt_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'target');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.copy_all));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(copiedText, 'beta target\ncharlie target');

    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('log panel search shows match count and navigates results', (
    tester,
  ) async {
    const content = 'alpha\nbeta target\ngamma\ndelta target';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: LogPanel(
              isDark: true,
              prepareLogFile: () async => const LogFileOpenResult(
                status: LogFileOpenStatus.ready,
                logPath: '/tmp/mock.log',
              ),
              readLogState: (logPath, {previous, maxRetainedCharacters = 120000}) async {
                return const LogPanelFileState(
                  content: content,
                  fileLength: content.length,
                  unchangedCount: 0,
                  nextPollInterval: Duration(seconds: 1),
                );
              },
              enableFallbackPolling: false,
              logUpdateStreamFactory: (_) => const Stream<Object?>.empty(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.search_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'target');
    await tester.pumpAndSettle();

    expect(find.text('1/2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
    await tester.pumpAndSettle();
    expect(find.text('2/2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_up));
    await tester.pumpAndSettle();
    expect(find.text('1/2'), findsOneWidget);
  });

  testWidgets('log panel search updates when new matching logs arrive', (
    tester,
  ) async {
    final controller = StreamController<Object?>();
    var content = 'alpha\nbeta';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: LogPanel(
              isDark: true,
              prepareLogFile: () async => const LogFileOpenResult(
                status: LogFileOpenStatus.ready,
                logPath: '/tmp/mock.log',
              ),
              readLogState: (logPath, {previous, maxRetainedCharacters = 120000}) async {
                return LogPanelFileState(
                  content: content,
                  fileLength: content.length,
                  unchangedCount: 0,
                  nextPollInterval: const Duration(seconds: 1),
                );
              },
              enableFallbackPolling: false,
              logUpdateStreamFactory: (_) => controller.stream,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.search_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'target');
    await tester.pumpAndSettle();

    expect(find.text('0/0'), findsOneWidget);

    content = 'alpha\nbeta\nnew target';
    controller.add(null);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('1/1'), findsOneWidget);

    await controller.close();
  });

  testWidgets('log panel keeps scroll position when paused and new logs arrive', (
    tester,
  ) async {
    final controller = StreamController<Object?>();
    addTearDown(controller.close);
    var content = List.generate(120, (index) => 'line $index').join('\n');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: LogPanel(
              isDark: true,
              prepareLogFile: () async => const LogFileOpenResult(
                status: LogFileOpenStatus.ready,
                logPath: '/tmp/mock.log',
              ),
              readLogState: (
                logPath, {
                previous,
                maxRetainedCharacters = 120000,
              }) async {
                return LogPanelFileState(
                  content: content,
                  fileLength: content.length,
                  unchangedCount: 0,
                  nextPollInterval: const Duration(seconds: 1),
                );
              },
              enableFallbackPolling: false,
              logUpdateStreamFactory: (_) => controller.stream,
            ),
          ),
        ),
      ),
    );

    final listView = tester.widget<ListView>(find.byType(ListView));
    final listController = listView.controller!;
    listController.jumpTo(120);
    await tester.pump();

    await tester.tap(find.byTooltip('暂停滚动'));
    await tester.pump();

    expect(find.byTooltip('继续滚动'), findsOneWidget);

    final beforeOffset = listController.offset;

    content = '$content\nnew log line';
    controller.add(null);
    await tester.pump(const Duration(milliseconds: 80));

    final afterOffset = listController.offset;
    expect(afterOffset, beforeOffset);
    expect(find.text('新日志'), findsOneWidget);
  });

  testWidgets(
    'log panel keeps scroll position when paused and matching search logs arrive',
    (tester) async {
      final controller = StreamController<Object?>();
      addTearDown(controller.close);
      var content = List.generate(
        120,
        (index) => index == 20 ? 'line $index target' : 'line $index',
      ).join('\n');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: LogPanel(
                isDark: true,
                prepareLogFile: () async => const LogFileOpenResult(
                  status: LogFileOpenStatus.ready,
                  logPath: '/tmp/mock.log',
                ),
                readLogState: (
                  logPath, {
                  previous,
                  maxRetainedCharacters = 120000,
                }) async {
                  return LogPanelFileState(
                    content: content,
                    fileLength: content.length,
                    unchangedCount: 0,
                    nextPollInterval: const Duration(seconds: 1),
                  );
                },
                enableFallbackPolling: false,
                logUpdateStreamFactory: (_) => controller.stream,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      final listController =
          tester.widget<ListView>(find.byType(ListView)).controller!;
      listController.jumpTo(listController.position.maxScrollExtent);
      await tester.pump();

      await tester.tap(find.byTooltip('暂停滚动'));
      await tester.pump();
      expect(find.byTooltip('继续滚动'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.search_outlined));
      await tester.pump();
      await tester.enterText(find.byType(TextField).last, 'target');
      await tester.pump();

      final beforeOffset = listController.offset;

      content = '$content\nnew target';
      controller.add(null);
      await tester.pump(const Duration(milliseconds: 80));

      expect(listController.offset, beforeOffset);
      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('新日志'), findsOneWidget);
    },
  );

  testWidgets('log panel resumes by jumping to latest logs', (tester) async {
    final controller = StreamController<Object?>();
    addTearDown(controller.close);
    var content = List.generate(120, (index) => 'line $index').join('\n');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: LogPanel(
              isDark: true,
              prepareLogFile: () async => const LogFileOpenResult(
                status: LogFileOpenStatus.ready,
                logPath: '/tmp/mock.log',
              ),
              readLogState: (
                logPath, {
                previous,
                maxRetainedCharacters = 120000,
              }) async {
                return LogPanelFileState(
                  content: content,
                  fileLength: content.length,
                  unchangedCount: 0,
                  nextPollInterval: const Duration(seconds: 1),
                );
              },
              enableFallbackPolling: false,
              logUpdateStreamFactory: (_) => controller.stream,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final listController =
        tester.widget<ListView>(find.byType(ListView)).controller!;
    listController.jumpTo(120);
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, 120));
    await tester.pump();

    await tester.tap(find.byTooltip('继续滚动'));
    await tester.pump();
    expect(find.byTooltip('暂停滚动'), findsOneWidget);

    content = '$content\nnew log line';
    controller.add(null);
    await tester.pump(const Duration(milliseconds: 80));

    expect(listController.offset, listController.position.maxScrollExtent);
  });

  testWidgets('log panel keeps auto scroll enabled when new logs arrive', (
    tester,
  ) async {
    final controller = StreamController<Object?>();
    addTearDown(controller.close);
    var content = List.generate(120, (index) => 'line $index').join('\n');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: LogPanel(
              isDark: true,
              prepareLogFile: () async => const LogFileOpenResult(
                status: LogFileOpenStatus.ready,
                logPath: '/tmp/mock.log',
              ),
              readLogState: (
                logPath, {
                previous,
                maxRetainedCharacters = 120000,
              }) async {
                return LogPanelFileState(
                  content: content,
                  fileLength: content.length,
                  unchangedCount: 0,
                  nextPollInterval: const Duration(seconds: 1),
                );
              },
              enableFallbackPolling: false,
              logUpdateStreamFactory: (_) => controller.stream,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    content = '$content\nnew log line';
    controller.add(null);
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.byTooltip('暂停滚动'), findsOneWidget);
    expect(find.byTooltip('继续滚动'), findsNothing);
  });

  testWidgets('log panel lazily builds long filtered content', (tester) async {
    final lines = List.generate(200, (index) => 'line $index target');
    final content = lines.join('\n');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: LogPanel(
              isDark: true,
              prepareLogFile: () async => const LogFileOpenResult(
                status: LogFileOpenStatus.ready,
                logPath: '/tmp/mock.log',
              ),
              readLogState: (
                logPath, {
                previous,
                maxRetainedCharacters = 120000,
              }) async {
                return LogPanelFileState(
                  content: content,
                  fileLength: content.length,
                  unchangedCount: 0,
                  nextPollInterval: const Duration(seconds: 1),
                );
              },
              enableFallbackPolling: false,
              logUpdateStreamFactory: (_) => const Stream<Object?>.empty(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.filter_alt_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'target');
    await tester.pumpAndSettle();

    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(SelectableText), findsWidgets);
    expect(find.byType(SelectableText), isNot(findsNWidgets(200)));
  });

  testWidgets('log panel supports custom retained character limit', (
    tester,
  ) async {
    const content = '1234567890';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: LogPanel(
              isDark: true,
              maxRetainedCharacters: 5,
              prepareLogFile: () async => const LogFileOpenResult(
                status: LogFileOpenStatus.ready,
                logPath: '/tmp/mock.log',
              ),
              readLogState: (
                logPath, {
                previous,
                maxRetainedCharacters = 120000,
              }) async {
                return LogPanelFileState(
                  content: content.substring(content.length - maxRetainedCharacters),
                  fileLength: content.length,
                  unchangedCount: 0,
                  nextPollInterval: const Duration(seconds: 1),
                );
              },
              enableFallbackPolling: false,
              logUpdateStreamFactory: (_) => const Stream<Object?>.empty(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('67890'), findsOneWidget);
    expect(find.textContaining('1234567890'), findsNothing);
  });

  testWidgets('log panel shows more visible log area when height increases', (
    tester,
  ) async {
    Widget buildPanel(double height) {
      final content = List.generate(120, (index) => 'line $index').join('\n');
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: height,
            child: LogPanel(
              isDark: true,
              prepareLogFile: () async => const LogFileOpenResult(
                status: LogFileOpenStatus.ready,
                logPath: '/tmp/mock.log',
              ),
              readLogState: (
                logPath, {
                previous,
                maxRetainedCharacters = 120000,
              }) async {
                return LogPanelFileState(
                  content: content,
                  fileLength: content.length,
                  unchangedCount: 0,
                  nextPollInterval: const Duration(seconds: 1),
                );
              },
              enableFallbackPolling: false,
              logUpdateStreamFactory: (_) => const Stream<Object?>.empty(),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildPanel(300));
    await tester.pumpAndSettle();
    final shortHeight = tester.getSize(find.byType(ListView)).height;

    await tester.pumpWidget(buildPanel(500));
    await tester.pumpAndSettle();
    final tallHeight = tester.getSize(find.byType(ListView)).height;

    expect(tallHeight - shortHeight, greaterThan(120));
  });
}
