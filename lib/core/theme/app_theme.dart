import 'package:flutter/material.dart';

class AppTheme {
  // Clean White & Blue Theme
  static const Color primaryBlue = Color(0xFF0066FF);
  static const Color lightBlueBackground = Color(0xFFF4F7FC);
  static const Color surfaceWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1F36);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBlueBackground,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: accentBlue,
        surface: surfaceWhite,
        error: dangerRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
        iconTheme: IconThemeData(color: primaryBlue),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.blue.withOpacity(0.1), width: 1),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textDark, fontFamily: 'Inter', fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: textDark, fontFamily: 'Inter', fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: textDark, fontFamily: 'Inter', fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: textDark, fontFamily: 'Inter', fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: textDark, fontFamily: 'Inter', fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: textDark, fontFamily: 'Inter', fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: textDark, fontFamily: 'Inter', fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: textDark, fontFamily: 'Inter', fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: textMuted, fontFamily: 'Inter', fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: textDark, fontFamily: 'Inter'),
        bodyMedium: TextStyle(color: textMuted, fontFamily: 'Inter'),
        bodySmall: TextStyle(color: textMuted, fontFamily: 'Inter'),
        labelLarge: TextStyle(color: primaryBlue, fontFamily: 'JetBrainsMono', fontWeight: FontWeight.bold),
        labelMedium: TextStyle(color: textDark, fontFamily: 'JetBrainsMono'),
        labelSmall: TextStyle(color: textMuted, fontFamily: 'JetBrainsMono'),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        labelStyle: const TextStyle(color: textMuted),
        hintStyle: TextStyle(color: textMuted.withOpacity(0.7)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
    );
  }
}
