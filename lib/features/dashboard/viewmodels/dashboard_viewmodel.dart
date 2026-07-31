import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:drive_replay/core/domain/repositories/trip_repository.dart';
import 'package:drive_replay/core/logger/logger_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final TripRepository _tripRepository;

  bool _isLoading = true;
  
  // Static distances strictly from SQLite (completed trips)
  double _staticTodayDistance = 0.0;
  double _staticWeeklyDistance = 0.0;
  double _staticMonthlyDistance = 0.0;
  double _staticLifetimeDistance = 0.0;
  
  // Live distance from active Isolate
  double _liveActiveTripDistance = 0.0;
  
  int _totalTrips = 0;
  bool _isRecording = false;

  DashboardViewModel(this._tripRepository) {
    _initLiveSync();
    _loadDashboardData();
  }

  void _initLiveSync() {
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
  }

  void _onReceiveTaskData(Object data) {
    if (data is Map && data['type'] == 'UPDATE') {
      _liveActiveTripDistance = (data['distance'] as num?)?.toDouble() ?? 0.0;
      if (!_isRecording) {
        _isRecording = true;
      }
      notifyListeners();
    }
  }

  bool get isLoading => _isLoading;
  // Odometer Getters = Completed DB Distance + Live Active Distance
  double get todayDistance => _staticTodayDistance + _liveActiveTripDistance;
  double get weeklyDistance => _staticWeeklyDistance + _liveActiveTripDistance;
  double get monthlyDistance => _staticMonthlyDistance + _liveActiveTripDistance;
  double get lifetimeDistance => _staticLifetimeDistance + _liveActiveTripDistance;
  
  int get totalTrips => _totalTrips;
  bool get isRecording => _isRecording;

  Future<void> _loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Recover Live State First (to prevent double counting if DB just finished)
      final isRunning = await FlutterForegroundTask.isRunningService;
      _isRecording = isRunning;
      if (isRunning) {
        final prefs = await SharedPreferences.getInstance();
        _liveActiveTripDistance = prefs.getDouble('current_active_trip_distance') ?? 0.0;
      } else {
        _liveActiveTripDistance = 0.0;
      }

      // 2. Fetch Static DB State
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);
      
      _staticTodayDistance = await _tripRepository.getOdometerSince(1, startOfDay);
      _staticWeeklyDistance = await _tripRepository.getOdometerSince(1, startOfWeek);
      _staticMonthlyDistance = await _tripRepository.getOdometerSince(1, startOfMonth);
      _staticLifetimeDistance = await _tripRepository.getOdometerTotal(1);

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
  
  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    super.dispose();
  }
}
