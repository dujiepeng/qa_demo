import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/mobile/user_info_lookup_page_mobile.dart';

void main() {
  testWidgets('looks up multiple user infos and displays all attributes', (
    tester,
  ) async {
    List<String>? requestedUserIds;

    await tester.pumpWidget(
      MaterialApp(
        home: UserInfoLookupPageMobile(
          fetchUsersInfo: (userIds) async {
            requestedUserIds = userIds;
            return {
              'qa01': EMUserInfo(
                'qa01',
                nickName: 'QA一号',
                avatarUrl: 'https://example.com/qa01.png',
                mail: 'qa01@example.com',
                phone: '13800000001',
                gender: 1,
                sign: 'hello qa',
                birth: '2000-01-01',
                ext: '{"role":"tester"}',
              ),
              'qa02': EMUserInfo('qa02', nickName: 'QA二号', gender: 2),
            };
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'qa01, qa02\nqa01');
    await tester.tap(find.text('查询'));
    await tester.pumpAndSettle();

    expect(requestedUserIds, ['qa01', 'qa02']);
    expect(find.text('qa01'), findsOneWidget);
    expect(find.text('昵称: QA一号'), findsOneWidget);
    expect(find.text('头像: https://example.com/qa01.png'), findsOneWidget);
    expect(find.text('邮箱: qa01@example.com'), findsOneWidget);
    expect(find.text('手机号: 13800000001'), findsOneWidget);
    expect(find.text('性别: 男'), findsOneWidget);
    expect(find.text('签名: hello qa'), findsOneWidget);
    expect(find.text('生日: 2000-01-01'), findsOneWidget);
    expect(find.text('扩展: {"role":"tester"}'), findsOneWidget);
    expect(find.text('qa02'), findsOneWidget);
    expect(find.text('昵称: QA二号'), findsOneWidget);
    expect(find.text('性别: 女'), findsOneWidget);
  });

  testWidgets('blocks lookups with more than 100 user ids', (tester) async {
    var called = false;
    final userIds = List.generate(101, (index) => 'qa$index').join(',');

    await tester.pumpWidget(
      MaterialApp(
        home: UserInfoLookupPageMobile(
          fetchUsersInfo: (_) async {
            called = true;
            return {};
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), userIds);
    await tester.tap(find.text('查询'));
    await tester.pumpAndSettle();

    expect(called, isFalse);
    expect(find.text('每次查询的用户 ID 数量不能超过 100 个'), findsOneWidget);
  });

  testWidgets('marks user ids missing from sdk result', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UserInfoLookupPageMobile(fetchUsersInfo: (_) async => {}),
      ),
    );

    await tester.enterText(find.byType(TextField), 'missing_user');
    await tester.tap(find.text('查询'));
    await tester.pumpAndSettle();

    expect(find.text('missing_user'), findsAtLeastNWidgets(1));
    expect(find.text('未返回属性'), findsOneWidget);
  });
}
