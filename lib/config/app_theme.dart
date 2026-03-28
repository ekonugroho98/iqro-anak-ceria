import 'package:flutter/material.dart';

class AppTheme {
  // Warna per jilid Iqro
  static const Color jilid1 = Color(0xFF4CAF50);
  static const Color jilid2 = Color(0xFF2196F3);
  static const Color jilid3 = Color(0xFFFFC107);
  static const Color jilid4 = Color(0xFFFF9800);
  static const Color jilid5 = Color(0xFF9C27B0);
  static const Color jilid6 = Color(0xFFE91E63);

  // Warna umum
  static const Color primary = Color(0xFF00897B);
  static const Color secondary = Color(0xFFFFB300);
  static const Color background = Color(0xFFFFF8E1);
  static const Color surface = Colors.white;
  static const Color correct = Color(0xFF4CAF50);
  static const Color incorrect = Color(0xFFEF5350);
  static const Color premium = Color(0xFFFFD700);

  static List<Color> jilidColors = [
    jilid1, jilid2, jilid3, jilid4, jilid5, jilid6,
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}