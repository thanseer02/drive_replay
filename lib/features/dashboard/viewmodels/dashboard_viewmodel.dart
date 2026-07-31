import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
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

  final _eventChannel = const EventChannel('com.drivereplay.location/stream');

  void _initLiveSync() {
    _eventChannel.receiveBroadcastStream().listen((data) {
      LoggerService.info('DASHBOARD_SYNC: Native EventChannel called with: $data');
      if (data is Map && data['type'] == 'UPDATE') {
        _liveActiveTripDistance = (data['distance'] as num?)?.toDouble() ?? 0.0;
        if (!_isRecording) {
          _isRecording = true;
        }
        notifyListeners();
      }
    }, onError: (error) {
      LoggerService.error('Native EventChannel Error: $error');
    });
  }

  bool get isLoading => _isLoading;
  // Odometer Getters = Completed DB Distance + Live Active Distance
  double get todayDistance {
    final total = _staticTodayDistance + _liveActiveTripDistance;
    LoggerService.info('DASHBOARD_SYNC: getter todayDistance called. static: $_staticTodayDistance, live: $_liveActiveTripDistance, total: $total');
    return total;
  }
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
      final prefs = await SharedPreferences.getInstance();
      final activeTripId = prefs.getInt('flutter.current_active_trip_id') ?? -1;
      if (activeTripId != -1) {
        _isRecording = true;
        _liveActiveTripDistance = prefs.getDouble('flutter.current_active_trip_distance') ?? 0.0;
      } else {
        _isRecording = false;
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
    super.dispose();
  }
}
