import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'colors.dart';

class AppStyles {
  AppStyles._();

  // Naming format: tsS(fontSize)W(weight)C(color)
  
  static TextStyle get tsS24W700CFFFFFF => TextStyle(
        fontSize: 24.spMin,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get tsS20W600CFFFFFF => TextStyle(
        fontSize: 20.spMin,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get tsS16W600CFFFFFF => TextStyle(
        fontSize: 16.spMin,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get tsS16W400CFFFFFF => TextStyle(
        fontSize: 16.spMin,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get tsS14W400CFFFFFF => TextStyle(
        fontSize: 14.spMin,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get tsS14W400CB3B3B3 => TextStyle(
        fontSize: 14.spMin,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get tsS12W400C666666 => TextStyle(
        fontSize: 12.spMin,
        fontWeight: FontWeight.w400,
        color: AppColors.textDisabled,
      );

  static TextStyle get tsS32W700CFFFFFF => TextStyle(
        fontSize: 32.spMin,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );
      
  static TextStyle get tsS16W600CPrimary => TextStyle(
        fontSize: 16.spMin,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      );
}
