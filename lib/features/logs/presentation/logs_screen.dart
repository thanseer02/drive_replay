import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/log_service.dart';
import '../models/log_entry.dart';
import '../../dashboard/viewmodel/dashboard_viewmodel.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_autoScroll && _scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Logs'),
        actions: [
          Consumer<LogService>(
            builder: (context, logService, _) {
              return IconButton(
                icon: Icon(logService.isPaused ? Icons.play_arrow : Icons.pause),
                tooltip: logService.isPaused ? 'Resume' : 'Pause',
                onPressed: () => logService.togglePause(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear',
            onPressed: () => context.read<LogService>().clearLogs(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              final logService = context.read<LogService>();
              if (value == 'copy') {
                final text = logService.logs.map((e) => e.toString()).join('\n');
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logs copied to clipboard')),
                );
              } else if (value == 'verbose') {
                logService.toggleVerbose();
              } else if (value == 'autoscroll') {
                setState(() => _autoScroll = !_autoScroll);
                if (_autoScroll) _scrollToBottom();
              }
            },
            itemBuilder: (context) {
              final logService = context.read<LogService>();
              return [
                const PopupMenuItem(
                  value: 'copy',
                  child: Text('Copy All Logs'),
                ),
                PopupMenuItem(
                  value: 'verbose',
                  child: Text(logService.verboseLogging ? 'Disable Verbose' : 'Enable Verbose'),
                ),
                PopupMenuItem(
                  value: 'autoscroll',
                  child: Text(_autoScroll ? 'Disable Auto-Scroll' : 'Enable Auto-Scroll'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatisticsPanel(context),
          Expanded(
            child: Container(
              color: Colors.black,
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              child: Consumer<LogService>(
                builder: (context, logService, child) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: logService.logs.length,
                    itemBuilder: (context, index) {
                      final log = logService.logs[index];
                      return _buildLogEntry(log);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsPanel(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, dashboard, _) {
        return Container(
          color: Theme.of(context).colorScheme.surfaceVariant,
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('Speed', '${dashboard.currentSpeed.toStringAsFixed(1)} km/h'),
                  _statItem('Dist', '${dashboard.activeDistance.toStringAsFixed(2)} km'),
                  _statItem('Steps', '${dashboard.steps}'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('Driving Time', '${dashboard.drivingTimeSeconds}s'),
                  _statItem('Stop Time', '${dashboard.stoppedTimeSeconds}s'),
                  _statItem('Tracking', dashboard.isTracking ? 'YES' : 'NO'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildLogEntry(LogEntry log) {
    Color color = Colors.greenAccent;
    if (log.level == LogLevel.warning) color = Colors.orange;
    if (log.level == LogLevel.error) color = Colors.red;
    if (log.level == LogLevel.success) color = Colors.blueAccent;

    final time = "${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}.${log.timestamp.millisecond.toString().padLeft(3, '0')}";

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: SelectableText(
        "$time [${log.category}]\n${log.message}",
        style: TextStyle(
          color: color,
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      ),
    );
  }
}
