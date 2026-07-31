import 'package:drive_replay/core/services/local_db/app_database.dart';

abstract class VehicleRepository {
  Future<List<Vehicle>> getVehicles();
  Future<Vehicle?> getActiveVehicle();
  Future<void> saveVehicle(Vehicle vehicle);
}
