import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService();

  /// Start a continuous stream of location updates.
  /// Used during active trip recording.
  Stream<Position> startTracking({
    LocationAccuracy accuracy = LocationAccuracy.bestForNavigation,
    int distanceFilter = 2, // update every 2 meters
  }) {
    final locationSettings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );
    
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Get a single, high-accuracy current position.
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
    } catch (e) {
      // TODO: Integrate LoggerHelper
      return null;
    }
  }

  /// Calculate distance between two coordinates in meters.
  double calculateDistance(
    double startLatitude, 
    double startLongitude, 
    double endLatitude, 
    double endLongitude
  ) {
    return Geolocator.distanceBetween(
      startLatitude, 
      startLongitude, 
      endLatitude, 
      endLongitude
    );
  }
}
