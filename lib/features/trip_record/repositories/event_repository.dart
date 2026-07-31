import 'package:drive_replay/core/services/local_db/app_database.dart';

abstract class EventRepository {
  Future<void> logEvent(Event event);
  Future<List<Event>> getEventsForTrip(int tripId);
}
