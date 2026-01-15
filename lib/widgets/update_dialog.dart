import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../theme/app_colors.dart';
import '../utils/version_manager.dart';

class UpdateDialog extends StatelessWidget {
  final String version;
  final String releaseNotes;

  const UpdateDialog({
    super.key,
    required this.version,
    required this.releaseNotes,
  });

  static void show(BuildContext context) {
    if (!VersionManager().hasNewVersion) return;

    showDialog(
      context: context,
      builder: (context) => UpdateDialog(
        version: VersionManager().latestVersion,
        releaseNotes: VersionManager().releaseNotes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final settings = AppSettings();
    final isDark = false;

    return AlertDialog(
      backgroundColor: AppColors.backgroundEnd(isDark),
      title: Text(
        '发现新版本 $version',
        style: TextStyle(color: AppColors.textPrimary(isDark)),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: MarkdownBody(
            data: releaseNotes,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(color: AppColors.textPrimary(isDark)),
              listBullet: TextStyle(color: AppColors.textPrimary(isDark)),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('稍后'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            // TODO: 跳转到更新页面或下载链接
          },
          child: const Text('立即更新'),
        ),
      ],
    );
  }
}
