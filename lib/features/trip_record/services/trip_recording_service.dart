import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drive_replay/core/logger/logger_service.dart';
import 'package:drive_replay/core/services/local_db/app_database.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(TripTaskHandler());
}

class TripTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _positionStream;
  
  // Independent isolate resources
  AppDatabase? _db;
  SharedPreferences? _prefs;

  // State
  bool _isPaused = false;
  Position? _lastPosition;
  double _totalDistance = 0.0;
  int? _activeTripId;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    LoggerService.info('Foreground Service Started');
    
    // Initialize DB and Prefs in this isolate
    _db = AppDatabase();
    _prefs = await SharedPreferences.getInstance();
    
    // Recover state
    _activeTripId = _prefs?.getInt('current_active_trip_id');
    
    if (_activeTripId == null) {
      LoggerService.warning('No active trip found on start. Stopping service.');
      await FlutterForegroundTask.stopService();
      return;
    }
    
    // Resume distance if recovering
    _totalDistance = _prefs?.getDouble('current_active_trip_distance') ?? 0.0;

    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3, // 3 meters strictly to avoid battery drain
        timeLimit: Duration(seconds: 2), // Hardware goes to sleep between fetches
      ),
    ).listen((Position position) {
      _processLocation(position);
    });
  }

  Future<void> _processLocation(Position position) async {
    if (_isPaused || _activeTripId == null) return;
    
    // 1. Noise Filtering
    if (position.accuracy > 30) return;

    // 2. Duplicate Avoidance
    if (_lastPosition != null && _lastPosition!.timestamp == position.timestamp) {
      return; // Exact duplicate
    }

    if (_lastPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      _totalDistance += distance;
      
      // Persist distance incrementally so a crash won't lose it
      await _prefs?.setDouble('current_active_trip_distance', _totalDistance);
    }

    _lastPosition = position;

    // 3. Memory Leak Prevention (Write immediately, do not hold in memory)
    try {
      await _db?.into(_db!.tripPoints).insert(
        TripPointsCompanion(
          tripId: drift.Value(_activeTripId!),
          timestamp: drift.Value(position.timestamp),
          latitude: drift.Value(position.latitude),
          longitude: drift.Value(position.longitude),
          altitude: drift.Value(position.altitude),
          heading: drift.Value(position.heading),
          accuracy: drift.Value(position.accuracy),
        ),
      );
    } catch (e) {
      LoggerService.error('Failed to insert TripPoint: $e');
    }

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
    // Optional periodic event if needed (e.g. timeout detection)
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTaskKilled) async {
    LoggerService.info('Foreground Service Destroyed');
    await _positionStream?.cancel();
    if (_db != null) {
      await _db!.close();
    }
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

  static Future<bool> startService(int tripId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_active_trip_id', tripId);
    await prefs.setDouble('current_active_trip_distance', 0.0);

    if (await FlutterForegroundTask.isRunningService) return true;
    
    await FlutterForegroundTask.startService(
      notificationTitle: 'Drive Replay',
      notificationText: 'Recording your trip...',
      callback: startCallback,
    );
    return await FlutterForegroundTask.isRunningService;
  }

  static Future<bool> stopService() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_active_trip_id');
    await prefs.remove('current_active_trip_distance');

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
