import 'package:flutter/material.dart';

class AppColors {
  // 深色模式配色
  static const Color darkBackgroundStart = Color(0xFF1A1A2E);
  static const Color darkBackgroundEnd = Color(0xFF16213E);
  static const Color darkPrimary = Color(0xFF0F3460);
  static const Color darkAccent = Color(0xFFE94560);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Colors.white70;
  static const Color darkInputBackground = Colors.white10;
  static const Color darkGlassBorder = Colors.white24;

  // 明亮模式配色
  static const Color lightBackgroundStart = Color(0xFFF0F2F5);
  static const Color lightBackgroundEnd = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF3B5998);
  static const Color lightAccent = Color(0xFF4A90E2);
  static const Color lightTextPrimary = Color(0xFF333333);
  static const Color lightTextSecondary = Color(0xFF666666);
  static const Color lightInputBackground = Colors.black12;
  static const Color lightGlassBorder = Colors.black26;

  // 根据当前设置获取颜色
  static Color backgroundStart(bool isDark) =>
      isDark ? darkBackgroundStart : lightBackgroundStart;
  static Color backgroundEnd(bool isDark) =>
      isDark ? darkBackgroundEnd : lightBackgroundEnd;
  static Color primary(bool isDark) =>
      isDark ? darkAccent : lightAccent; // 使用 Accent 作为主色
  static Color accent(bool isDark) => isDark ? darkAccent : lightAccent;
  static Color textPrimary(bool isDark) =>
      isDark ? darkTextPrimary : lightTextPrimary;
  static Color textSecondary(bool isDark) =>
      isDark ? darkTextSecondary : lightTextSecondary;
  static Color inputBackground(bool isDark) =>
      isDark ? darkInputBackground : lightInputBackground;
  static Color glassBorder(bool isDark) =>
      isDark ? darkGlassBorder : lightGlassBorder;
}
