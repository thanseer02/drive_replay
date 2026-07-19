import 'package:drive_tracker/database/db_helper.dart';
import 'package:drive_tracker/models/drive.dart';
import 'package:drive_tracker/repositories/drive_repository.dart';

class DriveRepositoryImpl implements DriveRepository {
  final DBHelper _dbHelper;

  DriveRepositoryImpl(this._dbHelper);

  @override
  Future<List<Drive>> getDrives() async {
    return await _dbHelper.getAllDrives();
  }

  @override
  Future<int> addDrive(Drive drive) async {
    return await _dbHelper.insertDrive(drive);
  }

  @override
  Future<int> deleteDrive(int id) async {
    return await _dbHelper.deleteDrive(id);
  }

  @override
  Future<int> clearDrives() async {
    return await _dbHelper.clearAllDrives();
  }
}
