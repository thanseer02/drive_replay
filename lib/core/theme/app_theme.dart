import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:drive_replay/core/theme/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.onPrimary,
        onSecondary: AppColors.onSecondary,
        onTertiary: AppColors.onTertiary,
        onSurface: AppColors.onSurface,
        onError: AppColors.onError,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiary,
        surface: Colors.white,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onSurface: Colors.black87,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get tss120w900 => TextStyle(fontSize: 120.spMin, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0);
  static TextStyle get tss48w700 => TextStyle(fontSize: 48.spMin, fontWeight: FontWeight.bold, color: Colors.white);
  static TextStyle get tss36w700 => TextStyle(fontSize: 36.spMin, fontWeight: FontWeight.bold, color: Colors.white);
  static TextStyle get tss28w700 => TextStyle(fontSize: 28.spMin, fontWeight: FontWeight.bold, color: Colors.white);
  static TextStyle get tss24w700 => TextStyle(fontSize: 24.spMin, fontWeight: FontWeight.bold, color: Colors.white);
  static TextStyle get tss20w700 => TextStyle(fontSize: 20.spMin, fontWeight: FontWeight.bold, color: Colors.white);
  
  static TextStyle get tss18w700 => TextStyle(fontSize: 18.spMin, fontWeight: FontWeight.bold, color: Colors.white);
  static TextStyle get tss18w400 => TextStyle(fontSize: 18.spMin, fontWeight: FontWeight.w400, color: Colors.white);

  static TextStyle get tss16w700 => TextStyle(fontSize: 16.spMin, fontWeight: FontWeight.bold, color: Colors.white);
  static TextStyle get tss16w600 => TextStyle(fontSize: 16.spMin, fontWeight: FontWeight.w600, color: Colors.white);
  static TextStyle get tss16w400 => TextStyle(fontSize: 16.spMin, fontWeight: FontWeight.w400, color: Colors.white);

  static TextStyle get tss14w700 => TextStyle(fontSize: 14.spMin, fontWeight: FontWeight.bold, color: Colors.white);
  static TextStyle get tss14w500 => TextStyle(fontSize: 14.spMin, fontWeight: FontWeight.w500, color: Colors.white);
  static TextStyle get tss14w400 => TextStyle(fontSize: 14.spMin, fontWeight: FontWeight.w400, color: Colors.white);

  static TextStyle get tss12w700 => TextStyle(fontSize: 12.spMin, fontWeight: FontWeight.bold, color: Colors.white);
  static TextStyle get tss12w400 => TextStyle(fontSize: 12.spMin, fontWeight: FontWeight.w400, color: Colors.white);
}
