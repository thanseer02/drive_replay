import 'package:flutter/material.dart';
import 'package:drive_replay/core/theme/app_colors.dart';

class ReusableSnackbar {
  ReusableSnackbar._();

  static void show({
    required BuildContext context,
    required String message,
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError ? AppColors.onError : AppColors.onSurface,
          ),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
