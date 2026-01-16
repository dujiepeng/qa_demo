import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LogContentPage extends StatefulWidget {
  final String logPath;

  const LogContentPage({super.key, required this.logPath});

  @override
  State<LogContentPage> createState() => _LogContentPageState();
}

class _LogContentPageState extends State<LogContentPage> {
  String _content = 'Loading...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogContent();
  }

  Future<void> _loadLogContent() async {
    try {
      final file = File(widget.logPath);
      if (await file.exists()) {
        final content = await file.readAsString();
        if (mounted) {
          setState(() {
            _content = content;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _content = 'Log file not found at: ${widget.logPath}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _content = 'Error reading log file: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Content'),
        backgroundColor: AppColors.backgroundStart(isDark),
      ),
      backgroundColor: AppColors.backgroundStart(isDark),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: SelectableText(
                _content,
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 12,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
            ),
    );
  }
}
