import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryRed = Color(0xFFE50914);
  static const Color backgroundDark = Color(0xFF101216);
  static const Color surfaceDark = Color(0xFF181A20);
  static const Color cardDark = Color(0xFF1C1F26);
  static const Color textMuted = Color(0xFF757B88);

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: primaryRed,
      secondary: Color(0xFF00ADB5),
      surface: surfaceDark,
      onSurface: Color(0xFFEDEDED),
      onPrimary: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardDark,
      hintStyle: const TextStyle(color: textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
