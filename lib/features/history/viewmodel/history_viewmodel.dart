import 'package:flutter/material.dart';
import 'package:drive_tracker/core/di.dart';
import 'package:drive_tracker/models/ride.dart';
import 'package:drive_tracker/repositories/ride_repository.dart';

class HistoryViewModel extends ChangeNotifier {
  final RideRepository _rideRepository = ServiceLocator.get<RideRepository>();

  List<Ride> _drives = [];
  bool _isLoading = false;

  List<Ride> get drives => _drives;
  bool get isLoading => _isLoading;

  Future<void> loadDrives() async {
    _isLoading = true;
    notifyListeners();

    try {
      _drives = await _rideRepository.getRides();
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteDrive(int id) async {
    await _rideRepository.deleteRide(id);
    await loadDrives();
  }

  Future<void> clearHistory() async {
    await _rideRepository.clearRides();
    await loadDrives();
  }

  Future<void> addMockDrive(Ride ride) async {
    await _rideRepository.addRide(ride);
    await loadDrives();
  }
}
