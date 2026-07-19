import 'package:flutter_test/flutter_test.dart';
import 'package:drive_tracker/models/ride.dart';
import 'package:drive_tracker/models/ride_location.dart';

void main() {
  group('Ride Calculations and Serialization Tests', () {
    final startTime = DateTime(2026, 7, 19, 10, 0, 0);
    final endTime = DateTime(2026, 7, 19, 10, 45, 0);
    final createdAt = DateTime(2026, 7, 19, 10, 46, 0);

    test('Ride model property calculations', () {
      final ride = Ride(
        id: 1,
        startTime: startTime,
        endTime: endTime,
        maxSpeed: 82.5,
        averageSpeed: 54.2,
        distance: 12.8,
        drivingTime: 2000,
        stopTime: 700,
        createdAt: createdAt,
      );

      // Total duration calculations
      expect(ride.durationSeconds, 2700);
      expect(ride.duration, const Duration(seconds: 2700));

      // Info strings
      expect(ride.notes.contains('54.2 avg speed'), isTrue);
      expect(ride.notes.contains('82.5 max speed'), isTrue);
      expect(ride.startLocation, 'Drive Start');
      expect(ride.endLocation, 'Drive End');
    });

    test('Ride copyWith behavior', () {
      final ride = Ride(
        id: 1,
        startTime: startTime,
        endTime: endTime,
        maxSpeed: 80.0,
        averageSpeed: 50.0,
        distance: 10.0,
        drivingTime: 1800,
        stopTime: 600,
        createdAt: createdAt,
      );

      final updated = ride.copyWith(
        distance: 11.5,
        stopTime: 800,
      );

      expect(updated.id, 1);
      expect(updated.distance, 11.5);
      expect(updated.stopTime, 800);
      expect(updated.maxSpeed, 80.0);
    });

    test('Ride mapping serialization and deserialization', () {
      final ride = Ride(
        id: 10,
        startTime: startTime,
        endTime: endTime,
        maxSpeed: 100.0,
        averageSpeed: 60.0,
        distance: 25.0,
        drivingTime: 1500,
        stopTime: 500,
        createdAt: createdAt,
      );

      final map = ride.toMap();
      expect(map['id'], 10);
      expect(map['startTime'], startTime.toIso8601String());
      expect(map['maxSpeed'], 100.0);
      expect(map['distance'], 25.0);

      final restored = Ride.fromMap(map);
      expect(restored.id, 10);
      expect(restored.startTime, startTime);
      expect(restored.endTime, endTime);
      expect(restored.maxSpeed, 100.0);
      expect(restored.distance, 25.0);
      expect(restored.drivingTime, 1500);
      expect(restored.stopTime, 500);
    });
  });

  group('RideLocation Serialization Tests', () {
    test('RideLocation properties and serialization', () {
      final timestamp = DateTime(2026, 7, 19, 10, 5, 0);
      final location = RideLocation(
        id: 2,
        rideId: 1,
        latitude: 37.7749,
        longitude: -122.4194,
        speed: 15.6,
        accuracy: 4.8,
        heading: 180.0,
        altitude: 35.2,
        timestamp: timestamp,
      );

      final map = location.toMap();
      expect(map['id'], 2);
      expect(map['rideId'], 1);
      expect(map['latitude'], 37.7749);
      expect(map['timestamp'], timestamp.toIso8601String());

      final restored = RideLocation.fromMap(map);
      expect(restored.id, 2);
      expect(restored.rideId, 1);
      expect(restored.latitude, 37.7749);
      expect(restored.speed, 15.6);
      expect(restored.accuracy, 4.8);
      expect(restored.heading, 180.0);
      expect(restored.altitude, 35.2);
    });
  });
}
