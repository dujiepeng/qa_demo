import 'package:flutter/material.dart';
import 'package:qa_flutter/test_pages/chatroom/test_chat_room_list_page.dart';
import 'package:qa_flutter/theme/app_colors.dart';
import 'package:qa_flutter/uikit/lib/chat_uikit.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/settings_page.dart';
import 'test_pages/group/test_group_list_page.dart';
import 'test_pages/single/test_single_chat_page.dart';
import 'theme/app_settings.dart';
import 'utils/version_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 加载持久化配置
  await AppSettings().loadSettings();

  // 启动后台版本检查
  VersionManager().checkVersion();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ChatUIKitLocalizations _localization = ChatUIKitLocalizations();

  @override
  void initState() {
    _localization.translate('zh');
    _localization.resetLocales();
    ChatUIKitTheme.instance.setColor(
      AppSettings().isDarkMode ? AppColors.darkColor : AppColors.lightColor,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QA Flutter',
      debugShowCheckedModeBanner: false,
      supportedLocales: _localization.supportedLocales,
      localizationsDelegates: _localization.localizationsDelegates,
      localeResolutionCallback: _localization.localeResolutionCallback,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // 根据登录状态动态决定起始页面
      initialRoute: AppSettings().isLoggedIn ? '/home' : '/login',
      onGenerateRoute: (settings) {
        return ChatUIKitRoute().generateRoute(settings);
      },
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/settings': (context) => const SettingsPage(),
        '/test_chat_room_list': (context) => const TestChatRoomListPage(),
        '/test_group_list': (context) => const TestGroupListPage(),
        '/test_single_chat': (context) => const TestSingleChatPage(),
      },
    );
  }
}
