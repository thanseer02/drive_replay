import 'package:drive_tracker/models/drive.dart';

abstract class DriveRepository {
  Future<List<Drive>> getDrives();
  Future<int> addDrive(Drive drive);
  Future<int> deleteDrive(int id);
  Future<int> clearDrives();
}
