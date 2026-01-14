import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/settings_page.dart';
import 'theme/app_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 加载持久化配置
  await AppSettings().loadSettings();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings();
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
        '/settings': (context) => const SettingsPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
