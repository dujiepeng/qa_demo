import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_flutter/common/utils/log_file_helper.dart';
import 'package:qa_flutter/common/utils/app_route_observer.dart';
import 'package:qa_flutter/common/widgets/log_page_launcher.dart';

void main() {
  setUp(() {
    debugResetLogPageLauncherState();
  });

  testWidgets('deduplicates repeated open requests while one is in progress', (
    tester,
  ) async {
    final completer = Completer<LogFileOpenResult>();
    var prepareCalls = 0;
    var pageOpenCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: appNavigatorKey,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                unawaited(
                  openSdkLogPage(
                    context,
                    prepareLogFile: () {
                      prepareCalls++;
                      return completer.future;
                    },
                    pushLogPage: (navigator, logPath) async {
                      pageOpenCalls++;
                    },
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
    await tester.pump();

    expect(prepareCalls, 1);

    completer.complete(
      const LogFileOpenResult(
        status: LogFileOpenStatus.ready,
        logPath: '/tmp/easemob.log',
      ),
    );
    await tester.pumpAndSettle();

    expect(pageOpenCalls, 1);
  });

  testWidgets('opens log page even when caller context has no navigator', (
    tester,
  ) async {
    var pageOpenCalls = 0;
    final overlayChild = Builder(
      builder: (overlayContext) => ElevatedButton(
        onPressed: () {
          unawaited(
            openSdkLogPage(
              overlayContext,
              prepareLogFile: () async => const LogFileOpenResult(
                status: LogFileOpenStatus.ready,
                logPath: '/tmp/easemob.log',
              ),
              pushLogPage: (navigator, logPath) async {
                pageOpenCalls++;
              },
            ),
          );
        },
        child: const Text('open'),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: appNavigatorKey,
        home: Scaffold(
          body: Overlay(
            initialEntries: [
              OverlayEntry(builder: (_) => Center(child: overlayChild)),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(pageOpenCalls, 1);
  });
}
