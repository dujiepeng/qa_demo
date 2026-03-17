import 'package:chat_uikit_theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qa_flutter/pages/chatroom/room_list_page.dart';
import 'package:qa_flutter/theme/app_colors.dart';
import 'package:qa_flutter/theme/app_settings.dart';
import 'config/app_config.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'common/server_config_page.dart';
import 'pages/group/group_list_page.dart';
import 'pages/single/single_chat_list_page.dart';
import 'pages/single/single_chat_page.dart';
import 'pages/conversation/conversation_list_page.dart';
import 'common/utils/log_service.dart';
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
        ChangeNotifierProvider(create: (_) => LogService()),
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
  @override
  void initState() {
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

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // 根据登录状态动态决定起始页面
      initialRoute: settings.isLoggedIn ? '/home' : '/login',

      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/server_config': (context) => const ServerConfigPage(),
        '/room_list': (context) => const RoomListPage(),
        '/group_list': (context) => const GroupListPage(),
        '/single_chat': (context) => const SingleChatPage(),
        '/single_chat_list': (context) => const SingleChatListPage(),
        '/conversation_list': (context) => const ConversationListPage(),
      },
    );
  }
}
