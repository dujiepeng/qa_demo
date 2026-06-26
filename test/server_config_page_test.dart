import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_flutter/common/server_config_page.dart';
import 'package:qa_flutter/config/server_config.dart';
import 'package:qa_flutter/theme/app_settings.dart';

void main() {
  testWidgets('qa cabin server config exposes manual server fields', (
    tester,
  ) async {
    final settings = AppSettings();
    settings.activeEnvName = ServerEnvironment.qaCabin.name;
    settings.saveCustomEnv(ServerEnvironment.qaCabin.name, {
      'appKey': ServerEnvironment.qaCabin.appKey,
      'restServer': ServerEnvironment.qaCabin.restServer,
      'msyncServer': ServerEnvironment.qaCabin.msyncServer,
      'msyncPort': ServerEnvironment.qaCabin.msyncPort,
      'wsServer': ServerEnvironment.qaCabin.wsServer,
      'wsPort': ServerEnvironment.qaCabin.wsPort,
      'wsPath': ServerEnvironment.qaCabin.wsPath,
      'isMsync': false,
      'enableTls': false,
    });

    await tester.pumpWidget(const MaterialApp(home: ServerConfigPage()));

    expect(find.text('DNS URL'), findsNothing);
    expect(find.text('AppKey'), findsOneWidget);
    expect(find.text('REST 配置'), findsOneWidget);
    expect(find.text('MSYNC 配置'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'REST 服务器地址'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'MSYNC 服务器地址'), findsOneWidget);

    await tester.tap(find.text('保存并使用该配置'));
    await tester.pumpAndSettle();

    final saved = settings.getCustomEnv(ServerEnvironment.qaCabin.name);
    expect(saved?['appKey'], ServerEnvironment.qaCabin.appKey);
    expect(saved?['restServer'], 'http://10.202.1.60:8081');
    expect(saved?['msyncServer'], '10.202.1.60');
    expect(saved?['msyncPort'], 4300);
    expect(saved?['wsServer'], '10.202.1.60');
    expect(saved?['wsPort'], 4717);
    expect(saved?['wsPath'], '/websocket');
    expect(saved?['isMsync'], false);
    expect(saved?['enableTls'], false);
    expect(saved?.containsKey('dnsUrl'), isFalse);
  });
}
