
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:drive_replay/features/trip_record/services/trip_recording_service.dart';
import 'package:drive_replay/core/logger/logger_service.dart';

enum TripState { idle, recording, paused }

class TripRecordViewModel extends ChangeNotifier {
  TripState _state = TripState.idle;
  double _currentSpeed = 0.0; // m/s
  double _totalDistance = 0.0; // meters

  TripState get state => _state;
  double get currentSpeedKmh => _currentSpeed * 3.6;
  double get totalDistanceKm => _totalDistance / 1000.0;

  TripRecordViewModel() {
    _initForegroundTask();
  }

  void _initForegroundTask() {
    TripRecordingService.init();
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
  }

  void _onReceiveTaskData(Object data) {
    if (data is Map) {
      if (data['type'] == 'UPDATE') {
        _currentSpeed = data['speed'] ?? 0.0;
        _totalDistance = data['distance'] ?? 0.0;
        notifyListeners();
      }
    }
  }

  Future<void> startTrip(int tripId) async {
    final started = await TripRecordingService.startService(tripId);
    if (started) {
      _state = TripState.recording;
      _currentSpeed = 0.0;
      _totalDistance = 0.0;
      notifyListeners();
    } else {
      LoggerService.error('Failed to start Foreground Service');
    }
  }

  void pauseTrip() {
    TripRecordingService.pauseTrip();
    _state = TripState.paused;
    _currentSpeed = 0.0; // Assume stopped
    notifyListeners();
  }

  void resumeTrip() {
    TripRecordingService.resumeTrip();
    _state = TripState.recording;
    notifyListeners();
  }

  Future<void> stopTrip() async {
    await TripRecordingService.stopService();
    _state = TripState.idle;
    _currentSpeed = 0.0;
    notifyListeners();
  }
}
