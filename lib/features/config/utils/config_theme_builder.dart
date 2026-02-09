import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../domain/entities/site_config.dart';

/// Builds Flutter ThemeData from design config (matching web app CSS variables).
class ConfigThemeBuilder {
  ConfigThemeBuilder._();

  static Color _parseColor(String hex) {
    final s = hex.replaceAll('#', '');
    if (s.length == 6) {
      return Color(int.parse('FF$s', radix: 16));
    }
    if (s.length == 8) {
      return Color(int.parse(s, radix: 16));
    }
    return const Color(0xFFB4770E);
  }

  static double _parseBorderRadius(String value) {
    final n = double.tryParse(value);
    return n ?? 0;
  }

  static double _parseFontSize(String value) {
    final n = double.tryParse(value);
    return n ?? 16;
  }

  static double _parseLineHeight(String value) {
    final n = double.tryParse(value);
    return n ?? 1.5;
  }

  static TextTheme _textTheme(DesignTypographyConfig typo, Color foreground) {
    final baseSize = _parseFontSize(typo.baseFontSize);
    final lineHeight = _parseLineHeight(typo.lineHeight);
    final bodyFont = typo.bodyFont == 'Inter' ? GoogleFonts.inter() : TextStyle(fontFamily: typo.bodyFont);
    final headingFont = typo.headingFont == 'Inter' ? GoogleFonts.inter() : TextStyle(fontFamily: typo.headingFont);

    return TextTheme(
      displayLarge: headingFont.copyWith(fontSize: baseSize * 2.5, height: lineHeight, color: foreground),
      displayMedium: headingFont.copyWith(fontSize: baseSize * 2.0, height: lineHeight, color: foreground),
      displaySmall: headingFont.copyWith(fontSize: baseSize * 1.75, height: lineHeight, color: foreground),
      headlineLarge: headingFont.copyWith(fontSize: baseSize * 1.5, height: lineHeight, color: foreground),
      headlineMedium: headingFont.copyWith(fontSize: baseSize * 1.25, height: lineHeight, color: foreground),
      headlineSmall: headingFont.copyWith(fontSize: baseSize * 1.125, height: lineHeight, color: foreground),
      titleLarge: headingFont.copyWith(fontSize: baseSize * 1.0, height: lineHeight, color: foreground),
      titleMedium: bodyFont.copyWith(fontSize: baseSize * 0.9, height: lineHeight, color: foreground),
      titleSmall: bodyFont.copyWith(fontSize: baseSize * 0.8, height: lineHeight, color: foreground),
      bodyLarge: bodyFont.copyWith(fontSize: baseSize, height: lineHeight, color: foreground),
      bodyMedium: bodyFont.copyWith(fontSize: baseSize * 0.875, height: lineHeight, color: foreground),
      bodySmall: bodyFont.copyWith(fontSize: baseSize * 0.75, height: lineHeight, color: foreground),
      labelLarge: bodyFont.copyWith(fontSize: baseSize * 0.875, height: lineHeight, color: foreground),
      labelMedium: bodyFont.copyWith(fontSize: baseSize * 0.75, height: lineHeight, color: foreground),
      labelSmall: bodyFont.copyWith(fontSize: baseSize * 0.625, height: lineHeight, color: foreground),
    );
  }

  static ThemeData build(DesignConfig design) {
    final colors = design.colors;
    final typo = design.typography;
    final layout = design.layout;

    final primary = _parseColor(colors.primary);
    final primaryLight = _parseColor(colors.primaryLight);
    final primaryDark = _parseColor(colors.primaryDark);
    final secondary = _parseColor(colors.secondary);
    final dominant = _parseColor(colors.dominant);
    final dominantOffWhite = _parseColor(colors.dominantOffWhite);
    final foreground = _parseColor(colors.secondary);
    final radius = _parseBorderRadius(layout.borderRadius);
    const destructive = Color(0xFFd4183d);

    final extension = RlocoThemeExtension(
      primary: primary,
      primaryForeground: Colors.white,
      secondary: secondary,
      foreground: foreground,
      background: dominant,
      muted: dominantOffWhite,
      mutedForeground: _parseColor(colors.secondaryGray),
      destructive: destructive,
      border: foreground.withValues(alpha: 0.1),
      radius: radius > 0 ? radius : 10,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primaryLight,
        secondary: secondary,
        onSecondary: Colors.white,
        surface: dominant,
        onSurface: foreground,
        surfaceContainerHighest: dominantOffWhite,
        error: destructive,
        onError: Colors.white,
        outline: foreground.withValues(alpha: 0.2),
      ),
      scaffoldBackgroundColor: dominant,
      textTheme: _textTheme(typo, foreground),
      appBarTheme: AppBarTheme(
        backgroundColor: dominant,
        foregroundColor: foreground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: (typo.headingFont == 'Inter' ? GoogleFonts.inter() : TextStyle(fontFamily: typo.headingFont)).copyWith(
          fontSize: _parseFontSize(typo.baseFontSize) * 1.125,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius > 0 ? radius : 40),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius > 0 ? radius : 40),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: BorderSide(color: foreground.withValues(alpha: 0.2)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius > 0 ? radius : 40),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dominantOffWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius > 0 ? radius : 10),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      extensions: [extension],
    );
  }
}
