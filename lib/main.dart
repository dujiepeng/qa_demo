import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qa_flutter/test_pages/chatroom/test_chat_room_list_page.dart';
import 'package:qa_flutter/theme/app_colors.dart';
import 'package:qa_flutter/uikit/lib/chat_uikit.dart';
import 'config/app_config.dart';
import 'mobile/home_page.dart';
import 'mobile/login_page.dart';
import 'common/settings_page.dart';
import 'test_pages/group/test_group_list_page.dart';
import 'test_pages/single/test_single_chat_list_page.dart';
import 'test_pages/single/test_single_chat_page.dart';
import 'theme/app_settings.dart';
import 'common/utils/version_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化应用配置 (读取版本号等信息)
  await AppConfig.init();

  // 加载持久化配置
  await AppSettings().loadSettings();

  // 启动后台版本检查
  VersionManager().checkVersion();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: AppSettings()),
        ChangeNotifierProvider.value(value: VersionManager()),
      ],
      child: const MyApp(),
    ),
  );
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
    // 监听设置变化
    final settings = context.watch<AppSettings>();

    // 动态同步 UIKit 主题色
    ChatUIKitTheme.instance.setColor(
      settings.isDarkMode ? AppColors.darkColor : AppColors.lightColor,
    );

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
      initialRoute: settings.isLoggedIn ? '/home' : '/login',
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
        '/test_single_chat_list': (context) => const TestSingleChatListPage(),
      },
    );
  }
}
