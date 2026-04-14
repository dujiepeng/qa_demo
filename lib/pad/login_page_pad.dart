import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../common/widgets/common_gradient_background.dart';
import '../common/mixins/login_logic_mixin.dart';
import '../common/utils/version_manager.dart';
import '../common/widgets/log_page_launcher.dart';
import '../common/widgets/update_dialog.dart';
import '../common/widgets/version_check_feedback.dart';

class LoginPagePad extends StatefulWidget {
  const LoginPagePad({super.key});

  @override
  State<LoginPagePad> createState() => _LoginPagePadState();
}

class _LoginPagePadState extends State<LoginPagePad> with LoginLogicMixin {
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
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: CommonGradientBackground(
          isDark: isDark,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground(
                    isDark,
                  ).withValues(alpha: 0.8),
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            onPressed: _isCheckingVersion
                                ? null
                                : _handleCheckVersion,
                            tooltip: '检查更新',
                            icon: _isCheckingVersion
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.textPrimary(isDark),
                                    ),
                                  )
                                : Icon(
                                    Icons.system_update_alt_outlined,
                                    color: AppColors.textSecondary(isDark),
                                  ),
                          ),
                          if (hasNewVersion)
                            const Positioned(
                              right: 10,
                              top: 10,
                              child: CircleAvatar(
                                radius: 4,
                                backgroundColor: Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Form(
                      key: _formKey,
                      child: Column(
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
                          const SizedBox(height: 8),
                          Text(
                            '环境: ${settings.activeEnvName} \nAppKey: ${settings.appKey}\n链接方式: ${settings.isMsync ? 'TCP' : 'WebSocket'}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary(isDark),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildTextField(
                            uidController,
                            'UID',
                            Icons.person_outline,
                            isDark,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            pwdController,
                            'Password',
                            Icons.lock_outline,
                            isDark,
                            isObscured: true,
                          ),
                          const SizedBox(height: 40),
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
                                      vertical: 20,
                                    ),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () => openSdkLogPage(context),
                          icon: Icon(
                            Icons.article_outlined,
                            color: AppColors.textSecondary(isDark),
                            size: 20,
                          ),
                          label: Text(
                            '查看日志',
                            style: TextStyle(
                              color: AppColors.textSecondary(isDark),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        TextButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/server_config'),
                          icon: Icon(
                            Icons.settings_outlined,
                            color: AppColors.textSecondary(isDark),
                            size: 20,
                          ),
                          label: Text(
                            '服务器配置',
                            style: TextStyle(
                              color: AppColors.textSecondary(isDark),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
      child: TextFormField(
        controller: controller,
        obscureText: isObscured,
        style: TextStyle(color: AppColors.textPrimary(isDark)),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '请输入$hint';
          }
          return null;
        },
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
