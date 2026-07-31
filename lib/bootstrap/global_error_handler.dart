import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:drive_replay/core/logger/logger_service.dart';

class GlobalErrorHandler {
  static void initialize() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      LoggerService.critical('Flutter Error: ${details.exception}', details.exception, details.stack);
      
      // Pass to standard error reporting if needed
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
    };

    // Handle platform channel errors
    PlatformDispatcher.instance.onError = (error, stack) {
      if (error is PlatformException) {
        LoggerService.error('Platform Exception: ${error.message}', error, stack);
      } else {
        LoggerService.critical('Platform Dispatcher Error: $error', error, stack);
      }
      return true; // Prevents default crash handling
    };
  }
}
