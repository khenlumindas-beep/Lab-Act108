import 'package:flutter/material.dart';

class AppTheme {
  // Colors - Exact from CSUCC Logo & Portal Design
  static const Color primaryColor = Color(0xFF004D29); // Dark forest green from logo
  static const Color primaryLight = Color(0xFF006837); // Lighter green
  static const Color primaryDark = Color(0xFF003820); // Even darker green
  static const Color secondaryColor = Color(0xFFFBB040); // Golden/Amber from logo rays
  static const Color accentColor = Color(0xFF0066B3); // Blue from Cabadbaran seal
  static const Color dangerColor = Color(0xFFef4444);
  static const Color successColor = Color(0xFF10b981);
  static const Color warningColor = Color(0xFFFBB040);
  static const Color lightBg = Color(0xFFF5F7FA); // Light gray background
  static const Color benefitsBg = Color(0xFFE8F3F8); // Light blue for right panel
  static const Color darkBg = Color(0xFF1e293b);
  static const Color borderColor = Color(0xFFE0E4E8);
  static const Color textPrimary = Color(0xFF1F3B5C); // Dark blue-gray
  static const Color textSecondary = Color(0xFF6B7C93);
  static const Color textLight = Color(0xFF94a3b8);
  static const Color benefitCardBg1 = Color(0xFFD4EDE4); // Light green for Travel Records
  static const Color benefitCardBg2 = Color(0xFFFFF3CD); // Light yellow for Documents  
  static const Color benefitCardBg3 = Color(0xFFD9E8F7); // Light blue for AI Compliance
  static const Color goldenAccent = Color(0xFFFBB040); // Golden from logo
  static const Color logoGreen = Color(0xFF004D29); // Exact green from logo

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: lightBg,
      
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: dangerColor,
        surface: Colors.white,
      ),

      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        centerTitle: true,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: dangerColor),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textLight),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textLight,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: lightBg,
        selectedColor: primaryColor,
        labelStyle: const TextStyle(color: textPrimary),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBg,
      
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: dangerColor,
        surface: const Color(0xFF2e3b48),
      ),

      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Color(0xFF2e3b48),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2e3b48),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3f4d5a)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3f4d5a)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accentColor, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textLight),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textLight,
        ),
      ),
    );
  }
}
