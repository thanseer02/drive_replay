import 'package:flutter/material.dart';
import '../../../repositories/trip_repository.dart';
import '../../trip_recording/model/trip_model.dart';

class HistoryViewModel extends ChangeNotifier {
  final TripRepository _repository = TripRepository.instance;
  
  List<TripModel> _trips = [];
  bool _isLoading = false;

  List<TripModel> get trips => _trips;
  bool get isLoading => _isLoading;

  Future<void> loadTrips() async {
    _isLoading = true;
    notifyListeners();
    
    _trips = await _repository.getAllTrips();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteTrip(String id) async {
    await _repository.deleteTrip(id);
    await loadTrips(); // Refresh the list
  }
}
