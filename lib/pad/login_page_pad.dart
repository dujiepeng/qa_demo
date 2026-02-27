import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';
import '../common/widgets/common_gradient_background.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';

class LoginPagePad extends StatefulWidget {
  const LoginPagePad({super.key});

  @override
  State<LoginPagePad> createState() => _LoginPagePadState();
}

class _LoginPagePadState extends State<LoginPagePad> {
  final TextEditingController _uidController = TextEditingController();
  final TextEditingController _pwdController = TextEditingController();
  bool _isLoading = false;
  final _settings = AppSettings();

  Future<void> _handleLogin() async {
    final uid = _uidController.text.trim();
    final pwd = _pwdController.text.trim();

    if (uid.isEmpty || pwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please enter UID and Password')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_settings.isDirty) {
        EMOptions options = _settings.useCustomServer
            ? EMOptions.withAppKey(
                _settings.appKey,
                autoLogin: false,
                debugMode: true,
                imServer: _settings.imServer,
                imPort: _settings.imPort,
                restServer: _settings.restServer,
                enableDNSConfig: false,
              )
            : EMOptions.withAppKey(
                _settings.appKey,
                autoLogin: false,
                debugMode: true,
              );

        await EMClient.getInstance.init(options);
        _settings.isDirty = false;
      }

      await EMClient.getInstance.logout();
      await EMClient.getInstance.loginWithPassword(uid, pwd);

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login Failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _settings.isDarkMode;

    return Scaffold(
      body: CommonGradientBackground(
        isDark: isDark,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.inputBackground(isDark).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.glassBorder(isDark)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.flash_on,
                  size: 80,
                  color: AppColors.primary(isDark),
                ),
                const SizedBox(height: 20),
                Text(
                  'QA DEMO (Pad)',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(isDark),
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                _buildTextField(
                  _uidController,
                  'UID',
                  Icons.person_outline,
                  isDark,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  _pwdController,
                  'Password',
                  Icons.lock_outline,
                  isDark,
                  isObscured: true,
                ),
                const SizedBox(height: 40),
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
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'LOGIN',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                  child: Text(
                    '服务器配置',
                    style: TextStyle(color: AppColors.textSecondary(isDark)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon,
    bool isDark, {
    bool isObscured = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black12 : Colors.white24,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.glassBorder(isDark)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscured,
        style: TextStyle(color: AppColors.textPrimary(isDark)),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.textSecondary(isDark)),
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.textSecondary(isDark).withValues(alpha: 0.5),
          ),
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
