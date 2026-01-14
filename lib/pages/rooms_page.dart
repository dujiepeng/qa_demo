import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RoomsPage extends StatelessWidget {
  final bool isDark;
  const RoomsPage({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '聊天室',
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
                Icons.meeting_room_outlined,
                size: 80,
                color: AppColors.primary(isDark).withOpacity(0.5),
              ),
              const SizedBox(height: 20),
              Text(
                '聊天室',
                style: TextStyle(
                  color: AppColors.textPrimary(isDark),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '热闹非凡，即将开启...',
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
