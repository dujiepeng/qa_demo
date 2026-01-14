import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _uidController = TextEditingController();
  final TextEditingController _pwdController = TextEditingController();
  bool _isLoading = false;
  final _settings = AppSettings();

  Future<void> _handleLogin() async {
    final uid = _uidController.text.trim();
    final pwd = _pwdController.text.trim();

    if (uid.isEmpty || pwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter UID and Password',
            style: TextStyle(
              color: AppColors.textPrimary(_settings.isDarkMode),
            ),
          ),
          backgroundColor: AppColors.primary(_settings.isDarkMode),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 暂时保留旧的 SDK 初始化逻辑，但 AppKey 和服务器配置已移除，使用默认值
      if (_settings.isDirty) {
        EMOptions options = EMOptions.withAppKey(
          'easemob#dutest',
          autoLogin: false,
          debugMode: true,
        );
        await EMClient.getInstance.init(options);
        _settings.isDirty = false;
      }

      await EMClient.getInstance.loginWithPassword(uid, pwd);

      // 更新登录状态并保存
      _settings.isLoggedIn = true;
      await _settings.saveSettings();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login Failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _settings.isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: AppColors.textPrimary(isDark).withOpacity(0.8),
            ),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.backgroundStart(isDark),
                AppColors.backgroundEnd(isDark),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand / Logo area
                  Icon(
                    Icons.flash_on,
                    size: 80,
                    color: AppColors.primary(isDark),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'QA FLUTTER',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(isDark),
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // UID Input
                  _buildTextField(
                    controller: _uidController,
                    hintText: 'UID',
                    icon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),

                  // Password Input
                  _buildTextField(
                    controller: _pwdController,
                    hintText: 'Password',
                    icon: Icons.lock_outline,
                    isObscured: true,
                    textInputAction: TextInputAction.done,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 30),

                  // Login Button
                  _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary(isDark),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary(isDark),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                          ),
                          child: const Text(
                            'LOGIN',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isObscured = false,
    TextInputAction? textInputAction,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground(isDark),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.glassBorder(isDark)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscured,
        textInputAction: textInputAction,
        style: TextStyle(color: AppColors.textPrimary(isDark)),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.textSecondary(isDark)),
          hintText: hintText,
          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 20,
          ),
        ),
      ),
    );
  }
}
