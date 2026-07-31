import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:drive_replay/core/domain/repositories/analytics_repository.dart';
import 'package:drive_replay/core/logger/logger_service.dart';

enum TimeRange { weekly, monthly, yearly }

class AnalyticsViewModel extends ChangeNotifier {
  final AnalyticsRepository _repository;
  
  TimeRange _currentRange = TimeRange.weekly;
  bool _isLoading = true;
  
  AggregateStats? _stats;
  List<BarChartGroupData> _chartData = [];
  double _maxChartY = 0;

  AnalyticsViewModel(this._repository) {
    loadData();
  }

  TimeRange get currentRange => _currentRange;
  bool get isLoading => _isLoading;
  AggregateStats? get stats => _stats;
  List<BarChartGroupData> get chartData => _chartData;
  double get maxChartY => _maxChartY;

  void setTimeRange(TimeRange range) {
    if (_currentRange == range) return;
    _currentRange = range;
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      DateTime start;
      bool groupByMonth = false;

      switch (_currentRange) {
        case TimeRange.weekly:
          start = now.subtract(const Duration(days: 7));
          break;
        case TimeRange.monthly:
          start = DateTime(now.year, now.month - 1, now.day);
          break;
        case TimeRange.yearly:
          start = DateTime(now.year - 1, now.month, now.day);
          groupByMonth = true;
          break;
      }

      _stats = await _repository.getAggregateStats(1, start, now);
      
      final distanceData = await _repository.getDistancePerPeriod(1, start, now, groupByMonth);
      
      _buildChartData(distanceData, groupByMonth);
      
    } catch (e) {
      LoggerService.error('Failed to load analytics: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _buildChartData(List<DistancePerPeriod> data, bool groupByMonth) {
    _chartData = [];
    _maxChartY = 0;
    
    int index = 0;
    for (var d in data) {
      final val = d.distance / 1000.0; // km
      if (val > _maxChartY) _maxChartY = val;
      
      _chartData.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: val,
              width: 16,
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        )
      );
      index++;
    }
    
    // Add 20% padding to max Y for visual headroom
    _maxChartY = _maxChartY * 1.2;
    if (_maxChartY < 10) _maxChartY = 10;
  }
}
