import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/mobile/push_settings_page_mobile.dart';

void main() {
  void useLargeViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('push settings page binds notifier token', (tester) async {
    useLargeViewport(tester);
    String? capturedNotifierName;
    String? capturedDeviceToken;

    await tester.pumpWidget(
      MaterialApp(
        home: PushSettingsPageMobile(
          bindDeviceToken:
              ({required notifierName, required deviceToken}) async {
                capturedNotifierName = notifierName;
                capturedDeviceToken = deviceToken;
              },
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'notifier name'),
      'qa',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'device token'),
      'token-1',
    );
    await tester.tap(find.text('绑定推送 token'));
    await tester.pumpAndSettle();

    expect(capturedNotifierName, 'qa');
    expect(capturedDeviceToken, 'token-1');
    expect(find.textContaining('绑定推送 token 成功'), findsOneWidget);
  });

  testWidgets(
    'push settings page configures global and conversation silent mode',
    (tester) async {
      useLargeViewport(tester);
      ChatSilentModeParam? globalParam;
      ChatSilentModeParam? conversationParam;
      String? capturedConversationId;
      var synced = false;

      await tester.pumpWidget(
        MaterialApp(
          home: PushSettingsPageMobile(
            setSilentModeForAll: (param) async {
              globalParam = param;
            },
            setConversationSilentMode:
                ({
                  required conversationId,
                  required type,
                  required param,
                }) async {
                  capturedConversationId = conversationId;
                  conversationParam = param;
                },
            syncConversationsSilentMode: () async {
              synced = true;
            },
          ),
        ),
      );

      await tester.enterText(find.widgetWithText(TextField, '免打扰分钟数'), '30');
      await tester.tap(find.text('设置全局静默'));
      await tester.pumpAndSettle();

      expect(globalParam?.silentDuration, 30);
      expect(find.textContaining('设置全局静默成功'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, '会话 ID'),
        'group-001',
      );
      await tester.tap(find.text('设置会话静默'));
      await tester.pumpAndSettle();

      expect(capturedConversationId, 'group-001');
      expect(conversationParam?.silentDuration, 30);
      expect(find.textContaining('设置会话静默成功'), findsOneWidget);

      await tester.tap(find.text('同步会话静默'));
      await tester.pumpAndSettle();

      expect(synced, isTrue);
      expect(find.textContaining('同步会话静默成功'), findsOneWidget);
    },
  );

  testWidgets('push settings page updates display style and template', (
    tester,
  ) async {
    useLargeViewport(tester);
    DisplayStyle? displayStyle;
    String? template;

    await tester.pumpWidget(
      MaterialApp(
        home: PushSettingsPageMobile(
          updatePushDisplayStyle: (style) async {
            displayStyle = style;
          },
          setPushTemplate: (name) async {
            template = name;
          },
        ),
      ),
    );

    await tester.tap(find.text('展示内容'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置展示样式'));
    await tester.pumpAndSettle();

    expect(displayStyle, DisplayStyle.Summary);
    expect(find.textContaining('设置展示样式成功'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, '模板名称'),
      'qa-template',
    );
    await tester.tap(find.text('设置推送模板'));
    await tester.pumpAndSettle();

    expect(template, 'qa-template');
    expect(find.textContaining('设置推送模板成功'), findsOneWidget);
  });

  testWidgets(
    'push settings page manages push language and batch silent mode',
    (tester) async {
      useLargeViewport(tester);
      List<EMConversation>? requestedConversations;
      String? preferredLanguage;
      var fetchedPreferredLanguage = false;

      await tester.pumpWidget(
        MaterialApp(
          home: PushSettingsPageMobile(
            fetchSilentModeForConversations: (conversations) async {
              requestedConversations = conversations;
              return {
                'group-001': ChatSilentModeResult(
                  123,
                  EMConversationType.GroupChat,
                  'group-001',
                  ChatPushRemindType.ALL,
                  null,
                  null,
                ),
              };
            },
            setPreferredNotificationLanguage: (languageCode) async {
              preferredLanguage = languageCode;
            },
            fetchPreferredNotificationLanguage: () async {
              fetchedPreferredLanguage = true;
              return 'zh-Hans';
            },
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, '会话 ID 列表'),
        'group-001\nuser-002',
      );
      await tester.tap(find.text('批量查询静默'));
      await tester.pumpAndSettle();

      expect(requestedConversations, isNotNull);
      expect(requestedConversations, hasLength(2));
      expect(requestedConversations!.first.id, 'group-001');
      expect(requestedConversations!.first.type, EMConversationType.GroupChat);
      expect(find.textContaining('批量会话静默: group-001'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, '推送语言'), 'en');
      await tester.tap(find.text('设置推送语言'));
      await tester.pumpAndSettle();

      expect(preferredLanguage, 'en');
      expect(find.textContaining('设置推送语言成功'), findsOneWidget);

      await tester.tap(find.text('查询推送语言'));
      await tester.pumpAndSettle();

      expect(fetchedPreferredLanguage, isTrue);
      expect(find.textContaining('当前推送语言: zh-Hans'), findsOneWidget);
    },
  );
}
