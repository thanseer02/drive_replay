import 'package:flutter_test/flutter_test.dart';
import 'package:drive_tracker/database/db_helper.dart';
import 'package:drive_tracker/models/ride.dart';
import 'package:drive_tracker/models/ride_location.dart';
import 'package:drive_tracker/models/settings_model.dart';
import 'package:drive_tracker/repositories/ride_repository_impl.dart';

// Fake implementations of DBHelper to execute inside unit-test environments without SQLite binary dependencies
class FakeDBHelper implements DBHelper {
  final List<Ride> rides = [];
  final List<RideLocation> locations = [];
  SettingsModel settings = SettingsModel(isDarkMode: false, useMetric: true);

  @override
  Future<int> insertRide(Ride ride) async {
    final newId = rides.length + 1;
    final toSave = ride.copyWith(id: newId);
    rides.add(toSave);
    return newId;
  }

  @override
  Future<int> updateRide(Ride ride) async {
    final index = rides.indexWhere((r) => r.id == ride.id);
    if (index == -1) return 0;
    rides[index] = ride;
    return 1;
  }

  @override
  Future<int> deleteRide(int id) async {
    final lengthBefore = rides.length;
    rides.removeWhere((r) => r.id == id);
    locations.removeWhere((l) => l.rideId == id);
    return lengthBefore - rides.length;
  }

  @override
  Future<List<Ride>> getAllRides() async {
    // Return sorted descending like SQL query
    final sorted = List<Ride>.from(rides);
    sorted.sort((a,b) => b.startTime.compareTo(a.startTime));
    return sorted;
  }

  @override
  Future<Ride?> getRide(int id) async {
    final index = rides.indexWhere((r) => r.id == id);
    if (index == -1) return null;
    final r = rides[index];
    final list = await getLocationsForRide(id);
    return r.copyWith(locations: list);
  }

  @override
  Future<int> clearAllRides() async {
    final count = rides.length;
    rides.clear();
    locations.clear();
    return count;
  }

  @override
  Future<int> insertRideLocation(RideLocation location) async {
    final newId = locations.length + 1;
    locations.add(RideLocation(
      id: newId,
      rideId: location.rideId,
      latitude: location.latitude,
      longitude: location.longitude,
      speed: location.speed,
      accuracy: location.accuracy,
      heading: location.heading,
      altitude: location.altitude,
      timestamp: location.timestamp,
    ));
    return newId;
  }

  @override
  Future<List<RideLocation>> getLocationsForRide(int rideId) async {
    return locations.where((l) => l.rideId == rideId).toList();
  }

  @override
  Future<SettingsModel> getSettings() async {
    return settings;
  }

  @override
  Future<int> updateSettings(SettingsModel settings) async {
    this.settings = settings;
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('SQLite Repository Tests', () {
    late FakeDBHelper fakeDb;
    late RideRepositoryImpl repository;

    setUp(() {
      fakeDb = FakeDBHelper();
      repository = RideRepositoryImpl(fakeDb);
    });

    test('Add and retrieve rides from repository', () async {
      final ride = Ride(
        startTime: DateTime(2026, 7, 19, 12, 0),
        maxSpeed: 60.0,
        averageSpeed: 45.0,
        distance: 8.5,
        drivingTime: 600,
        stopTime: 120,
        createdAt: DateTime(2026, 7, 19, 12, 15),
      );

      final id = await repository.addRide(ride);
      expect(id, 1);

      final all = await repository.getRides();
      expect(all.length, 1);
      expect(all.first.id, 1);
      expect(all.first.distance, 8.5);
    });

    test('Retrieve specific ride with location traces', () async {
      final ride = Ride(
        startTime: DateTime(2026, 7, 19, 12, 0),
        maxSpeed: 60.0,
        averageSpeed: 45.0,
        distance: 8.5,
        drivingTime: 600,
        stopTime: 120,
        createdAt: DateTime(2026, 7, 19, 12, 15),
      );

      await repository.addRide(ride);

      final loc1 = RideLocation(
        rideId: 1,
        latitude: 10.0,
        longitude: 20.0,
        speed: 10.0,
        accuracy: 2.0,
        heading: 0.0,
        altitude: 0.0,
        timestamp: DateTime(2026, 7, 19, 12, 1),
      );

      final loc2 = RideLocation(
        rideId: 1,
        latitude: 10.1,
        longitude: 20.1,
        speed: 15.0,
        accuracy: 2.2,
        heading: 90.0,
        altitude: 5.0,
        timestamp: DateTime(2026, 7, 19, 12, 2),
      );

      await repository.addRideLocation(loc1);
      await repository.addRideLocation(loc2);

      final savedRide = await repository.getRide(1);
      expect(savedRide, isNotNull);
      expect(savedRide!.locations, isNotNull);
      expect(savedRide.locations!.length, 2);
      expect(savedRide.locations!.first.latitude, 10.0);
    });

    test('Clear rides list or delete unique records', () async {
      final ride1 = Ride(
        startTime: DateTime(2026, 7, 19, 10, 0),
        maxSpeed: 50.0,
        averageSpeed: 40.0,
        distance: 5.0,
        drivingTime: 400,
        stopTime: 50,
        createdAt: DateTime(2026, 7, 19, 10, 10),
      );

      final ride2 = Ride(
        startTime: DateTime(2026, 7, 19, 11, 0),
        maxSpeed: 70.0,
        averageSpeed: 50.0,
        distance: 15.0,
        drivingTime: 1000,
        stopTime: 200,
        createdAt: DateTime(2026, 7, 19, 11, 20),
      );

      await repository.addRide(ride1);
      await repository.addRide(ride2);

      var list = await repository.getRides();
      expect(list.length, 2);

      await repository.deleteRide(1);
      list = await repository.getRides();
      expect(list.length, 1);
      expect(list.first.id, 2);

      await repository.clearRides();
      list = await repository.getRides();
      expect(list.isEmpty, isTrue);
    });

    test('Read and update SettingsModel configurations', () async {
      var current = await repository.getSettings();
      expect(current.useMetric, isTrue);

      await repository.updateSettings(SettingsModel(isDarkMode: true, useMetric: false));
      current = await repository.getSettings();
      expect(current.isDarkMode, isTrue);
      expect(current.useMetric, isFalse);
    });
  });
}
