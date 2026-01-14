import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GroupsPage extends StatelessWidget {
  final bool isDark;
  const GroupsPage({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '群组',
          style: TextStyle(color: AppColors.textPrimary(isDark)),
        ),
        centerTitle: true,
      ),
      body: Container(
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.group_outlined,
                size: 80,
                color: AppColors.primary(isDark).withOpacity(0.5),
              ),
              const SizedBox(height: 20),
              Text(
                '群组列表',
                style: TextStyle(
                  color: AppColors.textPrimary(isDark),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '正在寻找战友...',
                style: TextStyle(
                  color: AppColors.textSecondary(isDark).withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
