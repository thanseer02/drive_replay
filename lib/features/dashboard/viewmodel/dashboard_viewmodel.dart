import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:drive_tracker/core/di.dart';
import 'package:drive_tracker/models/ride.dart';
import 'package:drive_tracker/repositories/ride_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  final RideRepository _rideRepository = ServiceLocator.get<RideRepository>();

  // Native channels. Match MainActivity.kt strings.
  static const MethodChannel _controlChannel = MethodChannel('com.example.drivetracker/tracking_control');
  static const EventChannel _eventChannel = EventChannel('com.example.drivetracker/tracking_events');

  StreamSubscription? _trackingSubscription;

  List<Ride> _drives = [];
  bool _isLoading = false;

  // Active tracking state
  bool _isTracking = false;
  double _currentSpeed = 0.0;
  double _maxSpeed = 0.0;
  double _activeDistance = 0.0;
  double _heading = 0.0;
  double _altitude = 0.0;
  int _drivingTimeSeconds = 0;
  int _stoppedTimeSeconds = 0;

  List<Ride> get drives => _drives;
  bool get isLoading => _isLoading;

  // Telemetry getters
  bool get isTracking => _isTracking;
  double get currentSpeed => _currentSpeed;
  double get maxSpeed => _maxSpeed;
  double get activeDistance => _activeDistance;
  double get heading => _heading;
  double get altitude => _altitude;
  int get drivingTimeSeconds => _drivingTimeSeconds;
  int get stoppedTimeSeconds => _stoppedTimeSeconds;

  double get averageSpeed {
    final drivingHours = drivingTimeSeconds / 3600.0;
    if (drivingHours == 0.0) return 0.0;
    return _activeDistance / drivingHours;
  }

  // General historical metrics
  double get totalDistance => _drives.fold(0.0, (sum, drive) => sum + drive.distance);
  int get totalDurationSeconds => _drives.fold(0, (sum, drive) => sum + (drive.drivingTime + drive.stopTime));
  int get totalDrives => _drives.length;

  DashboardViewModel() {
    _checkServiceRunning();
  }

  Future<void> _checkServiceRunning() async {
    try {
      final Map? telemetry = await _controlChannel.invokeMapMethod('getTelemetry');
      if (telemetry != null && (telemetry['isTracking'] as bool? ?? false)) {
        _isTracking = true;
        _currentSpeed = (telemetry['currentSpeed'] as num? ?? 0.0).toDouble() * 3.6;
        _maxSpeed = (telemetry['maxSpeed'] as num? ?? 0.0).toDouble() * 3.6;
        _activeDistance = (telemetry['distance'] as num? ?? 0.0).toDouble() / 1000.0;
        _drivingTimeSeconds = telemetry['drivingTime'] as int? ?? 0;
        _stoppedTimeSeconds = telemetry['stopTime'] as int? ?? 0;

        _startListeningToChannel();
        notifyListeners();
      }
    } catch (_) {
      // Ignored
    }
  }

  Future<void> loadDashboardStats() async {
    _isLoading = true;
    notifyListeners();

    try {
      _drives = await _rideRepository.getRides();
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Active tracking native client commands
  Future<void> startTracking() async {
    if (_isTracking) return;
    try {
      await _controlChannel.invokeMethod('startTracking');
      _isTracking = true;
      _currentSpeed = 0.0;
      _maxSpeed = 0.0;
      _activeDistance = 0.0;
      _heading = 0.0;
      _altitude = 0.0;
      _drivingTimeSeconds = 0;
      _stoppedTimeSeconds = 0;

      _startListeningToChannel();
      notifyListeners();
    } catch (_) {
      // Handle error
    }
  }

  Future<Ride?> stopTracking(String startLoc, String endLoc) async {
    if (!_isTracking) return null;
    try {
      await _controlChannel.invokeMethod('stopTracking');
      
      final ride = Ride(
        startTime: DateTime.now().subtract(Duration(seconds: _drivingTimeSeconds + _stoppedTimeSeconds)),
        endTime: DateTime.now(),
        maxSpeed: maxSpeed,
        averageSpeed: averageSpeed,
        distance: double.parse(_activeDistance.toStringAsFixed(2)),
        drivingTime: _drivingTimeSeconds,
        stopTime: _stoppedTimeSeconds,
        createdAt: DateTime.now(),
      );

      _isTracking = false;
      _currentSpeed = 0.0;
      notifyListeners();
      return ride;
    } catch (_) {
      return null;
    }
  }

  void _startListeningToChannel() {
    _trackingSubscription?.cancel();
    _trackingSubscription = _eventChannel.receiveBroadcastStream().listen(
      _onTrackingEvent,
      onError: (err) {
        // Stream listener warning handler
      },
    );
  }

  void _onTrackingEvent(dynamic event) {
    if (event is Map) {
      final type = event['type'];
      if (type == 'telemetry') {
        _currentSpeed = (event['currentSpeed'] as num).toDouble() * 3.6;
        _maxSpeed = (event['maxSpeed'] as num).toDouble() * 3.6;
        _activeDistance = (event['distance'] as num).toDouble() / 1000.0;
        _drivingTimeSeconds = event['drivingTime'] as int;
        _stoppedTimeSeconds = event['stopTime'] as int;
        _heading = (event['heading'] ?? 0.0 as num).toDouble();
        _altitude = (event['altitude'] ?? 0.0 as num).toDouble();
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
      // Catch exceptions on DB transaction failures
    } finally {
      await loadDashboardStats();
      notifyListeners();
    }
  }

  Future<void> addMockDrive(Ride ride) async {
    await _rideRepository.addRide(ride);
    await loadDashboardStats();
  }

  @override
  void dispose() {
    _trackingSubscription?.cancel();
    super.dispose();
  }
}
