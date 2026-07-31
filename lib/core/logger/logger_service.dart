import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

enum LogLevel { debug, info, warning, error, critical }

class LoggerService {
  static bool _enabled = true;
  static File? _logFile;

  static Future<void> initialize({bool enableLogs = true}) async {
    _enabled = enableLogs;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      _logFile = File('${directory.path}/app_crashes_and_logs.txt');
      
      if (!await _logFile!.exists()) {
        await _logFile!.create();
      }
      info('LoggerService initialized. Logging to file: ${_logFile!.path}');
    } catch (e) {
      developer.log('Failed to initialize local log file: $e');
    }
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
    
    var formattedMessage = '[$timeString][$levelString] $message';
    if (error != null) formattedMessage += '\nError: $error';
    if (stackTrace != null) formattedMessage += '\nStacktrace:\n$stackTrace';

    if (kDebugMode) {
      // In debug mode, use standard print for easy console reading
      print(formattedMessage);
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

    // Always append crashes and errors to the local file for release mode debugging
    if (_logFile != null && (level == LogLevel.error || level == LogLevel.critical || !kDebugMode)) {
      try {
        _logFile!.writeAsStringSync('$formattedMessage\n\n', mode: FileMode.append);
      } catch (_) {
        // Silently fail if file system is locked to prevent crash loops
      }
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
