import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:qa_flutter/mobile/my_models.dart';
import 'package:qa_flutter/mobile/my_user_profile_page_mobile.dart';

void main() {
  testWidgets('user profile page is read only by default', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MyUserProfilePageMobile(
          initialProfile: MyUserProfile(
            nickname: '测试用户',
            birthday: '2000-01-01',
            email: 'test@example.com',
          ),
          updateOwnInfo:
              ({
                String? nickname,
                String? avatarUrl,
                String? birth,
                String? mail,
                String? phone,
                int? gender,
                String? sign,
                String? ext,
              }) async {
                return EMUserInfo(
                  'qa_user',
                  nickName: nickname,
                  avatarUrl: avatarUrl,
                  birth: birth,
                  mail: mail,
                  phone: phone,
                  gender: gender ?? 0,
                  sign: sign,
                  ext: ext,
                );
              },
        ),
      ),
    );

    expect(find.text('编辑'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('测试用户'), findsOneWidget);
    expect(find.text('2000-01-01'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
  });

  testWidgets('user profile page toggles edit and save', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MyUserProfilePageMobile(
          initialProfile: MyUserProfile(
            nickname: '测试用户',
            birthday: '2000-01-01',
            email: 'test@example.com',
          ),
          updateOwnInfo:
              ({
                String? nickname,
                String? avatarUrl,
                String? birth,
                String? mail,
                String? phone,
                int? gender,
                String? sign,
                String? ext,
              }) async {
                return EMUserInfo(
                  'qa_user',
                  nickName: nickname,
                  avatarUrl: avatarUrl,
                  birth: birth,
                  mail: mail,
                  phone: phone,
                  gender: gender ?? 0,
                  sign: sign,
                  ext: ext,
                );
              },
        ),
      ),
    );

    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();

    expect(find.text('保存'), findsOneWidget);
    await _enterProfileField(tester, '昵称', '新昵称');
    await _enterProfileField(tester, '生日', '2024-05-20');
    await _enterProfileField(tester, '邮箱', 'new@example.com');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('编辑'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('新昵称'), findsOneWidget);
    expect(find.text('2024-05-20'), findsOneWidget);
    expect(find.text('new@example.com'), findsOneWidget);
  });

  testWidgets('user profile page loads own info from server on open', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MyUserProfilePageMobile(
          initialProfile: const MyUserProfile(
            nickname: '本地昵称',
            birthday: '1999-09-09',
            email: 'local@example.com',
          ),
          fetchOwnInfo: () async => EMUserInfo(
            'qa_user',
            nickName: '服务端昵称',
            birth: '2001-02-03',
            mail: 'server@example.com',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('服务端昵称'), findsOneWidget);
    expect(find.text('2001-02-03'), findsOneWidget);
    expect(find.text('server@example.com'), findsOneWidget);
    expect(find.text('本地昵称'), findsNothing);
  });

  testWidgets('user profile page shows all own info fields from server', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MyUserProfilePageMobile(
          initialProfile: const MyUserProfile(
            nickname: '本地昵称',
            birthday: '1999-09-09',
            email: 'local@example.com',
          ),
          fetchOwnInfo: () async => EMUserInfo(
            'qa_user',
            nickName: '服务端昵称',
            avatarUrl: 'https://example.com/avatar.png',
            mail: 'server@example.com',
            phone: '13800138000',
            gender: 2,
            sign: 'QA signature',
            birth: '2001-02-03',
            ext: '{"role":"qa"}',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('服务端昵称'), findsOneWidget);
    expect(find.text('https://example.com/avatar.png'), findsOneWidget);
    expect(find.text('server@example.com'), findsOneWidget);
    expect(find.text('13800138000'), findsOneWidget);
    expect(find.text('女 (2)'), findsOneWidget);
    expect(find.text('2001-02-03'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('QA signature'), 120);
    expect(find.text('QA signature'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('{"role":"qa"}'), 120);
    expect(find.text('{"role":"qa"}'), findsOneWidget);
  });

  testWidgets('user profile page saves all own info fields to server', (
    tester,
  ) async {
    String? savedAvatarUrl;
    String? savedPhone;
    int? savedGender;
    String? savedSign;
    String? savedExt;

    await tester.pumpWidget(
      MaterialApp(
        home: MyUserProfilePageMobile(
          initialProfile: const MyUserProfile(
            nickname: '本地昵称',
            birthday: '1999-09-09',
            email: 'local@example.com',
          ),
          fetchOwnInfo: () async => EMUserInfo('qa_user'),
          updateOwnInfo:
              ({
                String? nickname,
                String? avatarUrl,
                String? birth,
                String? mail,
                String? phone,
                int? gender,
                String? sign,
                String? ext,
              }) async {
                savedAvatarUrl = avatarUrl;
                savedPhone = phone;
                savedGender = gender;
                savedSign = sign;
                savedExt = ext;
                return EMUserInfo(
                  'qa_user',
                  nickName: nickname,
                  avatarUrl: avatarUrl,
                  mail: mail,
                  phone: phone,
                  gender: gender ?? 0,
                  sign: sign,
                  birth: birth,
                  ext: ext,
                );
              },
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();

    await _enterProfileField(tester, '昵称', '完整昵称');
    await _enterProfileField(tester, '头像', 'https://avatar.test/a.png');
    await _enterProfileField(tester, '生日', '2024-06-10');
    await _enterProfileField(tester, '邮箱', 'full@example.com');
    await _enterProfileField(tester, '手机号', '13900139000');
    await _enterProfileField(tester, '性别', '1');
    await _enterProfileField(tester, '签名', 'hello sign');
    await _enterProfileField(tester, '扩展', '{"x":1}');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(savedAvatarUrl, 'https://avatar.test/a.png');
    expect(savedPhone, '13900139000');
    expect(savedGender, 1);
    expect(savedSign, 'hello sign');
    expect(savedExt, '{"x":1}');
  });

  testWidgets('user profile page saves own info to server', (tester) async {
    String? savedNickname;
    String? savedBirthday;
    String? savedEmail;

    await tester.pumpWidget(
      MaterialApp(
        home: MyUserProfilePageMobile(
          initialProfile: const MyUserProfile(
            nickname: '本地昵称',
            birthday: '1999-09-09',
            email: 'local@example.com',
          ),
          fetchOwnInfo: () async => EMUserInfo(
            'qa_user',
            nickName: '服务端昵称',
            birth: '2001-02-03',
            mail: 'server@example.com',
          ),
          updateOwnInfo:
              ({
                String? nickname,
                String? avatarUrl,
                String? birth,
                String? mail,
                String? phone,
                int? gender,
                String? sign,
                String? ext,
              }) async {
                savedNickname = nickname;
                savedBirthday = birth;
                savedEmail = mail;
                return EMUserInfo(
                  'qa_user',
                  nickName: '保存后昵称',
                  birth: '2024-06-01',
                  mail: 'saved@example.com',
                );
              },
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();

    await _enterProfileField(tester, '昵称', '提交昵称');
    await _enterProfileField(tester, '生日', '2024-05-20');
    await _enterProfileField(tester, '邮箱', 'submit@example.com');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(savedNickname, '提交昵称');
    expect(savedBirthday, '2024-05-20');
    expect(savedEmail, 'submit@example.com');
    expect(find.text('保存后昵称'), findsOneWidget);
    expect(find.text('2024-06-01'), findsOneWidget);
    expect(find.text('saved@example.com'), findsOneWidget);
  });

  testWidgets(
    'user profile page keeps submitted values when save returns partial info',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MyUserProfilePageMobile(
            initialProfile: const MyUserProfile(
              nickname: '本地昵称',
              birthday: '1999-09-09',
              email: 'local@example.com',
            ),
            fetchOwnInfo: () async => EMUserInfo(
              'qa_user',
              nickName: '服务端昵称',
              birth: '2001-02-03',
              mail: 'server@example.com',
            ),
            updateOwnInfo:
                ({
                  String? nickname,
                  String? avatarUrl,
                  String? birth,
                  String? mail,
                  String? phone,
                  int? gender,
                  String? sign,
                  String? ext,
                }) async {
                  return EMUserInfo('qa_user');
                },
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('编辑'));
      await tester.pumpAndSettle();

      await _enterProfileField(tester, '昵称', '提交昵称');
      await _enterProfileField(tester, '生日', '2024-05-20');
      await _enterProfileField(tester, '邮箱', 'submit@example.com');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.text('提交昵称'), findsOneWidget);
      expect(find.text('2024-05-20'), findsOneWidget);
      expect(find.text('submit@example.com'), findsOneWidget);
      expect(find.text('未设置'), findsNothing);
    },
  );
}

Future<void> _enterProfileField(
  WidgetTester tester,
  String label,
  String value,
) async {
  final finder = find.byKey(ValueKey('profile_field_$label'));
  for (var i = 0; i < 12 && finder.evaluate().isEmpty; i += 1) {
    await tester.drag(find.byType(ListView), const Offset(0, -180));
    await tester.pumpAndSettle();
  }
  expect(finder, findsWidgets);
  await tester.enterText(finder.first, value);
}
