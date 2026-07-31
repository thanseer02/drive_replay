import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drive_replay/core/services/local_db/app_database.dart';
import 'package:drive_replay/core/data/repositories/trip_repository_impl.dart';

void main() {
  late AppDatabase database;
  late TripRepositoryImpl repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = TripRepositoryImpl(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('TripRepositoryImpl Tests', () {
    test('startTrip creates a new trip successfully', () async {
      final trip = Trip(
        id: 1,
        vehicleId: 1,
        startTime: DateTime.now(),
        totalDistance: 0.0,
        status: 'Recording',
        isFavorite: false,
        isDeleted: false,
      );
      final tripId = await repository.startTrip(trip);
      expect(tripId, isPositive);
    });

    test('getOdometerTotal aggregates distances properly', () async {
      final trip = Trip(
        id: 2,
        vehicleId: 1,
        startTime: DateTime.now(),
        totalDistance: 0.0,
        status: 'Recording',
        isFavorite: false,
        isDeleted: false,
      );
      final tripId = await repository.startTrip(trip);
      
      await database.customStatement('UPDATE trips SET total_distance = 1500.5 WHERE id = $tripId');
      
      final total = await repository.getOdometerTotal(1);
      expect(total, 1500.5);
    });
  });
}
