import 'package:flutter/material.dart';
import 'package:drive_replay/core/services/local_db/app_database.dart';
import 'package:drive_replay/features/trip_record/repositories/trip_repository.dart';

class TripHistoryViewModel extends ChangeNotifier {
  final TripRepository _repository;
  
  // State
  List<Trip> _trips = [];
  bool _isLoading = false;
  bool _hasReachedMax = false;
  String _searchQuery = '';
  bool _favoritesOnly = false;
  
  // Statistics State
  double _totalDistance = 0.0;
  int _totalTripsCount = 0;

  // Pagination config
  final int _limit = 20;
  int _offset = 0;

  TripHistoryViewModel(this._repository) {
    // Assuming vehicleId 1 for now (active vehicle)
    fetchInitialTrips();
  }

  List<Trip> get trips => _trips;
  bool get isLoading => _isLoading;
  bool get hasReachedMax => _hasReachedMax;
  String get searchQuery => _searchQuery;
  bool get favoritesOnly => _favoritesOnly;
  double get totalDistance => _totalDistance;
  int get totalTripsCount => _totalTripsCount;

  Future<void> fetchInitialTrips() async {
    _offset = 0;
    _hasReachedMax = false;
    _trips = [];
    _totalDistance = 0.0;
    _totalTripsCount = 0;
    await _fetchTrips();
  }

  Future<void> fetchNextPage() async {
    if (_hasReachedMax || _isLoading) return;
    _offset += _limit;
    await _fetchTrips();
  }

  Future<void> _fetchTrips() async {
    _isLoading = true;
    notifyListeners();

    try {
      final fetchedTrips = await _repository.getTripHistory(
        vehicleId: 1, // Defaulting to 1 for this implementation
        limit: _limit,
        offset: _offset,
        searchQuery: _searchQuery,
        favoritesOnly: _favoritesOnly,
      );

      if (fetchedTrips.isEmpty) {
        _hasReachedMax = true;
      } else {
        _trips.addAll(fetchedTrips);
        _calculateStats();
      }
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
