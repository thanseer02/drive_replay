import 'package:flutter/material.dart';
import 'package:drive_tracker/core/di.dart';
import 'package:drive_tracker/models/activity_model.dart';
import 'package:drive_tracker/repositories/activity_repository.dart';
import 'package:intl/intl.dart';

class HistoryViewModel extends ChangeNotifier {
  final ActivityRepository _activityRepository = ServiceLocator.get<ActivityRepository>();

  List<ActivityModel> _activities = [];
  bool _isLoading = false;
  String? _error;

  ActivityModel? _selectedActivity;
  bool _isLoadingDetails = false;
  String? _detailsError;

  String _searchQuery = '';
  String _sortBy = 'date_desc'; 
  String _filterDistance = 'all'; 
  String _filterDate = 'all'; 

  List<ActivityModel> get drives => _activities;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ActivityModel? get selectedRide => _selectedActivity;
  bool get isLoadingDetails => _isLoadingDetails;
  String? get detailsError => _detailsError;

  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;
  String get filterDistance => _filterDistance;
  String get filterDate => _filterDate;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  void setFilterDistance(String range) {
    _filterDistance = range;
    notifyListeners();
  }

  void setFilterDate(String dateRange) {
    _filterDate = dateRange;
    notifyListeners();
  }

  List<ActivityModel> get filteredDrives {
    List<ActivityModel> filtered = List.from(_activities);

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((act) {
        final dateStr = DateFormat('EEEE MMMM d yyyy').format(act.startTime).toLowerCase();
        final typeStr = act.activityType.toLowerCase();
        return dateStr.contains(query) || typeStr.contains(query);
      }).toList();
    }

    if (_filterDistance != 'all') {
      filtered = filtered.where((act) {
        final dist = act.distance;
        switch (_filterDistance) {
          case 'short': return dist < 1.0;
          case 'medium': return dist >= 1.0 && dist <= 5.0;
          case 'long': return dist > 5.0;
          default: return true;
        }
      }).toList();
    }

    if (_filterDate != 'all') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final oneWeekAgo = today.subtract(const Duration(days: 7));

      filtered = filtered.where((act) {
        final date = DateTime(act.startTime.year, act.startTime.month, act.startTime.day);
        switch (_filterDate) {
          case 'today': return date == today;
          case 'yesterday': return date == yesterday;
          case 'week': return date.isAfter(oneWeekAgo) || date == oneWeekAgo;
          default: return true;
        }
      }).toList();
    }

    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'date_asc': return a.startTime.compareTo(b.startTime);
        case 'distance_desc': return b.distance.compareTo(a.distance);
        case 'distance_asc': return a.distance.compareTo(b.distance);
        case 'speed_desc': return b.maxSpeed.compareTo(a.maxSpeed);
        case 'duration_desc': return b.duration.compareTo(a.duration);
        case 'date_desc':
        default: return b.startTime.compareTo(a.startTime);
      }
    });

    return filtered;
  }

  Future<void> loadDrives() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _activities = await _activityRepository.getActivities();
    } catch (e) {
      _error = 'Could not load history.';
      _activities = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRideDetails(int id) async {
    _isLoadingDetails = true;
    _detailsError = null;
    _selectedActivity = null;
    notifyListeners();

    try {
      _selectedActivity = await _activityRepository.getActivityDetails(id);
      if (_selectedActivity == null) _detailsError = 'Not found.';
    } catch (e) {
      _detailsError = 'Could not load details.';
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }

  Future<void> deleteDrive(int id) async {
    _error = null;
    notifyListeners();
    try {
      await _activityRepository.deleteActivity(id);
      if (_selectedActivity?.id == id) _selectedActivity = null;
      await loadDrives();
    } catch (e) {
      _error = 'Failed to delete.';
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    _error = null;
    notifyListeners();
    try {
      await _activityRepository.clearActivities();
      _selectedActivity = null;
      await loadDrives();
    } catch (e) {
      _error = 'Failed to clear history.';
      notifyListeners();
    }
  }

  Future<void> addMockDrive(ActivityModel act) async {
    _error = null;
    notifyListeners();
    try {
      await _activityRepository.addActivity(act);
      await loadDrives();
    } catch (e) {
      _error = 'Failed to add mock.';
      notifyListeners();
    }
  }
}
