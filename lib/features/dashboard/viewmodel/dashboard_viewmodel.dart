import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:drive_tracker/core/di.dart';
import 'package:drive_tracker/models/activity_model.dart';
import 'package:drive_tracker/repositories/activity_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  final ActivityRepository _activityRepository = ServiceLocator.get<ActivityRepository>();

  static const MethodChannel _controlChannel = MethodChannel('com.example.drivetracker/tracking_control');
  static const EventChannel _eventChannel = EventChannel('com.example.drivetracker/tracking_events');

  StreamSubscription? _trackingSubscription;

  List<ActivityModel> _activities = [];
  bool _isLoading = false;

  // Active tracking state
  bool _isTracking = false;
  String _activityType = 'driving';
  double _currentSpeed = 0.0;
  double _maxSpeed = 0.0;
  double _activeDistance = 0.0;
  double _acceleration = 0.0;
  double _heading = 0.0;
  double _altitude = 0.0;
  int _drivingTimeSeconds = 0;
  int _stoppedTimeSeconds = 0;
  int _steps = 0;
  double _calories = 0.0;
  double _pace = 0.0;
  double _cadence = 0.0;

  List<ActivityModel> get activities => _activities;
  bool get isLoading => _isLoading;

  bool get isTracking => _isTracking;
  String get activityType => _activityType;
  double get currentSpeed => _currentSpeed;
  double get maxSpeed => _maxSpeed;
  double get activeDistance => _activeDistance;
  double get acceleration => _acceleration;
  double get heading => _heading;
  double get altitude => _altitude;
  int get drivingTimeSeconds => _drivingTimeSeconds;
  int get stoppedTimeSeconds => _stoppedTimeSeconds;
  int get steps => _steps;
  double get calories => _calories;
  double get pace => _pace;
  double get cadence => _cadence;

  double get averageSpeed {
    final drivingHours = drivingTimeSeconds / 3600.0;
    if (drivingHours == 0.0) return 0.0;
    return _activeDistance / drivingHours;
  }

  double get totalDistance => _activities.fold(0.0, (sum, act) => sum + act.distance);
  int get totalDurationSeconds => _activities.fold(0, (sum, act) => sum + act.duration);
  int get totalActivities => _activities.length;

  DashboardViewModel() {
    _checkServiceRunning();
  }

  Future<void> _checkServiceRunning() async {
    try {
      final Map? telemetry = await _controlChannel.invokeMapMethod('getTelemetry');
      if (telemetry != null && (telemetry['isTracking'] as bool? ?? false)) {
        _isTracking = true;
        _activityType = telemetry['activityType'] as String? ?? 'driving';
        _currentSpeed = (telemetry['currentSpeed'] as num? ?? 0.0).toDouble() * 3.6; // Assuming Kotlin sends m/s
        _maxSpeed = (telemetry['maxSpeed'] as num? ?? 0.0).toDouble() * 3.6;
        _activeDistance = (telemetry['distance'] as num? ?? 0.0).toDouble() / 1000.0;
        _drivingTimeSeconds = telemetry['drivingTime'] as int? ?? 0;
        _stoppedTimeSeconds = telemetry['stopTime'] as int? ?? 0;
        _steps = telemetry['steps'] as int? ?? 0;
        _calories = (telemetry['calories'] as num? ?? 0.0).toDouble();
        _pace = (telemetry['pace'] as num? ?? 0.0).toDouble();
        _cadence = (telemetry['cadence'] as num? ?? 0.0).toDouble();

        _startListeningToChannel();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> loadDashboardStats() async {
    _isLoading = true;
    notifyListeners();

    try {
      _activities = await _activityRepository.getActivities();
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startTracking(String type) async {
    if (_isTracking) return;
    try {
      await _controlChannel.invokeMethod('startTracking', {'activityType': type});
      _isTracking = true;
      _activityType = type;
      _currentSpeed = 0.0;
      _maxSpeed = 0.0;
      _activeDistance = 0.0;
      _acceleration = 0.0;
      _heading = 0.0;
      _altitude = 0.0;
      _drivingTimeSeconds = 0;
      _stoppedTimeSeconds = 0;
      _steps = 0;
      _calories = 0.0;
      _pace = 0.0;
      _cadence = 0.0;

      _startListeningToChannel();
      notifyListeners();
    } catch (_) {}
  }

  Future<ActivityModel?> stopTracking() async {
    if (!_isTracking) return null;
    try {
      await _controlChannel.invokeMethod('stopTracking');
      
      final act = ActivityModel(
        activityType: _activityType,
        startTime: DateTime.now().subtract(Duration(seconds: _drivingTimeSeconds + _stoppedTimeSeconds)),
        endTime: DateTime.now(),
        maxSpeed: maxSpeed,
        averageSpeed: averageSpeed,
        distance: double.parse(_activeDistance.toStringAsFixed(2)),
        duration: _drivingTimeSeconds,
        stopTime: _stoppedTimeSeconds,
        steps: _steps,
        calories: _calories,
        pace: _pace,
        cadence: _cadence,
        createdAt: DateTime.now(),
      );

      _isTracking = false;
      _currentSpeed = 0.0;
      notifyListeners();
      return act;
    } catch (_) {
      return null;
    }
  }

  void _startListeningToChannel() {
    _trackingSubscription?.cancel();
    _trackingSubscription = _eventChannel.receiveBroadcastStream().listen(
      _onTrackingEvent,
      onError: (err) {},
    );
  }

  void _onTrackingEvent(dynamic event) {
    if (event is Map) {
      final type = event['type'];
      if (type == 'telemetry') {
        _activityType = event['activityType'] as String? ?? 'driving';
        _currentSpeed = (event['currentSpeed'] as num? ?? 0.0).toDouble() * 3.6;
        _maxSpeed = (event['maxSpeed'] as num? ?? 0.0).toDouble() * 3.6;
        _activeDistance = (event['distance'] as num? ?? 0.0).toDouble() / 1000.0;
        _acceleration = (event['acceleration'] ?? 0.0 as num).toDouble();
        _drivingTimeSeconds = event['drivingTime'] as int? ?? 0;
        _stoppedTimeSeconds = event['stopTime'] as int? ?? 0;
        _heading = (event['heading'] ?? 0.0 as num).toDouble();
        _altitude = (event['altitude'] ?? 0.0 as num).toDouble();
        _steps = event['steps'] as int? ?? 0;
        _calories = (event['calories'] as num? ?? 0.0).toDouble();
        _pace = (event['pace'] as num? ?? 0.0).toDouble();
        _cadence = (event['cadence'] as num? ?? 0.0).toDouble();
        notifyListeners();
      } else if (type == 'stopped') {
        _isTracking = false;
        _currentSpeed = 0.0;
        _trackingSubscription?.cancel();
        _trackingSubscription = null;

        _saveRideFromEvent(event);
      }
    }
  }

  Future<void> _saveRideFromEvent(Map event) async {
    try {
      // Telemetry metrics and locations are persisted directly in SQLite natively.
    } catch (_) {
    } finally {
      await loadDashboardStats();
      notifyListeners();
    }
  }

  Future<void> addMockDrive(ActivityModel act) async {
    await _activityRepository.addActivity(act);
    await loadDashboardStats();
  }

  @visibleForTesting
  void routeEventForTesting(dynamic event) {
    _onTrackingEvent(event);
  }

  @override
  void dispose() {
    _trackingSubscription?.cancel();
    super.dispose();
  }
}
