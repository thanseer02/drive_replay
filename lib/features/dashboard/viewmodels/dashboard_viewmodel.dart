import 'package:flutter/material.dart';
import 'package:drive_replay/core/domain/repositories/trip_repository.dart';
import 'package:drive_replay/core/logger/logger_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final TripRepository _tripRepository;

  bool _isLoading = true;
  double _todayDistance = 0.0;
  int _totalTrips = 0;
  final bool _isRecording = false; // Mock state, normally bound to TripRecordingService

  DashboardViewModel(this._tripRepository) {
    _loadDashboardData();
  }

  bool get isLoading => _isLoading;
  double get todayDistance => _todayDistance;
  int get totalTrips => _totalTrips;
  bool get isRecording => _isRecording;

  Future<void> _loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      // Load today's stats using robust Odometer service
      _todayDistance = await _tripRepository.getOdometerSince(1, startOfDay);

      // Load total trips count (we can approximate by fetching history without limit, or add a count query)
      final trips = await _tripRepository.getTripHistory(vehicleId: 1, limit: 10000);
      _totalTrips = trips.length;

    } catch (e, stack) {
      LoggerService.error('Failed to load dashboard data', e, stack);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await _loadDashboardData();
  }
}
