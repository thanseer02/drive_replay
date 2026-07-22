import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/log_entry.dart';

class LogService extends ChangeNotifier {
  static const int _maxLogs = 2000;
  final List<LogEntry> _logs = [];
  bool _isPaused = false;
  bool _verboseLogging = false;

  Timer? _watchdogTimer;
  DateTime? _lastGpsTime;
  bool _isTracking = false;

  static const EventChannel _rawEventsChannel = EventChannel('com.example.drivetracker/raw_events');
  StreamSubscription? _rawEventsSub;

  List<LogEntry> get logs => List.unmodifiable(_logs);
  bool get isPaused => _isPaused;
  bool get verboseLogging => _verboseLogging;

  LogService() {
    _startListening();
    _startWatchdog();
  }

  void _startListening() {
    _rawEventsSub = _rawEventsChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is Map) {
          final type = event['type'] as String?;
          final category = event['category'] as String? ?? 'NATIVE';
          final message = event['message'] as String? ?? '';
          final levelStr = event['level'] as String? ?? 'info';

          LogLevel level = LogLevel.info;
          if (levelStr == 'warning') level = LogLevel.warning;
          if (levelStr == 'error') level = LogLevel.error;

          if (type == 'gps' || type == 'sensor') {
            _lastGpsTime = DateTime.now();
          }

          if (category == 'ACCELEROMETER' && !_verboseLogging) return;

          addLog(category, message, level: level);
        }
      },
      onError: (err) {
        addLog('ERROR', 'Raw event channel error: $err', level: LogLevel.error);
      },
    );
  }

  void _startWatchdog() {
    _watchdogTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isTracking && _lastGpsTime != null) {
        final diff = DateTime.now().difference(_lastGpsTime!);
        if (diff.inSeconds >= 5 && diff.inSeconds % 5 == 0) {
          addLog('WARNING', 'GPS/Sensor callback not received for ${diff.inSeconds} seconds!', level: LogLevel.warning);
        }
      }
    });
  }

  void setTrackingState(bool isTracking) {
    _isTracking = isTracking;
    if (isTracking) {
      _lastGpsTime = DateTime.now();
    }
  }

  void addLog(String category, String message, {LogLevel level = LogLevel.info}) {
    if (_isPaused) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      category: category,
      message: message,
      level: level,
    );

    _logs.add(entry);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }
    notifyListeners();
  }

  void togglePause() {
    _isPaused = !_isPaused;
    notifyListeners();
  }

  void toggleVerbose() {
    _verboseLogging = !_verboseLogging;
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _rawEventsSub?.cancel();
    _watchdogTimer?.cancel();
    super.dispose();
  }
}
