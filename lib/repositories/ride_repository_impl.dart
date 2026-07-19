import 'package:drive_tracker/database/db_helper.dart';
import 'package:drive_tracker/models/ride.dart';
import 'package:drive_tracker/models/ride_location.dart';
import 'package:drive_tracker/models/settings_model.dart';
import 'package:drive_tracker/repositories/ride_repository.dart';

class RideRepositoryImpl implements RideRepository {
  final DBHelper _dbHelper;

  RideRepositoryImpl(this._dbHelper);

  @override
  Future<List<Ride>> getRides() async {
    return await _dbHelper.getAllRides();
  }

  @override
  Future<Ride?> getRide(int id) async {
    return await _dbHelper.getRide(id);
  }

  @override
  Future<int> addRide(Ride ride) async {
    return await _dbHelper.insertRide(ride);
  }

  @override
  Future<int> updateRide(Ride ride) async {
    return await _dbHelper.updateRide(ride);
  }

  @override
  Future<int> deleteRide(int id) async {
    return await _dbHelper.deleteRide(id);
  }

  @override
  Future<int> clearRides() async {
    return await _dbHelper.clearAllRides();
  }

  @override
  Future<int> addRideLocation(RideLocation location) async {
    return await _dbHelper.insertRideLocation(location);
  }

  @override
  Future<List<RideLocation>> getLocationsForRide(int rideId) async {
    return await _dbHelper.getLocationsForRide(rideId);
  }

  @override
  Future<SettingsModel> getSettings() async {
    return await _dbHelper.getSettings();
  }

  @override
  Future<int> updateSettings(SettingsModel settings) async {
    return await _dbHelper.updateSettings(settings);
  }
}
