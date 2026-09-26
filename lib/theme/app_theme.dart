import 'package:flutter/material.dart';

class AppTheme {
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.dark);

  static void toggleThemeMode() {
    themeModeNotifier.value = themeModeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  static bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  // Futuristic Dark Studio Palette
  static const Color bgDark = Color(0xFF0B0F19);
  static const Color bgCanvas = Color(0xFF0F172A);
  static const Color sidebarBg = Color(0xFF090D16);
  static const Color cardBg = Color(0xFF1E293B);
  static const Color cardBgTranslucent = Color(0xCC1E293B);

  // Light Studio Palette
  static const Color bgLight = Color(0xFFF1F5F9);
  static const Color bgCanvasLight = Color(0xFFF8FAFC);
  static const Color sidebarBgLight = Color(0xFFFFFFFF);
  static const Color cardBgLight = Color(0xFFFFFFFF);
  static const Color cardBgTranslucentLight = Color(0xEEFFFFFF);

  // Accents (constant across themes)
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color cyanGlow = Color(0xFF06B6D4);
  static const Color purpleGlow = Color(0xFF8B5CF6);
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color amberGold = Color(0xFFF59E0B);
  static const Color coralRose = Color(0xFFF43F5E);

  // Text colors
  static const Color textWhite = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textMutedLight = Color(0xFF475569);
  static const Color textSubtle = Color(0xFF64748B);

  // Border & Dividers
  static const Color borderColor = Color(0xFF334155);
  static const Color borderColorLight = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0x33F8FAFC);

  static ThemeData get darkStudioTheme {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: '.SF Pro Text',
      scaffoldBackgroundColor: bgDark,
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: cyanGlow,
        surface: bgCanvas,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardBg,
        contentTextStyle: const TextStyle(color: textWhite, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData get lightStudioTheme {
    return ThemeData(
      brightness: Brightness.light,
      fontFamily: '.SF Pro Text',
      scaffoldBackgroundColor: bgLight,
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: cyanGlow,
        surface: bgCanvasLight,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardBgLight,
        contentTextStyle: const TextStyle(color: textDark, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
