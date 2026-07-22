enum LogLevel { info, warning, error, success }

class LogEntry {
  final DateTime timestamp;
  final String category;
  final String message;
  final LogLevel level;

  LogEntry({
    required this.timestamp,
    required this.category,
    required this.message,
    required this.level,
  });

  @override
  String toString() {
    final time = "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}.${timestamp.millisecond.toString().padLeft(3, '0')}";
    return "$time\n[$category]\n$message\n";
  }
}
