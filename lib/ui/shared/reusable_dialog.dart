import 'package:flutter/material.dart';
import 'package:drive_replay/core/theme/app_colors.dart';

class ReusableDialog {
  ReusableDialog._();

  static Future<void> showInfoDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(title, style: const TextStyle(color: AppColors.onSurface)),
          content: Text(message, style: const TextStyle(color: AppColors.onSurface)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onPressed != null) {
                  onPressed();
                }
              },
              child: Text(buttonText, style: const TextStyle(color: AppColors.primary)),
            ),
          ],
        );
      },
    );
  }
}
