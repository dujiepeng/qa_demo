import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../common/widgets/common_gradient_background.dart';
import '../common/mixins/login_logic_mixin.dart';
import '../common/utils/version_manager.dart';
import '../common/widgets/log_page_launcher.dart';
import '../common/widgets/update_dialog.dart';
import '../common/widgets/version_check_feedback.dart';

class LoginPageMobile extends StatefulWidget {
  const LoginPageMobile({super.key});

  @override
  State<LoginPageMobile> createState() => _LoginPageMobileState();
}

class _LoginPageMobileState extends State<LoginPageMobile>
    with LoginLogicMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isCheckingVersion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      VersionManager().silentCheck(source: VersionCheckSource.loginSilent);
    });
  }

  Future<void> _handleCheckVersion() async {
    if (_isCheckingVersion) return;
    setState(() => _isCheckingVersion = true);

    final result = await VersionManager().checkWithResult(
      force: true,
      source: VersionCheckSource.manualLogin,
    );
    if (!mounted) return;
    setState(() => _isCheckingVersion = false);

    switch (result.status) {
      case VersionCheckStatus.hasUpdate:
        UpdateDialog.show(
          context,
          version: result.latestVersion,
          releaseNotes: result.releaseNotes,
          downloadUrl: result.downloadUrl,
        );
        break;
      case VersionCheckStatus.upToDate:
        await showVersionCheckMessage(
          context,
          title: '版本检查',
          message: result.message,
        );
        break;
      case VersionCheckStatus.networkError:
        await showVersionCheckMessage(
          context,
          title: '检查失败',
          message: result.message,
        );
        break;
      case VersionCheckStatus.idle:
      case VersionCheckStatus.checking:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = settings.isDarkMode;
    final hasNewVersion = context.watch<VersionManager>().hasNewVersion;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.article_outlined,
              color: AppColors.textPrimary(isDark).withValues(alpha: 0.8),
            ),
            onPressed: () => openSdkLogPage(context),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: _isCheckingVersion
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textPrimary(
                            isDark,
                          ).withValues(alpha: 0.8),
                        ),
                      )
                    : Icon(
                        Icons.system_update_alt_outlined,
                        color: AppColors.textPrimary(
                          isDark,
                        ).withValues(alpha: 0.8),
                      ),
                onPressed: _isCheckingVersion ? null : _handleCheckVersion,
                tooltip: '检查更新',
              ),
              if (hasNewVersion)
                const Positioned(
                  right: 10,
                  top: 10,
                  child: CircleAvatar(radius: 4, backgroundColor: Colors.red),
                ),
            ],
          ),
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
                  child: Form(
                    key: _formKey,
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
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            '环境: ${settings.activeEnvName}\nAppKey: ${settings.appKey}\n链接方式: ${settings.isMsync ? 'TCP' : 'WebSocket'}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary(isDark),
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

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
                                onPressed: () {
                                  if (_formKey.currentState?.validate() !=
                                      true) {
                                    return;
                                  }
                                  handleLogin();
                                },
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
      child: TextFormField(
        controller: controller,
        obscureText: isObscured,
        textInputAction: textInputAction,
        style: TextStyle(color: AppColors.textPrimary(isDark)),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '请输入$hintText';
          }
          return null;
        },
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
