import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../utils/version_manager.dart';

class UpdateDialog extends StatelessWidget {
  final String version;
  final String releaseNotes;
  final String downloadUrl;

  const UpdateDialog({
    super.key,
    required this.version,
    required this.releaseNotes,
    required this.downloadUrl,
  });

  static void show(BuildContext context) {
    if (!VersionManager().hasNewVersion) return;

    showDialog(
      context: context,
      builder: (context) => UpdateDialog(
        version: VersionManager().latestVersion,
        releaseNotes: VersionManager().releaseNotes,
        downloadUrl: VersionManager().downloadUrl,
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
          onPressed: () async {
            if (!Platform.isAndroid) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('只支持安卓系统')));
              return;
            }

            Navigator.of(context).pop();
            // final uri = Uri.parse(downloadUrl);
            final uri = Uri.parse(downloadUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: const Text('立即更新'),
        ),
      ],
    );
  }
}
