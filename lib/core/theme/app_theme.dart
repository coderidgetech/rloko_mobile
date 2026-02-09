import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Theme extension for Rloco design tokens. Used when theme is built from config.
class RlocoThemeExtension extends ThemeExtension<RlocoThemeExtension> {
  const RlocoThemeExtension({
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.foreground,
    required this.background,
    required this.muted,
    required this.mutedForeground,
    required this.destructive,
    required this.border,
    required this.radius,
  });

  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color foreground;
  final Color background;
  final Color muted;
  final Color mutedForeground;
  final Color destructive;
  final Color border;
  final double radius;

  @override
  RlocoThemeExtension copyWith({
    Color? primary,
    Color? primaryForeground,
    Color? secondary,
    Color? foreground,
    Color? background,
    Color? muted,
    Color? mutedForeground,
    Color? destructive,
    Color? border,
    double? radius,
  }) {
    return RlocoThemeExtension(
      primary: primary ?? this.primary,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      secondary: secondary ?? this.secondary,
      foreground: foreground ?? this.foreground,
      background: background ?? this.background,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      destructive: destructive ?? this.destructive,
      border: border ?? this.border,
      radius: radius ?? this.radius,
    );
  }

  @override
  RlocoThemeExtension lerp(ThemeExtension<RlocoThemeExtension>? other, double t) {
    if (other is! RlocoThemeExtension) return this;
    return RlocoThemeExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryForeground: Color.lerp(primaryForeground, other.primaryForeground, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      background: Color.lerp(background, other.background, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      border: Color.lerp(border, other.border, t)!,
      radius: radius + (other.radius - radius) * t,
    );
  }
}

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

  /// React/Tailwind radii (pin-to-pin)
  static const double radius2xl = 16.0; // rounded-2xl
  static const double radius3xl = 24.0; // rounded-t-3xl
  static const double radiusFull = 9999.0; // rounded-full

  /// Typography tokens (React/Tailwind: text-xs 12px, text-sm 14px, text-base 16px, etc.)
  static const double fontSizeXs = 12;
  static const double fontSizeSm = 14;
  static const double fontSizeBase = 16;
  static const double fontSizeLg = 18;
  static const double fontSizeXl = 20;
  static const double fontSize2xl = 24;

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
      textTheme: GoogleFonts.interTextTheme().copyWith(
        bodySmall: GoogleFonts.inter(fontSize: fontSizeXs, color: foreground, fontWeight: FontWeight.w400),
        bodyMedium: GoogleFonts.inter(fontSize: fontSizeSm, color: foreground, fontWeight: FontWeight.w400),
        bodyLarge: GoogleFonts.inter(fontSize: fontSizeBase, color: foreground, fontWeight: FontWeight.w400),
        titleSmall: GoogleFonts.inter(fontSize: fontSizeSm, color: foreground, fontWeight: FontWeight.w500),
        titleMedium: GoogleFonts.inter(fontSize: fontSizeBase, color: foreground, fontWeight: FontWeight.w500),
        titleLarge: GoogleFonts.inter(fontSize: fontSizeLg, color: foreground, fontWeight: FontWeight.w500),
        headlineSmall: GoogleFonts.inter(fontSize: fontSizeLg, color: foreground, fontWeight: FontWeight.w600),
        headlineMedium: GoogleFonts.inter(fontSize: fontSizeXl, color: foreground, fontWeight: FontWeight.w600),
        headlineLarge: GoogleFonts.inter(fontSize: fontSize2xl, color: foreground, fontWeight: FontWeight.w600),
      ).apply(bodyColor: foreground, displayColor: foreground),
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

  /// Returns design tokens from theme extension if available (when using config-driven theme).
  static RlocoThemeExtension? of(BuildContext context) {
    return Theme.of(context).extension<RlocoThemeExtension>();
  }

  /// Primary color: from theme extension if config-driven, else static default.
  static Color primaryColor(BuildContext context) =>
      of(context)?.primary ?? primary;

  /// Primary foreground (on-primary) color: from theme extension if config-driven, else static default.
  static Color primaryForegroundColor(BuildContext context) =>
      of(context)?.primaryForeground ?? primaryForeground;

  /// Background color: from theme extension if config-driven, else static default.
  static Color backgroundColor(BuildContext context) =>
      of(context)?.background ?? background;

  /// Foreground color: from theme extension if config-driven, else static default.
  static Color foregroundColor(BuildContext context) =>
      of(context)?.foreground ?? foreground;

  /// Muted color: from theme extension if config-driven, else static default.
  static Color mutedColor(BuildContext context) =>
      of(context)?.muted ?? muted;

  /// Muted foreground color: from theme extension if config-driven, else static default.
  static Color mutedForegroundColor(BuildContext context) =>
      of(context)?.mutedForeground ?? mutedForeground;

  /// Border color: from theme extension if config-driven, else static default.
  static Color borderColor(BuildContext context) =>
      of(context)?.border ?? border;

  /// Border radius: from theme extension if config-driven, else static default.
  static double radiusValue(BuildContext context) =>
      of(context)?.radius ?? radius;
}
