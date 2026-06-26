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
    final panelColor = _panelColor(isDark);
    final panelBorderColor = _panelBorderColor(isDark);

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
                  color: panelColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: panelBorderColor, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.38 : 0.16,
                      ),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
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
                        _buildActionButton(
                          onPressed: () => openSdkLogPage(context),
                          icon: Icons.article_outlined,
                          label: '查看日志',
                          color: _logActionColor(isDark),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 20),
                        _buildActionButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/server_config'),
                          icon: Icons.settings_outlined,
                          label: '服务器配置',
                          color: _configActionColor(isDark),
                          isDark: isDark,
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
        color: _fieldColor(isDark),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _fieldBorderColor(isDark)),
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

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: isDark ? 0.12 : 0.08),
        side: BorderSide(color: color.withValues(alpha: isDark ? 0.62 : 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Color _panelColor(bool isDark) =>
      isDark ? const Color(0xDD0B1220) : const Color(0xFFF7FAFF);

  Color _panelBorderColor(bool isDark) =>
      isDark ? const Color(0x665B7CFA) : const Color(0x553B5998);

  Color _fieldColor(bool isDark) =>
      isDark ? const Color(0x6618273A) : Colors.white;

  Color _fieldBorderColor(bool isDark) =>
      isDark ? const Color(0x445B7CFA) : const Color(0x223B5998);

  Color _logActionColor(bool isDark) =>
      isDark ? const Color(0xFF5BD6D6) : const Color(0xFF147C84);

  Color _configActionColor(bool isDark) =>
      isDark ? const Color(0xFF9AA7FF) : const Color(0xFF4358B8);
}
