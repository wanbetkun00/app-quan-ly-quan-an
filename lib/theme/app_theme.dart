import 'package:flutter/material.dart';

class AppTheme {
  // Màu chính: #f59b42 (cam/vàng cam)
  static const Color primaryOrange = Color(0xFFF59B42);
  // Màu chữ: #2d2d2d (xám đậm)
  static const Color darkGreyText = Color(0xFF2D2D2D);
  // Background: #F9F9F9 (xám nhạt)
  static const Color lightGreyBg = Color(0xFFF9F9F9);

  static const Color statusGreen = Color(0xFF4CAF50);
  static const Color statusRed = Color(0xFFE53935);
  static const Color statusYellow = Color(0xFFFFC107);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryOrange,
      primary: primaryOrange,
      background: lightGreyBg,
    ),
    scaffoldBackgroundColor: lightGreyBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: darkGreyText,
      elevation: 0.5,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: darkGreyText),
      titleMedium: TextStyle(color: darkGreyText, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(
        color: darkGreyText,
        fontWeight: FontWeight.w800,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}

