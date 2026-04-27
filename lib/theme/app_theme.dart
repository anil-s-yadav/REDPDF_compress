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
      systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
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
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
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

  const AppColors({
    required this.primary,
    required this.bg,
    required this.text,
    required this.light,
    required this.card,
  });
}

class AppThemeColors {
  /// 🔴 PDF LIGHT
  static const pdfLight = AppColors(
    primary: Color(0xFFFF4E50),
    bg: Color(0xFFFFF5F5),
    text: Color(0xFF1E1E1E),
    light: Color(0xFFFFEAEA),
    card: Colors.white,
  );

  /// 🔴 PDF DARK
  static const pdfDark = AppColors(
    primary: Color(0xFFFF6B6D),
    bg: Color(0xFF121212),
    text: Colors.white,
    light: Color(0x33FF4E50),
    card: Color(0xFF1E1E1E),
  );

  /// 🔵 IMAGE LIGHT
  static const imageLight = AppColors(
    primary: Color(0xFF2F80ED),
    bg: Color(0xFFF5F9FF),
    text: Color(0xFF1C1C1E),
    light: Color(0xFFEAF2FF),
    card: Colors.white,
  );

  /// 🔵 IMAGE DARK
  static const imageDark = AppColors(
    primary: Color(0xFF4DA3FF),
    bg: Color(0xFF121212),
    text: Colors.white,
    light: Color(0x332F80ED),
    card: Color(0xFF1E1E1E),
  );
}
