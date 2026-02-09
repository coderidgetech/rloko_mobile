import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens from frontend theme.css: primary #B4770E, foreground #1A1A1A, etc.
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFFB4770E);
  static const Color primaryForeground = Colors.white;
  static const Color secondary = Color(0xFFF1B041);
  static const Color secondaryForeground = Color(0xFF1A1A1A);
  static const Color foreground = Color(0xFF1A1A1A);
  static const Color background = Colors.white;
  static const Color muted = Color(0xFFF5F5F5);
  static const Color mutedForeground = Color(0xFF666666);
  static const Color destructive = Color(0xFFd4183d);
  static const Color border = Color(0x1A1A1A1A); // rgba(26,26,26,0.1)
  static const double radius = 10.0; // 0.625rem ≈ 10

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: primaryForeground,
        secondary: secondary,
        onSecondary: secondaryForeground,
        surface: background,
        onSurface: foreground,
        error: destructive,
        onError: Colors.white,
        outline: border,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: foreground,
        displayColor: foreground,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: primaryForeground,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius * 4),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius * 4),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
