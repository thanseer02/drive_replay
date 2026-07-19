import 'package:flutter/material.dart';
import 'package:drive_tracker/core/di.dart';
import 'package:drive_tracker/models/drive.dart';
import 'package:drive_tracker/repositories/drive_repository.dart';

class HistoryViewModel extends ChangeNotifier {
  final DriveRepository _driveRepository = ServiceLocator.get<DriveRepository>();

  List<Drive> _drives = [];
  bool _isLoading = false;

  List<Drive> get drives => _drives;
  bool get isLoading => _isLoading;

  Future<void> loadDrives() async {
    _isLoading = true;
    notifyListeners();

    try {
      _drives = await _driveRepository.getDrives();
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteDrive(int id) async {
    await _driveRepository.deleteDrive(id);
    await loadDrives();
  }

  Future<void> clearHistory() async {
    await _driveRepository.clearDrives();
    await loadDrives();
  }

  Future<void> addMockDrive(Drive drive) async {
    await _driveRepository.addDrive(drive);
    await loadDrives();
  }
}
