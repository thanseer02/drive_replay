import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error, critical }

class LoggerService {
  static bool _enabled = true;

  static void initialize({bool enableLogs = true}) {
    _enabled = enableLogs;
    info('LoggerService initialized. Logging enabled: $_enabled');
  }

  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  static void critical(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.critical, message, error, stackTrace);
  }

  static void _log(LogLevel level, String message, Object? error, StackTrace? stackTrace) {
    if (!_enabled && !kDebugMode) return;

    final now = DateTime.now();
    final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final levelString = level.name.toUpperCase();
    
    final formattedMessage = '[$timeString][$levelString] $message';

    if (kDebugMode) {
      // In debug mode, use standard print for easy console reading
      print(formattedMessage);
      if (error != null) print('Error: $error');
      if (stackTrace != null) print('Stacktrace:\n$stackTrace');
    } else {
      // In release mode, use developer.log if enabled (or send to crashlytics in real app)
      developer.log(
        message,
        time: now,
        level: _getDeveloperLevel(level),
        name: 'DriveReplay',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static int _getDeveloperLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug: return 500;
      case LogLevel.info: return 800;
      case LogLevel.warning: return 900;
      case LogLevel.error: return 1000;
      case LogLevel.critical: return 1200;
    }
  }
}
