import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../common/widgets/common_gradient_background.dart';
import '../common/mixins/login_logic_mixin.dart';

class LoginPageMobile extends StatefulWidget {
  const LoginPageMobile({super.key});

  @override
  State<LoginPageMobile> createState() => _LoginPageMobileState();
}

class _LoginPageMobileState extends State<LoginPageMobile>
    with LoginLogicMixin {
  @override
  Widget build(BuildContext context) {
    final isDark = settings.isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: AppColors.textPrimary(isDark).withValues(alpha: 0.8),
            ),
            onPressed: () => Navigator.pushNamed(context, '/server_config'),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: CommonGradientBackground(
          isDark: isDark,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
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
                          'QA DEMO',
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
                        controller: uidController,
                        hintText: 'UID',
                        icon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),

                      // Password Input
                      _buildTextField(
                        controller: pwdController,
                        hintText: 'Password',
                        icon: Icons.lock_outline,
                        isObscured: true,
                        textInputAction: TextInputAction.done,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 30),

                      // Login Button
                      isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary(isDark),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary(isDark),
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
