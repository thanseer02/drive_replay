import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/location_service.dart';
import '../../../services/sensor_service.dart';
import '../../../repositories/trip_repository.dart';
import '../model/trip_model.dart';

class TripViewModel extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final SensorService _sensorService = SensorService();

  bool _isRecording = false;
  TripModel? _currentTrip;
  
  Position? _currentPosition;
  double _currentSpeed = 0.0;
  
  StreamSubscription<Position>? _locationSub;

  bool get isRecording => _isRecording;
  TripModel? get currentTrip => _currentTrip;
  Position? get currentPosition => _currentPosition;
  double get currentSpeed => _currentSpeed; // m/s

  void startTrip() {
    _isRecording = true;
    _currentTrip = TripModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(),
    );
    
    // Start GPS Tracking
    _locationSub = _locationService.startTracking().listen((Position position) {
      _currentPosition = position;
      _currentSpeed = position.speed; // speed provided by Geolocator in m/s
      
      // Update top speed dynamically
      if (_currentSpeed > (_currentTrip?.topSpeed ?? 0)) {
        _currentTrip = _currentTrip?.copyWith(topSpeed: _currentSpeed);
      }
      
      notifyListeners();
    });

    // Start Sensor Tracking for harsh events
    _sensorService.startListening(
      onAccelerometerEvent: (event) {
        // Detect harsh braking / acceleration logic will go here
      },
    );
    notifyListeners();
  }

  void stopTrip() {
    _isRecording = false;
    _currentTrip = _currentTrip?.copyWith(endTime: DateTime.now());
    
    _locationSub?.cancel();
    _sensorService.stopListening();
    
    if (_currentTrip != null) {
      TripRepository.instance.saveTrip(_currentTrip!);
    }
    
    notifyListeners();
  }
  
  @override
  void dispose() {
    _locationSub?.cancel();
    _sensorService.stopListening();
    super.dispose();
  }
}
