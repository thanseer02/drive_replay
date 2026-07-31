import 'package:drive_replay/core/services/local_db/app_database.dart';

abstract class TripRepository {
  Future<int> startTrip(Trip trip);
  Future<void> endTrip(int tripId, DateTime endTime, double distance);
  Future<List<Trip>> getTripHistory({
    required int vehicleId,
    required int limit,
    int? lastSeenId,
    String? searchQuery,
    bool favoritesOnly = false,
  });
  Future<Trip?> getTripDetails(int tripId);
  Future<void> toggleFavorite(int tripId);
  Future<void> softDeleteTrip(int tripId);
  Future<void> restoreTrip(int tripId);
  Future<String> exportTripCsv(int tripId);
  Future<List<TripPoint>> getTripPoints(int tripId);
}
