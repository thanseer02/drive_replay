import 'package:drive_replay/core/services/local_db/app_database.dart';

abstract class TripRepository {
  Future<int> startTrip(Trip trip);
  Future<void> endTrip(int tripId, DateTime endTime, double distance);
  Future<List<Trip>> getTripHistory(int vehicleId, int limit, int offset);
  Future<Trip?> getTripDetails(int tripId);
}
