import 'package:hive/hive.dart';
import '../features/trip_recording/model/trip_model.dart';

class TripRepository {
  static const String boxName = 'trips_box';
  
  TripRepository._();
  
  static final TripRepository instance = TripRepository._();

  Future<void> saveTrip(TripModel trip) async {
    final box = Hive.box<TripModel>(boxName);
    await box.put(trip.id, trip);
  }

  Future<List<TripModel>> getAllTrips() async {
    final box = Hive.box<TripModel>(boxName);
    final trips = box.values.toList();
    // Sort descending by start time (newest first)
    trips.sort((a, b) => b.startTime.compareTo(a.startTime));
    return trips;
  }

  Future<void> deleteTrip(String id) async {
    final box = Hive.box<TripModel>(boxName);
    await box.delete(id);
  }
}
