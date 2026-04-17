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
          updateOwnInfo: ({String? nickname, String? birth, String? mail}) async {
            return EMUserInfo(
              'qa_user',
              nickName: nickname,
              birth: birth,
              mail: mail,
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
          updateOwnInfo: ({String? nickname, String? birth, String? mail}) async {
            return EMUserInfo(
              'qa_user',
              nickName: nickname,
              birth: birth,
              mail: mail,
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();

    expect(find.text('保存'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(3));

    await tester.enterText(find.byType(TextField).at(0), '新昵称');
    await tester.enterText(find.byType(TextField).at(1), '2024-05-20');
    await tester.enterText(find.byType(TextField).at(2), 'new@example.com');
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
          updateOwnInfo: ({
            String? nickname,
            String? birth,
            String? mail,
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

    await tester.enterText(find.byType(TextField).at(0), '提交昵称');
    await tester.enterText(find.byType(TextField).at(1), '2024-05-20');
    await tester.enterText(find.byType(TextField).at(2), 'submit@example.com');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(savedNickname, '提交昵称');
    expect(savedBirthday, '2024-05-20');
    expect(savedEmail, 'submit@example.com');
    expect(find.text('保存后昵称'), findsOneWidget);
    expect(find.text('2024-06-01'), findsOneWidget);
    expect(find.text('saved@example.com'), findsOneWidget);
  });
}
