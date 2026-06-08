// ignore_for_file: depend_on_referenced_packages

import 'package:flutter_test/flutter_test.dart';
import 'package:im_flutter_sdk_interface/im_flutter_sdk_interface.dart';
import 'package:qa_flutter/common/mixins/login_logic_mixin.dart';
import 'package:qa_flutter/config/server_config.dart';
import 'package:qa_flutter/theme/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InitCaptureClient extends Client {
  Map? initOptions;

  @override
  Future<dynamic> callNativeMethod(String method, [dynamic params]) async {
    if (method == 'init') {
      initOptions = params as Map;
      return null;
    }
    if (method == 'getCurrentUserId') {
      return {'getCurrentUserId': null};
    }
    return {};
  }

  @override
  void updateNativeHandler(handler) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'cold start always resets persisted login flag to show login page',
    () async {
      SharedPreferences.setMockInitialValues({'is_logged_in': true});
      final settings = AppSettings();

      await settings.loadSettings();

      expect(settings.isLoggedIn, isFalse);
    },
  );

  test('saveSettings no longer persists legacy login flag', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings();

    settings.isLoggedIn = true;
    await settings.saveSettings();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('is_logged_in'), isFalse);
  });

  test('persists log overlay minimized state and bubble placement', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings();

    await settings.setLogOverlayMinimized(true);
    await settings.updateLogBubblePlacement(
      onRightSide: false,
      verticalRatio: 0.35,
    );

    await settings.setLogOverlayMinimized(false);
    await settings.updateLogBubblePlacement(
      onRightSide: true,
      verticalRatio: 0.8,
    );

    await settings.loadSettings();

    expect(settings.isLogOverlayMinimized, isFalse);
    expect(settings.logBubbleOnRightSide, isTrue);
    expect(settings.logBubbleVerticalRatio, 0.8);
  });

  test('persists last login credentials for device refresh', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings();

    settings.lastLoginUserId = 'qa_user';
    settings.lastLoginPassword = 'secret';
    await settings.saveSettings();

    final restored = AppSettings();
    await restored.loadSettings();

    expect(restored.lastLoginUserId, 'qa_user');
    expect(restored.lastLoginPassword, 'secret');
  });

  test('qa cabin environment is available before TKE with default servers', () {
    final environments = ServerEnvironment.environments;
    final qaIndex = environments.indexWhere((env) => env.name == 'qa隔舱');
    final tkeIndex = environments.indexWhere((env) => env.name == 'TKE');

    expect(qaIndex, isNot(-1));
    expect(tkeIndex, isNot(-1));
    expect(qaIndex, lessThan(tkeIndex));

    final qaCabin = environments[qaIndex];
    expect(qaCabin.appKey, 'easemob-demo#qatest');
    expect(qaCabin.restServer, 'http://10.202.1.58:8081');
    expect(qaCabin.wsServer, '10.202.1.58');
    expect(qaCabin.wsPort, 4717);
    expect(qaCabin.wsPath, '/websocket');
    expect(qaCabin.enableTls, isFalse);
    expect(qaCabin.msyncServer, '10.202.1.58');
    expect(qaCabin.msyncPort, 4300);
  });

  test('qa cabin websocket init disables TLS for ws endpoint', () async {
    SharedPreferences.setMockInitialValues({});
    final previousClient = Client.instance;
    final client = _InitCaptureClient();
    Client.instance = client;
    addTearDown(() {
      Client.instance = previousClient;
    });

    final settings = AppSettings();
    settings.isInit = false;
    settings.useCustomAppKey = true;
    settings.useCustomServer = true;
    settings.appKey = ServerEnvironment.qaCabin.appKey;
    settings.restServer = ServerEnvironment.qaCabin.restServer;
    settings.imServer = ServerEnvironment.qaCabin.msyncServer;
    settings.imPort = ServerEnvironment.qaCabin.msyncPort;
    settings.saveCustomEnv('qa隔舱', {
      'appKey': ServerEnvironment.qaCabin.appKey,
      'restServer': ServerEnvironment.qaCabin.restServer,
      'msyncServer': ServerEnvironment.qaCabin.msyncServer,
      'msyncPort': ServerEnvironment.qaCabin.msyncPort,
      'wsServer': ServerEnvironment.qaCabin.wsServer,
      'wsPort': ServerEnvironment.qaCabin.wsPort,
      'wsPath': ServerEnvironment.qaCabin.wsPath,
      'enableTls': ServerEnvironment.qaCabin.enableTls,
      'isMsync': false,
    });
    settings.activeEnvName = 'qa隔舱';

    await ensureSdkInit(settings);

    expect(client.initOptions?['webSocketServer'], '10.202.1.58/websocket');
    expect(client.initOptions?['webSocketPort'], 4717);
    expect(client.initOptions?['enableTLS'], isFalse);
    expect(client.initOptions?['imServer'], isNull);
    expect(client.initOptions?['imPort'], isNull);
  });

  test('qa cabin websocket uses default TLS flag for saved legacy env', () async {
    final settings = AppSettings();
    settings.useCustomAppKey = true;
    settings.useCustomServer = true;
    settings.appKey = ServerEnvironment.qaCabin.appKey;
    settings.restServer = ServerEnvironment.qaCabin.restServer;
    settings.imServer = ServerEnvironment.qaCabin.msyncServer;
    settings.imPort = ServerEnvironment.qaCabin.msyncPort;
    settings.saveCustomEnv('qa隔舱', {
      'appKey': ServerEnvironment.qaCabin.appKey,
      'restServer': ServerEnvironment.qaCabin.restServer,
      'msyncServer': ServerEnvironment.qaCabin.msyncServer,
      'msyncPort': ServerEnvironment.qaCabin.msyncPort,
      'wsServer': ServerEnvironment.qaCabin.wsServer,
      'wsPort': ServerEnvironment.qaCabin.wsPort,
      'isMsync': false,
    });
    settings.activeEnvName = 'qa隔舱';

    expect(settings.activeConfig?.enableTls, isFalse);
    expect(settings.activeConfig?.wsPath, '/websocket');
  });
}
