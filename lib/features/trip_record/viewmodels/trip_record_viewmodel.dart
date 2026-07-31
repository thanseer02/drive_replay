
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:drive_replay/core/services/local_db/app_database.dart';
import 'package:drive_replay/core/domain/repositories/trip_repository.dart';
import 'package:drive_replay/features/trip_record/services/trip_recording_service.dart';
import 'package:drive_replay/core/logger/logger_service.dart';

enum TripState { idle, recording, paused }

class TripRecordViewModel extends ChangeNotifier {
  final TripRepository _repository;
  
  TripState _state = TripState.idle;
  double _currentSpeed = 0.0; // m/s
  double _totalDistance = 0.0; // meters
  int _elapsedSeconds = 0;
  int? _currentTripId;
  Timer? _timer;

  TripState get state => _state;
  double get currentSpeedKmh => _currentSpeed * 3.6;
  double get totalDistanceKm => _totalDistance / 1000.0;
  int get elapsedSeconds => _elapsedSeconds;
  
  String get formattedDuration {
    final minutes = (_elapsedSeconds / 60).floor();
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  TripRecordViewModel(this._repository) {
    _initForegroundTask();
  }

  void _initForegroundTask() {
    TripRecordingService.init();
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
  }

  void _onReceiveTaskData(Object data) {
    if (data is Map) {
      if (data['type'] == 'UPDATE') {
        _currentSpeed = (data['speed'] as num?)?.toDouble() ?? 0.0;
        _totalDistance = (data['distance'] as num?)?.toDouble() ?? 0.0;
        notifyListeners();
      }
    }
  }

  Future<void> startTrip() async {
    // 1. Create Trip in DB
    final newTrip = Trip(
      id: 0, // Ignored by Drift insert
      vehicleId: 1, // Default vehicle
      startTime: DateTime.now(),
      status: 'Recording',
      isFavorite: false,
      isDeleted: false,
      totalDistance: 0.0,
    );
    
    _currentTripId = await _repository.startTrip(newTrip);

    // 2. Start Background Service
    final started = await TripRecordingService.startService(_currentTripId!);
    if (started) {
      _state = TripState.recording;
      _currentSpeed = 0.0;
      _totalDistance = 0.0;
      _elapsedSeconds = 0;
      _startTimer();
      notifyListeners();
    } else {
      LoggerService.error('Failed to start Foreground Service');
    }
  }

  void pauseTrip() {
    TripRecordingService.pauseTrip();
    _stopTimer();
    _state = TripState.paused;
    _currentSpeed = 0.0; // Assume stopped
    notifyListeners();
  }

  void resumeTrip() {
    TripRecordingService.resumeTrip();
    _startTimer();
    _state = TripState.recording;
    notifyListeners();
  }

  Future<void> stopTrip() async {
    await TripRecordingService.stopService();
    _stopTimer();
    
    if (_currentTripId != null) {
      if (_totalDistance < 10.0) {
        // If they traveled less than 10 meters (basically 0 km/h the whole time), discard it.
        LoggerService.info('Trip $_currentTripId discarded: Distance was less than 10 meters.');
        await _repository.softDeleteTrip(_currentTripId!);
      } else {
        await _repository.endTrip(_currentTripId!, DateTime.now(), _totalDistance);
      }
    }
    
    _state = TripState.idle;
    _currentSpeed = 0.0;
    _currentTripId = null;
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }
  
  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
