import 'package:flutter/material.dart';
import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import '../theme/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _uidController = TextEditingController();
  final TextEditingController _pwdController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final uid = _uidController.text.trim();
    final pwd = _pwdController.text.trim();

    if (uid.isEmpty || pwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter UID and Password')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await EMClient.getInstance.loginWithPassword(uid, pwd);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.backgroundStart, AppColors.backgroundEnd],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Settings Button
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(
                      Icons.settings,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Brand / Logo area
                      const Icon(
                        Icons.flash_on,
                        size: 80,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 20),
                      const Center(
                        child: Text(
                          'QA FLUTTER',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
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
                      ),
                      const SizedBox(height: 20),

                      // Password Input
                      _buildTextField(
                        controller: _pwdController,
                        hintText: 'Password',
                        icon: Icons.lock_outline,
                        isObscured: true,
                      ),
                      const SizedBox(height: 30),

                      // Login Button
                      _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
              ],
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscured,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.textSecondary),
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white38),
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
