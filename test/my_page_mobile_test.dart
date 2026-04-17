import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qa_flutter/common/utils/other_logged_in_devices_controller.dart';
import 'package:qa_flutter/mobile/my_devices_page_mobile.dart';
import 'package:qa_flutter/mobile/my_page_mobile.dart';
import 'package:qa_flutter/mobile/my_user_profile_page_mobile.dart';

void main() {
  testWidgets('my page shows all action entries', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => OtherLoggedInDevicesController(),
        child: const MaterialApp(home: MyPageMobile()),
      ),
    );

    expect(find.text('登录的其他设备'), findsOneWidget);
    expect(find.text('设置推送昵称'), findsOneWidget);
    expect(find.text('设置用户信息'), findsOneWidget);
    expect(find.textContaining('查看当前账号在其他设备上的登录信息'), findsNothing);
    expect(find.textContaining('当前：'), findsNothing);
    expect(find.textContaining('昵称：'), findsNothing);
  });

  testWidgets('my page updates push nickname from dialog', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => OtherLoggedInDevicesController(),
        child: const MaterialApp(home: MyPageMobile()),
      ),
    );

    await tester.tap(find.text('设置推送昵称'));
    await tester.pumpAndSettle();

    expect(find.text('设置推送昵称'), findsAtLeastNWidgets(1));
    await tester.enterText(find.byType(TextField), 'QA推送昵称');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
  });

  testWidgets('push nickname dialog does not overflow on short viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => OtherLoggedInDevicesController(),
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 320),
              viewInsets: EdgeInsets.only(bottom: 180),
            ),
            child: const MyPageMobile(),
          ),
        ),
      ),
    );

    await tester.tap(find.text('设置推送昵称'));
    await tester.pumpAndSettle();

    expect(find.text('设置推送昵称'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('my page opens device page', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => OtherLoggedInDevicesController(),
        child: const MaterialApp(home: MyPageMobile()),
      ),
    );

    await tester.tap(find.text('登录的其他设备'));
    await tester.pumpAndSettle();

    expect(find.byType(MyDevicesPageMobile), findsOneWidget);
    expect(find.text('其他登录设备'), findsOneWidget);
  });

  testWidgets('my page opens user profile page', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => OtherLoggedInDevicesController(),
        child: const MaterialApp(home: MyPageMobile()),
      ),
    );

    await tester.tap(find.text('设置用户信息'));
    await tester.pumpAndSettle();

    expect(find.byType(MyUserProfilePageMobile), findsOneWidget);
    expect(find.text('用户信息'), findsOneWidget);
  });

}
