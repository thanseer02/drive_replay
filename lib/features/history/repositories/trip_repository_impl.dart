import 'dart:io';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drive_replay/core/services/local_db/app_database.dart';
import 'package:drive_replay/features/trip_record/repositories/trip_repository.dart';

class TripRepositoryImpl implements TripRepository {
  final AppDatabase _db;

  TripRepositoryImpl(this._db);

  @override
  Future<int> startTrip(Trip trip) async {
    return await _db.into(_db.trips).insert(
      TripsCompanion(
        vehicleId: Value(trip.vehicleId),
        startTime: Value(trip.startTime),
      ),
    );
  }

  @override
  Future<void> endTrip(int tripId, DateTime endTime, double distance) async {
    await (_db.update(_db.trips)..where((t) => t.id.equals(tripId))).write(
      TripsCompanion(
        endTime: Value(endTime),
        totalDistance: Value(distance),
        status: const Value('Completed'),
      ),
    );
  }

  @override
  Future<List<Trip>> getTripHistory({
    required int vehicleId,
    required int limit,
    required int offset,
    String? searchQuery,
    bool favoritesOnly = false,
  }) async {
    final query = _db.select(_db.trips)
      ..where((t) => t.isDeleted.equals(false))
      ..where((t) => t.vehicleId.equals(vehicleId));

    if (favoritesOnly) {
      query.where((t) => t.isFavorite.equals(true));
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query.where((t) => 
        t.startLocation.like('%$searchQuery%') | 
        t.endLocation.like('%$searchQuery%')
      );
    }

    query.orderBy([(t) => OrderingTerm(expression: t.startTime, mode: OrderingMode.desc)]);
    query.limit(limit, offset: offset);

    return await query.get();
  }

  @override
  Future<Trip?> getTripDetails(int tripId) async {
    return await (_db.select(_db.trips)..where((t) => t.id.equals(tripId))).getSingleOrNull();
  }

  @override
  Future<void> toggleFavorite(int tripId) async {
    final trip = await getTripDetails(tripId);
    if (trip != null) {
      await (_db.update(_db.trips)..where((t) => t.id.equals(tripId))).write(
        TripsCompanion(isFavorite: Value(!trip.isFavorite)),
      );
    }
  }

  @override
  Future<void> softDeleteTrip(int tripId) async {
    await (_db.update(_db.trips)..where((t) => t.id.equals(tripId))).write(
      const TripsCompanion(isDeleted: Value(true)),
    );
  }

  @override
  Future<void> restoreTrip(int tripId) async {
    await (_db.update(_db.trips)..where((t) => t.id.equals(tripId))).write(
      const TripsCompanion(isDeleted: Value(false)),
    );
  }

  @override
  Future<String> exportTripCsv(int tripId) async {
    final points = await (_db.select(_db.tripPoints)..where((p) => p.tripId.equals(tripId))).get();
    
    final List<List<dynamic>> rows = [
      ['Timestamp', 'Latitude', 'Longitude', 'Altitude', 'Speed', 'Heading', 'Accuracy']
    ];

    for (var point in points) {
      rows.add([
        point.timestamp.toIso8601String(),
        point.latitude,
        point.longitude,
        point.altitude,
        '', // Speed
        point.heading,
        point.accuracy,
      ]);
    }

    final StringBuffer buffer = StringBuffer();
    for (var row in rows) {
      buffer.writeln(row.join(','));
    }
    final String csvData = buffer.toString();
    
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/trip_$tripId.csv');
    await file.writeAsString(csvData);
    return file.path;
  }
}
