import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:drive_tracker/core/di.dart';
import 'package:drive_tracker/models/drive.dart';
import 'package:drive_tracker/repositories/drive_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  final DriveRepository _driveRepository = ServiceLocator.get<DriveRepository>();

  List<Drive> _drives = [];
  bool _isLoading = false;

  // Active tracking state
  bool _isTracking = false;
  double _currentSpeed = 0.0;
  double _maxSpeed = 0.0;
  double _activeDistance = 0.0;
  int _drivingTimeSeconds = 0;
  int _stoppedTimeSeconds = 0;
  
  Timer? _ticker;
  final Random _random = Random();

  List<Drive> get drives => _drives;
  bool get isLoading => _isLoading;

  // Telemetry getters
  bool get isTracking => _isTracking;
  double get currentSpeed => _currentSpeed;
  double get maxSpeed => _maxSpeed;
  double get activeDistance => _activeDistance;
  int get drivingTimeSeconds => _drivingTimeSeconds;
  int get stoppedTimeSeconds => _stoppedTimeSeconds;

  double get averageSpeed {
    final totalHours = (drivingTimeSeconds + stoppedTimeSeconds) / 3600.0;
    if (totalHours == 0.0) return 0.0;
    return _activeDistance / totalHours;
  }

  // General historical metrics
  double get totalDistance => _drives.fold(0.0, (sum, drive) => sum + drive.distance);
  int get totalDurationSeconds => _drives.fold(0, (sum, drive) => sum + drive.durationSeconds);
  int get totalDrives => _drives.length;

  Future<void> loadDashboardStats() async {
    _isLoading = true;
    notifyListeners();

    try {
      _drives = await _driveRepository.getDrives();
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Active tracking simulation commands
  void startTracking() {
    if (_isTracking) return;
    _isTracking = true;
    _currentSpeed = 0.0;
    _maxSpeed = 0.0;
    _activeDistance = 0.0;
    _drivingTimeSeconds = 0;
    _stoppedTimeSeconds = 0;

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      _simulateTelemetryTick();
    });

    notifyListeners();
  }

  Future<Drive?> stopTracking(String startLoc, String endLoc) async {
    if (!_isTracking) return null;
    _isTracking = false;
    _ticker?.cancel();
    _currentSpeed = 0.0;

    // Build the finished drive
    final drive = Drive(
      startTime: DateTime.now().subtract(Duration(seconds: _drivingTimeSeconds + _stoppedTimeSeconds)),
      endTime: DateTime.now(),
      durationSeconds: _drivingTimeSeconds + _stoppedTimeSeconds,
      distance: double.parse(_activeDistance.toStringAsFixed(2)),
      startLocation: startLoc,
      endLocation: endLoc,
      notes: 'Logged ride: ${averageSpeed.toStringAsFixed(1)} avg speed, ${maxSpeed.toStringAsFixed(1)} max speed.',
    );

    // Save of the drive into DB
    await _driveRepository.addDrive(drive);
    await loadDashboardStats();
    
    notifyListeners();
    return drive;
  }

  void _simulateTelemetryTick() {
    // Under active simulation, speed fluctuates between 0 and 110 km/h
    // 10% chance of stopping, 90% of moving
    final double chance = _random.nextDouble();

    if (chance < 0.08) {
      _currentSpeed = 0.0;
    } else {
      // Randomly accelerate or decelerate
      if (_currentSpeed == 0.0) {
        _currentSpeed = 15.0 + _random.nextDouble() * 20.0;
      } else {
        final change = -15.0 + _random.nextDouble() * 32.0;
        _currentSpeed = (_currentSpeed + change).clamp(10.0, 115.0);
      }
    }

    if (_currentSpeed > 0.0) {
      _drivingTimeSeconds++;
      // Distance added per second: speed in km/h divided by 3600 (seconds in hour)
      _activeDistance += _currentSpeed / 3600.0;
      if (_currentSpeed > _maxSpeed) {
        _maxSpeed = _currentSpeed;
      }
    } else {
      _stoppedTimeSeconds++;
    }

    notifyListeners();
  }

  Future<void> addMockDrive(Drive drive) async {
    await _driveRepository.addDrive(drive);
    await loadDashboardStats();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
