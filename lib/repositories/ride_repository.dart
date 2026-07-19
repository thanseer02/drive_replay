import 'package:drive_tracker/models/ride.dart';
import 'package:drive_tracker/models/ride_location.dart';
import 'package:drive_tracker/models/settings_model.dart';

abstract class RideRepository {
  Future<List<Ride>> getRides();
  Future<Ride?> getRide(int id);
  Future<int> addRide(Ride ride);
  Future<int> updateRide(Ride ride);
  Future<int> deleteRide(int id);
  Future<int> clearRides();

  Future<int> addRideLocation(RideLocation location);
  Future<List<RideLocation>> getLocationsForRide(int rideId);

  Future<SettingsModel> getSettings();
  Future<int> updateSettings(SettingsModel settings);
}
