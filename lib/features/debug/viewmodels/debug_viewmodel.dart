import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:drive_replay/core/services/local_db/app_database.dart';

class DebugViewModel extends ChangeNotifier {
  final AppDatabase _db;
  Timer? _timer;

  int totalDbPoints = 0;
  int currentTripPoints = 0;
  bool isForegroundServiceRunning = false;
  
  DebugViewModel(this._db) {
    _startPolling();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => refreshStats());
    refreshStats();
  }

  Future<void> refreshStats() async {
    try {
      final totalPointsResult = await _db.customSelect('SELECT COUNT(*) as c FROM trip_points').getSingle();
      totalDbPoints = totalPointsResult.read<int>('c');
      isForegroundServiceRunning = await FlutterForegroundTask.isRunningService;
      notifyListeners();
    } catch (e) {
      // Ignore
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
