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
import 'pages/single/black_list_page.dart';
import 'pages/single/contact_presence_page.dart';
import 'pages/single/single_chat_list_page.dart';
import 'pages/single/single_chat_page.dart';
import 'pages/conversation/conversation_list_page.dart';
import 'common/utils/connection_status_overlay_controller.dart';
import 'common/utils/other_logged_in_devices_controller.dart';
import 'common/utils/log_service.dart';
import 'common/utils/offline_message_counter.dart';
import 'common/utils/app_route_observer.dart';
import 'common/utils/version_manager.dart';
import 'common/widgets/connection_status_overlay.dart';
import 'common/widgets/common_gradient_background.dart';
import 'mobile/me_page_mobile.dart';
import 'mobile/my_page_mobile.dart';
import 'common/widgets/layout/mobile_log_overlay.dart';
import 'common/widgets/responsive_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化应用配置 (读取版本号等信息)
  await AppConfig.init();

  // 加载持久化配置
  await AppSettings().loadSettings();

  // 启动后台版本检查
  VersionManager().silentCheck(source: VersionCheckSource.startupSilent);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: AppSettings()),
        ChangeNotifierProvider.value(value: VersionManager()),
        ChangeNotifierProvider(create: (_) => LogService()),
        ChangeNotifierProvider(create: (_) => OfflineMessageCounter()),
        ChangeNotifierProvider(
          create: (_) => ConnectionStatusOverlayController(),
        ),
        ChangeNotifierProvider(create: (_) => OtherLoggedInDevicesController()),
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
      navigatorObservers: [appRouteObserver],

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();

        // 使用 ResponsiveLayout 判断是否在移动端显示全局日志遮罩
        return ResponsiveLayout(
          mobile: CommonGradientBackground(
            isDark: settings.isDarkMode,
            child: Stack(
              children: [
                MobileLogOverlay(child: child),
                const Positioned.fill(child: ConnectionStatusOverlay()),
              ],
            ),
          ),
          tablet: CommonGradientBackground(
            isDark: settings.isDarkMode,
            child: Stack(
              children: [
                child,
                const Positioned.fill(child: ConnectionStatusOverlay()),
              ],
            ),
          ),
        );
      },
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
        '/contact_presence': (context) => const ContactPresencePage(),
        '/black_list': (context) => const BlackListPage(),
        '/conversation_list': (context) => const ConversationListPage(),
        '/me_page': (context) => const MePageMobile(),
        '/my_page': (context) => const MyPageMobile(),
      },
    );
  }
}
