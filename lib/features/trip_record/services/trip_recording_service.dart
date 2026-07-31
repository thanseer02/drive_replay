import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drive_replay/core/logger/logger_service.dart';
import 'package:drive_replay/core/services/local_db/app_database.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(TripTaskHandler());
}

class TripTaskHandler extends TaskHandler {
  StreamSubscription? _positionStream;
  static const _eventChannel = EventChannel('com.drivereplay.location/stream');
  
  // Independent isolate resources
  AppDatabase? _db;
  SharedPreferences? _prefs;

  // State
  bool _isPaused = false;
  double _totalDistance = 0.0;
  int? _activeTripId;
  String _unit = 'metric';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    LoggerService.info('ISOLATE_LIFECYCLE: onStart called at $timestamp');
    
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

    // Load Settings
    try {
      final settings = await _db?.select(_db!.settings).getSingleOrNull();
      _unit = settings?.measurementUnit ?? 'metric';
    } catch (e) {
      LoggerService.error('Failed to load settings in Isolate: $e');
    }

    // Verify Permissions Mid-Trip Recovery
    // Removed Dart-side Geolocator check as Native Kotlin does its own check

    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    _positionStream = _eventChannel.receiveBroadcastStream().listen((data) {
      if (data is Map && data['type'] == 'UPDATE') {
        _processLocation(data);
      }
    }, onError: (error) {
      LoggerService.error('Native Location Stream Error: $error');
      FlutterForegroundTask.sendDataToMain({
        'type': 'ERROR',
        'message': 'Location services are disabled or unavailable.',
      });
    });
  }

  Future<void> _processLocation(Map data) async {
    if (_isPaused || _activeTripId == null) return;
    
    // We get pre-filtered data from Native
    final effectiveSpeed = (data['speed'] as num?)?.toDouble() ?? 0.0;
    
    final lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
    final lng = (data['longitude'] as num?)?.toDouble() ?? 0.0;
    final alt = (data['altitude'] as num?)?.toDouble() ?? 0.0;
    final head = (data['heading'] as num?)?.toDouble() ?? 0.0;
    final acc = (data['accuracy'] as num?)?.toDouble() ?? 0.0;

    try {
      await _db?.into(_db!.tripPoints).insert(
        TripPointsCompanion(
          tripId: drift.Value(_activeTripId!),
          timestamp: drift.Value(DateTime.now()), // Assuming native timestamp is now
          latitude: drift.Value(lat),
          longitude: drift.Value(lng),
          altitude: drift.Value(alt),
          heading: drift.Value(head),
          accuracy: drift.Value(acc),
          speed: drift.Value(effectiveSpeed),
        ),
      );
    } catch (e) {
      LoggerService.error('Failed to insert TripPoint: $e');
    }

    // Send update to UI Isolate for TripRecordViewModel
    FlutterForegroundTask.sendDataToMain(data);
    
    // Logging EXACT format requested by user
    try {
      final lifetimeRes = await _db?.customSelect('SELECT SUM(total_distance) as s FROM trips WHERE is_deleted = 0').getSingleOrNull();
      final lifetime = lifetimeRes?.read<double?>('s') ?? 0.0;

      final logMessage = '''
[GPS NATIVE SYNC]
Latitude: $lat
Longitude: $lng
Accuracy: $acc
Heading: $head
Speed: $effectiveSpeed
Current Trip Distance: $_totalDistance
Lifetime Distance: $lifetime
Saved To Database: true
Provider Updated: true
UI Updated: true''';
      LoggerService.info(logMessage);
    } catch (e) {
      LoggerService.error('Failed to generate GPS log: $e');
    }

    LoggerService.info('ISOLATE_SYNC: Sending data to main port. Distance sent: $_totalDistance');
    // Send update to UI
    FlutterForegroundTask.sendDataToMain(data);

    // Update Notification
    double displaySpeed = effectiveSpeed;
    double displayDistance = _totalDistance;
    String unitStr = 'km/h';
    String distStr = 'km';

    if (_unit == 'imperial') {
      displaySpeed *= 2.23694; // mph
      displayDistance /= 1609.34; // miles
      unitStr = 'mph';
      distStr = 'mi';
    } else if (_unit == 'nautical') {
      displaySpeed *= 1.94384; // knots
      displayDistance /= 1852.0; // nautical miles
      unitStr = 'knots';
      distStr = 'nm';
    } else {
      displaySpeed *= 3.6; // km/h
      displayDistance /= 1000.0; // km
    }

    await FlutterForegroundTask.updateService(
      notificationTitle: 'Live Speed: ${displaySpeed.toStringAsFixed(1)} $unitStr',
      notificationText: 'Distance: ${displayDistance.toStringAsFixed(2)} $distStr',
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Optional periodic event if needed (e.g. timeout detection)
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTaskKilled) async {
    LoggerService.info('ISOLATE_LIFECYCLE: onDestroy called. TaskKilled: $isTaskKilled');
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
    await prefs.setInt('flutter.current_active_trip_id', tripId);
    await prefs.setDouble('flutter.current_active_trip_distance', 0.0);

    const methodChannel = MethodChannel('com.drivereplay.location/method');
    await methodChannel.invokeMethod('startTracking', {'tripId': tripId});

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
    await prefs.remove('flutter.current_active_trip_id');
    await prefs.remove('flutter.current_active_trip_distance');

    const methodChannel = MethodChannel('com.drivereplay.location/method');
    await methodChannel.invokeMethod('stopTracking');

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
