import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/location_service.dart';
import '../../../services/sensor_service.dart';
import '../../../repositories/trip_repository.dart';
import '../../../helpers/permission_helper.dart';
import '../model/trip_model.dart';
import 'package:latlong2/latlong.dart';

class TripViewModel extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final SensorService _sensorService = SensorService();

  bool _isRecording = false;
  TripModel? _currentTrip;
  
  Position? _currentPosition;
  double _currentSpeed = 0.0;
  
  StreamSubscription<Position>? _locationSub;
  Timer? _durationTimer;
  Duration _tripDuration = Duration.zero;
  final List<LatLng> _routePath = [];

  bool get isRecording => _isRecording;
  TripModel? get currentTrip => _currentTrip;
  Position? get currentPosition => _currentPosition;
  double get currentSpeed => _currentSpeed; // m/s
  Duration get tripDuration => _tripDuration;
  List<LatLng> get routePath => _routePath;

  Future<void> startTrip() async {
    bool hasPermission = await PermissionHelper.requestLocationPermission();
    if (!hasPermission) {
      return; // Stop if permissions are completely denied
    }

    _isRecording = true;
    _tripDuration = Duration.zero;
    _routePath.clear();
    _currentTrip = TripModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(),
    );
    
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tripDuration = DateTime.now().difference(_currentTrip!.startTime);
      notifyListeners();
    });
    
    // Start GPS Tracking
    _locationSub = _locationService.startTracking().listen((Position position) {
      final currentLatLng = LatLng(position.latitude, position.longitude);
      _routePath.add(currentLatLng);
      if (_currentPosition != null) {
        final distance = Geolocator.distanceBetween(
          _currentPosition!.latitude, 
          _currentPosition!.longitude, 
          position.latitude, 
          position.longitude
        );
        final newDistance = (_currentTrip?.distanceInMeters ?? 0.0) + distance;
        _currentTrip = _currentTrip?.copyWith(distanceInMeters: newDistance);
      }
      
      _currentPosition = position;
      _currentSpeed = position.speed; // speed provided by Geolocator in m/s
      
      // Update top speed dynamically
      if (_currentSpeed > (_currentTrip?.topSpeed ?? 0)) {
        _currentTrip = _currentTrip?.copyWith(topSpeed: _currentSpeed);
      }
      
      notifyListeners();
    }, onError: (e) {
      // Handle stream errors silently
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
    
    // Convert LatLng back to string format for offline storage
    final List<String> encodedPath = _routePath.map((e) => '${e.latitude},${e.longitude}').toList();
    
    _currentTrip = _currentTrip?.copyWith(
      endTime: DateTime.now(),
      routePath: encodedPath,
    );
    
    _durationTimer?.cancel();
    _locationSub?.cancel();
    _sensorService.stopListening();
    
    if (_currentTrip != null) {
      TripRepository.instance.saveTrip(_currentTrip!);
    }
    
    notifyListeners();
  }
  
  @override
  void dispose() {
    _durationTimer?.cancel();
    _locationSub?.cancel();
    _sensorService.stopListening();
    super.dispose();
  }
}
