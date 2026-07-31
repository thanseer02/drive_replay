import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:drive_replay/core/logger/app_logger.dart';

// Top level function required for flutter_foreground_task
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(TripTaskHandler());
}

class TripTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _positionStream;

  // State
  bool _isPaused = false;
  Position? _lastPosition;
  double _totalDistance = 0.0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    AppLogger.i('Foreground Service Started');
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2, // 2 meters to avoid noise
      ),
    ).listen((Position position) {
      _processLocation(position);
    });
  }

  void _processLocation(Position position) {
    if (_isPaused) return;
    
    // Ignore GPS noise (accuracy > 30 meters is usually bad)
    if (position.accuracy > 30) return;

    if (_lastPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      _totalDistance += distance;

      // Auto-stop logic placeholder based on speed over time
      if (position.speed > 1.0) {
        // moved
      }
    }

    _lastPosition = position;

    // TODO: Write point to Drift database here (requires initializing DB in this isolate)
    
    // Send update to UI
    FlutterForegroundTask.sendDataToMain({
      'type': 'UPDATE',
      'speed': position.speed,
      'distance': _totalDistance,
      'latitude': position.latitude,
      'longitude': position.longitude,
    });
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Optional periodic event if needed
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTaskKilled) async {
    AppLogger.i('Foreground Service Destroyed');
    await _positionStream?.cancel();
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map) {
      if (data['command'] == 'PAUSE') {
        _isPaused = true;
      } else if (data['command'] == 'RESUME') {
        _isPaused = false;
      }
    }
  }
}

class TripRecordingService {
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'trip_recording_channel',
        channelName: 'Trip Recording',
        channelDescription: 'Continuous location tracking for Drive Replay',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<bool> startService() async {
    if (await FlutterForegroundTask.isRunningService) return true;
    await FlutterForegroundTask.startService(
      notificationTitle: 'Drive Replay',
      notificationText: 'Recording your trip...',
      callback: startCallback,
    );
    return await FlutterForegroundTask.isRunningService;
  }

  static Future<bool> stopService() async {
    await FlutterForegroundTask.stopService();
    return !(await FlutterForegroundTask.isRunningService);
  }

  static void pauseTrip() {
    FlutterForegroundTask.sendDataToTask({'command': 'PAUSE'});
  }

  static void resumeTrip() {
    FlutterForegroundTask.sendDataToTask({'command': 'RESUME'});
  }
}
