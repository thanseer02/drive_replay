import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../repositories/trip_repository.dart';

class ExportHelper {
  ExportHelper._();

  static Future<void> exportTripsToCSV() async {
    final trips = await TripRepository.instance.getAllTrips();
    
    List<List<dynamic>> rows = [
      ["Trip ID", "Start Time", "End Time", "Distance (m)", "Top Speed (m/s)", "Average Speed (m/s)", "Score"]
    ];

    for (var trip in trips) {
      rows.add([
        trip.id,
        trip.startTime.toIso8601String(),
        trip.endTime?.toIso8601String() ?? 'Ongoing',
        trip.distanceInMeters,
        trip.topSpeed,
        trip.averageSpeed,
        trip.score,
      ]);
    }

    String csvData = rows.map((row) => row.join(',')).join('\n');

    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/drive_replay_trips.csv";
    final file = File(path);
    await file.writeAsString(csvData);

    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(path)], text: 'My Drive Replay Trip Log');
  }
}
