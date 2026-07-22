import 'package:drive_tracker/database/db_helper.dart';
import 'package:drive_tracker/models/activity_model.dart';

class ActivityRepository {
  final DBHelper _dbHelper = DBHelper.instance;

  Future<void> addActivity(ActivityModel activity) async {
    await _dbHelper.insertActivity(activity);
  }

  Future<List<ActivityModel>> getActivities() async {
    return await _dbHelper.getAllActivities();
  }

  Future<ActivityModel?> getActivityDetails(int id) async {
    return await _dbHelper.getActivity(id);
  }

  Future<void> deleteActivity(int id) async {
    await _dbHelper.deleteActivity(id);
  }

  Future<void> clearActivities() async {
    await _dbHelper.clearAllActivities();
  }
}
