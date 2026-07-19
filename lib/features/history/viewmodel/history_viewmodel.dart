import 'package:flutter/material.dart';
import 'package:drive_tracker/core/di.dart';
import 'package:drive_tracker/models/ride.dart';
import 'package:drive_tracker/repositories/ride_repository.dart';
import 'package:intl/intl.dart';

class HistoryViewModel extends ChangeNotifier {
  final RideRepository _rideRepository = ServiceLocator.get<RideRepository>();

  List<Ride> _drives = [];
  bool _isLoading = false;
  String? _error;

  // Selected ride for details view
  Ride? _selectedRide;
  bool _isLoadingDetails = false;
  String? _detailsError;

  // Search and Filter states
  String _searchQuery = '';
  String _sortBy = 'date_desc'; // date_desc, date_asc, distance_desc, distance_asc, speed_desc, duration_desc
  String _filterDistance = 'all'; // all, short (<1km), medium (1-5km), long (>5km)
  String _filterDate = 'all'; // all, today, yesterday, week

  List<Ride> get drives => _drives;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Ride? get selectedRide => _selectedRide;
  bool get isLoadingDetails => _isLoadingDetails;
  String? get detailsError => _detailsError;

  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;
  String get filterDistance => _filterDistance;
  String get filterDate => _filterDate;

  // Setters that notify listeners
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

  // Get computed filtered and sorted drives
  List<Ride> get filteredDrives {
    List<Ride> filtered = List.from(_drives);

    // 1. Text Search Filter
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((ride) {
        final dateStr = DateFormat('EEEE MMMM d yyyy').format(ride.startTime).toLowerCase();
        final notesStr = ride.notes.toLowerCase();
        final startLoc = ride.startLocation.toLowerCase();
        final endLoc = ride.endLocation.toLowerCase();
        return dateStr.contains(query) ||
               notesStr.contains(query) ||
               startLoc.contains(query) ||
               endLoc.contains(query);
      }).toList();
    }

    // 2. Distance Filter
    if (_filterDistance != 'all') {
      filtered = filtered.where((ride) {
        final dist = ride.distance; // in km
        switch (_filterDistance) {
          case 'short':
            return dist < 1.0;
          case 'medium':
            return dist >= 1.0 && dist <= 5.0;
          case 'long':
            return dist > 5.0;
          default:
            return true;
        }
      }).toList();
    }

    // 3. Date Range Filter
    if (_filterDate != 'all') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final oneWeekAgo = today.subtract(const Duration(days: 7));

      filtered = filtered.where((ride) {
        final rideDate = DateTime(ride.startTime.year, ride.startTime.month, ride.startTime.day);
        switch (_filterDate) {
          case 'today':
            return rideDate == today;
          case 'yesterday':
            return rideDate == yesterday;
          case 'week':
            return rideDate.isAfter(oneWeekAgo) || rideDate == oneWeekAgo;
          default:
            return true;
        }
      }).toList();
    }

    // 4. Sorting logic
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'date_asc':
          return a.startTime.compareTo(b.startTime);
        case 'distance_desc':
          return b.distance.compareTo(a.distance);
        case 'distance_asc':
          return a.distance.compareTo(b.distance);
        case 'speed_desc':
          return b.maxSpeed.compareTo(a.maxSpeed);
        case 'duration_desc':
          return b.durationSeconds.compareTo(a.durationSeconds);
        case 'date_desc':
        default:
          return b.startTime.compareTo(a.startTime);
      }
    });

    return filtered;
  }

  Future<void> loadDrives() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _drives = await _rideRepository.getRides();
    } catch (e) {
      _error = 'Could not load ride history. Please try again.';
      _drives = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRideDetails(int id) async {
    _isLoadingDetails = true;
    _detailsError = null;
    _selectedRide = null;
    notifyListeners();

    try {
      _selectedRide = await _rideRepository.getRide(id);
      if (_selectedRide == null) {
        _detailsError = 'Ride not found.';
      }
    } catch (e) {
      _detailsError = 'Could not load ride details. Please try again.';
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }

  Future<void> deleteDrive(int id) async {
    _error = null;
    notifyListeners();
    try {
      await _rideRepository.deleteRide(id);
      if (_selectedRide?.id == id) {
        _selectedRide = null;
      }
      await loadDrives();
    } catch (e) {
      _error = 'Failed to delete ride log. Please try again.';
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    _error = null;
    notifyListeners();
    try {
      await _rideRepository.clearRides();
      _selectedRide = null;
      await loadDrives();
    } catch (e) {
      _error = 'Failed to clear history database. Please try again.';
      notifyListeners();
    }
  }

  Future<void> addMockDrive(Ride ride) async {
    _error = null;
    notifyListeners();
    try {
      await _rideRepository.addRide(ride);
      await loadDrives();
    } catch (e) {
      _error = 'Failed to add mock drive. Please try again.';
      notifyListeners();
    }
  }

}

