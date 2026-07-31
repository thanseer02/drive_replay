import 'dart:async';
import 'package:flutter/material.dart';
import 'package:drive_replay/core/services/local_db/app_database.dart';
import 'package:drive_replay/features/trip_record/repositories/trip_repository.dart';
import 'package:drive_replay/core/logger/app_logger.dart';

class ReplayViewModel extends ChangeNotifier {
  final TripRepository _repository;
  
  // Data
  List<TripPoint> _points = [];
  Trip? _trip;
  
  // Playback State
  bool _isPlaying = false;
  bool _isLoading = true;
  double _playbackSpeed = 1.0;
  
  // Simulation State
  DateTime? _simulationTime;
  DateTime? _startTime;
  DateTime? _endTime;
  
  // Interpolated Values
  double _currentLatitude = 0.0;
  double _currentLongitude = 0.0;
  double _currentHeading = 0.0;
  double _currentAltitude = 0.0;
  double _currentDistance = 0.0;
  
  Timer? _ticker;
  DateTime? _lastTickTime;

  ReplayViewModel(this._repository);

  // Getters
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  double get playbackSpeed => _playbackSpeed;
  List<TripPoint> get points => _points;
  Trip? get trip => _trip;
  
  double get currentLatitude => _currentLatitude;
  double get currentLongitude => _currentLongitude;
  double get currentHeading => _currentHeading;
  double get currentAltitude => _currentAltitude;
  double get currentDistance => _currentDistance;

  double get progress {
    if (_startTime == null || _endTime == null || _simulationTime == null) return 0;
    final total = _endTime!.difference(_startTime!).inMilliseconds;
    if (total == 0) return 0;
    final current = _simulationTime!.difference(_startTime!).inMilliseconds;
    return (current / total).clamp(0.0, 1.0);
  }
  
  String get formattedSimTime {
    if (_simulationTime == null) return '00:00';
    final diff = _simulationTime!.difference(_startTime!);
    final mm = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hh = diff.inHours > 0 ? '${diff.inHours}:' : '';
    return '$hh$mm:$ss';
  }

  Future<void> loadTrip(int tripId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _trip = await _repository.getTripDetails(tripId);
      _points = await _repository.getTripPoints(tripId);
      
      if (_points.isNotEmpty) {
        _startTime = _points.first.timestamp;
        _endTime = _points.last.timestamp;
        _simulationTime = _startTime;
        _updateInterpolatedValues();
      }
    } catch (e) {
      AppLogger.e('Failed to load replay: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void togglePlayback() {
    if (_isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void play() {
    if (_points.isEmpty || _simulationTime == null) return;
    if (progress >= 1.0) {
      // Reset if at end
      _simulationTime = _startTime;
    }
    
    _isPlaying = true;
    _lastTickTime = DateTime.now();
    
    // ~60fps ticker
    _ticker = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _tick();
    });
    notifyListeners();
  }

  void pause() {
    _isPlaying = false;
    _ticker?.cancel();
    notifyListeners();
  }

  void setPlaybackSpeed(double speed) {
    _playbackSpeed = speed;
    notifyListeners();
  }

  void seekTo(double progressRatio) {
    if (_startTime == null || _endTime == null) return;
    
    final totalMs = _endTime!.difference(_startTime!).inMilliseconds;
    final targetMs = (totalMs * progressRatio).round();
    _simulationTime = _startTime!.add(Duration(milliseconds: targetMs));
    
    _updateInterpolatedValues();
    notifyListeners();
  }

  void _tick() {
    if (_simulationTime == null || _endTime == null) return;
    
    final now = DateTime.now();
    final realDeltaMs = now.difference(_lastTickTime!).inMilliseconds;
    _lastTickTime = now;
    
    final simDeltaMs = (realDeltaMs * _playbackSpeed).round();
    _simulationTime = _simulationTime!.add(Duration(milliseconds: simDeltaMs));
    
    if (_simulationTime!.isAfter(_endTime!)) {
      _simulationTime = _endTime;
      pause();
    }
    
    _updateInterpolatedValues();
    notifyListeners();
  }

  void _updateInterpolatedValues() {
    if (_points.isEmpty || _simulationTime == null) return;

    // Find bounding points
    final int idx = _points.indexWhere((p) => p.timestamp.isAfter(_simulationTime!));
    
    if (idx == -1) {
      // At the end
      _applyPoint(_points.last);
      return;
    }
    
    if (idx == 0) {
      // At the start
      _applyPoint(_points.first);
      return;
    }

    final p1 = _points[idx - 1];
    final p2 = _points[idx];
    
    final int totalMs = p2.timestamp.difference(p1.timestamp).inMilliseconds;
    if (totalMs == 0) {
      _applyPoint(p1);
      return;
    }
    
    final elapsedMs = _simulationTime!.difference(p1.timestamp).inMilliseconds;
    final t = (elapsedMs / totalMs).clamp(0.0, 1.0);
    
    // Linear Interpolation
    _currentLatitude = _lerp(p1.latitude, p2.latitude, t);
    _currentLongitude = _lerp(p1.longitude, p2.longitude, t);
    
    // For smooth visuals, we can infer speed from distance over time, 
    // but we can also just lerp available accuracy/speed values if we had them. 
    // Since our TripPoint only stores altitude/heading/accuracy, we lerp them:
    _currentAltitude = _lerp(p1.altitude ?? 0.0, p2.altitude ?? 0.0, t);
    
    // Heading needs shortest-path circular interpolation
    _currentHeading = _lerpHeading(p1.heading ?? 0.0, p2.heading ?? 0.0, t);
    
    // Approximate distance dynamically (in a full app we'd accumulate distance at each point)
    _currentDistance = _lerp((idx - 1).toDouble(), idx.toDouble(), t) * 5; // Placeholder for distance
  }

  void _applyPoint(TripPoint p) {
    _currentLatitude = p.latitude;
    _currentLongitude = p.longitude;
    _currentAltitude = p.altitude ?? 0.0;
    _currentHeading = p.heading ?? 0.0;
  }

  double _lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }

  double _lerpHeading(double a, double b, double t) {
    double diff = b - a;
    while (diff < -180.0) {
      diff += 360.0;
    }
    while (diff > 180.0) {
      diff -= 360.0;
    }
    return a + diff * t;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
