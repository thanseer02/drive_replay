import 'package:flutter/material.dart';
import 'package:drive_replay/core/services/local_db/app_database.dart';
import 'package:drive_replay/core/domain/repositories/trip_repository.dart';
import 'package:drive_replay/core/logger/logger_service.dart';

class TripHistoryViewModel extends ChangeNotifier {
  final TripRepository _repository;
  
  // State
  List<Trip> _trips = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int? _lastSeenId;
  String _searchQuery = '';
  bool _favoritesOnly = false;
  
  // Statistics State
  double _totalDistance = 0.0;
  int _totalTripsCount = 0;

  // Pagination config
  final int _limit = 20;

  TripHistoryViewModel(this._repository) {
    // Assuming vehicleId 1 for now (active vehicle)
    fetchInitialTrips();
  }

  List<Trip> get trips => _trips;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String get searchQuery => _searchQuery;
  bool get favoritesOnly => _favoritesOnly;
  double get totalDistance => _totalDistance;
  int get totalTripsCount => _totalTripsCount;

  Future<void> fetchInitialTrips() async {
    _isLoading = true;
    _lastSeenId = null;
    _hasMore = true;
    notifyListeners();

    try {
      final results = await _repository.getTripHistory(
        vehicleId: 1, // Hardcoded for now
        limit: _limit,
        lastSeenId: _lastSeenId,
        searchQuery: _searchQuery,
        favoritesOnly: _favoritesOnly,
      );

      _trips = results;
      if (results.isNotEmpty) {
        _lastSeenId = results.last.id;
      }
      _hasMore = results.length == _limit;
      
      _calculateStats();
    } catch (e) {
      LoggerService.error('Failed to fetch initial trips: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNextPage() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final results = await _repository.getTripHistory(
        vehicleId: 1,
        limit: _limit,
        lastSeenId: _lastSeenId,
        searchQuery: _searchQuery,
        favoritesOnly: _favoritesOnly,
      );

      if (results.isNotEmpty) {
        _trips.addAll(results);
        _lastSeenId = results.last.id;
      }
      _hasMore = results.length == _limit;
      _calculateStats();
    } catch (e) {
      LoggerService.error('Failed to fetch next page trips: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchInitialTrips();
  }

  void toggleFavoritesFilter() {
    _favoritesOnly = !_favoritesOnly;
    fetchInitialTrips();
  }

  Future<void> toggleFavorite(int tripId) async {
    await _repository.toggleFavorite(tripId);
    // Optimistic UI update
    final index = _trips.indexWhere((t) => t.id == tripId);
    if (index != -1) {
      final oldTrip = _trips[index];
      // Due to Drift's immutable classes, we use copyWith
      _trips[index] = oldTrip.copyWith(isFavorite: !oldTrip.isFavorite);
      notifyListeners();
    }
  }

  Future<void> deleteTrip(int tripId) async {
    await _repository.softDeleteTrip(tripId);
    _trips.removeWhere((t) => t.id == tripId);
    _calculateStats();
    notifyListeners();
  }

  Future<void> restoreTrip(int tripId) async {
    await _repository.restoreTrip(tripId);
    // Fetch from top to re-order correctly
    await fetchInitialTrips();
  }
  
  Future<String> exportTrip(int tripId) async {
    return await _repository.exportTripCsv(tripId);
  }

  void _calculateStats() {
    _totalTripsCount = _trips.length;
    _totalDistance = _trips.fold(0.0, (sum, trip) => sum + trip.totalDistance);
  }
}
