import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppThemeColors.pdfLight.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppThemeColors.pdfLight.primary,
      brightness: Brightness.light,
      surface: AppThemeColors.pdfLight.bg,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppThemeColors.pdfLight.bg,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppThemeColors.pdfLight.text),
      titleTextStyle: TextStyle(
        color: AppThemeColors.pdfLight.text,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppThemeColors.pdfLight.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppThemeColors.pdfLight.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppThemeColors.pdfDark.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppThemeColors.pdfDark.primary,
      brightness: Brightness.dark,
      surface: AppThemeColors.pdfDark.bg,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppThemeColors.pdfDark.bg,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppThemeColors.pdfDark.text),
      titleTextStyle: TextStyle(
        color: AppThemeColors.pdfDark.text,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppThemeColors.pdfDark.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppThemeColors.pdfDark.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
  );
}

@immutable
class AppColors {
  final Color primary;
  final Color bg;
  final Color text;
  final Color light;
  final Color card;
  final Color accent;
  final Color subtle;

  const AppColors({
    required this.primary,
    required this.bg,
    required this.text,
    required this.light,
    required this.card,
    required this.accent,
    required this.subtle,
  });

  /// Gradient for primary buttons / headers
  LinearGradient get primaryGradient => LinearGradient(
        colors: [primary, accent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

class AppThemeColors {
  /// 🔴 PDF LIGHT — Rich coral-red with warm cream background
  static const pdfLight = AppColors(
    primary: Color(0xFFE8453C),    // Vibrant coral-red (richer than before)
    accent: Color(0xFFFF7043),     // Warm orange accent for gradients
    bg: Color(0xFFFAF6F5),        // Warm cream white
    text: Color(0xFF1A1A2E),      // Deep navy-black (better contrast)
    light: Color(0xFFFFF0EE),     // Soft blush tint
    subtle: Color(0xFFF5E6E4),    // Muted rose for borders/dividers
    card: Colors.white,
  );

  /// 🔴 PDF DARK — Glowing coral on deep charcoal
  static const pdfDark = AppColors(
    primary: Color(0xFFFF6F61),    // Warm coral (softer glow on dark)
    accent: Color(0xFFFF8A65),     // Peachy orange accent
    bg: Color(0xFF0F0F14),        // Deep blue-black (richer than pure #121212)
    text: Color(0xFFF0EDED),      // Warm off-white (less harsh)
    light: Color(0x40FF6F61),     // Semi-transparent coral tint
    subtle: Color(0xFF1C1C26),    // Slightly lighter surface for borders
    card: Color(0xFF1A1A24),      // Blue-tinted dark card
  );

  /// 🔵 IMAGE LIGHT — Vivid sapphire blue with cool white
  static const imageLight = AppColors(
    primary: Color(0xFF3D7BF5),    // Richer sapphire blue
    accent: Color(0xFF42A5F5),     // Sky blue accent
    bg: Color(0xFFF3F7FD),        // Cool white with blue tint
    text: Color(0xFF1A1A2E),      // Deep navy-black
    light: Color(0xFFE3EDFF),     // Soft blue wash
    subtle: Color(0xFFD6E4FA),    // Muted blue for borders
    card: Colors.white,
  );

  /// 🔵 IMAGE DARK — Electric blue on deep charcoal
  static const imageDark = AppColors(
    primary: Color(0xFF5CA0FF),    // Bright electric blue
    accent: Color(0xFF82B1FF),     // Light blue accent
    bg: Color(0xFF0F0F14),        // Deep blue-black
    text: Color(0xFFF0EDED),      // Warm off-white
    light: Color(0x403D7BF5),     // Semi-transparent blue tint
    subtle: Color(0xFF1C1C26),    // Subtle dark border
    card: Color(0xFF1A1A24),      // Blue-tinted dark card
  );
}
