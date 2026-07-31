import 'package:flutter/material.dart';
import 'package:drive_replay/core/logger/app_logger.dart';

class ErrorHandler {
  ErrorHandler._();

  static void handleError(dynamic error, [StackTrace? stackTrace]) {
    AppLogger.e('An error occurred', error, stackTrace);
    // Future enhancements: 
    // - Send error to crashlytics (if added later)
    // - Show a toast/snackbar globally if a GlobalKey<NavigatorState> is provided
  }

  static Widget buildErrorWidget(FlutterErrorDetails details) {
    AppLogger.e('Flutter Framework Error', details.exception, details.stack);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Oops! Something went wrong.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              details.exceptionAsString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
