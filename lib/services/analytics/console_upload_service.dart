import 'package:flutter/foundation.dart';
import 'package:flutter_background_analyser/features/analytics/core/uploader/analytics_upload_service.dart';
import 'package:flutter_background_analyser/features/analytics/domain/entities/analytics_event.dart';

class ConsoleUploadService implements AnalyticsUploadService {
  @override
  Future<bool> uploadBatch(List<AnalyticsEvent> events) async {
    debugPrint('[ConsoleUploadService] Uploading batch of ${events.length} events:');
    for (var event in events) {
      debugPrint('  - Event: ${event.eventType} (ID: ${event.eventId}, Screen: ${event.screenName})');
    }
    return true;
  }
}
