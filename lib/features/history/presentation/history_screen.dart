import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:drive_tracker/features/history/viewmodel/history_viewmodel.dart';
import 'package:drive_tracker/features/settings/viewmodel/settings_viewmodel.dart';
import 'package:drive_tracker/models/drive.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryViewModel>().loadDrives();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final historyVM = context.watch<HistoryViewModel>();
    final settingsVM = context.watch<SettingsViewModel>();

    // Unit settings
    final bool useMetric = settingsVM.useMetric;
    final double distMulti = useMetric ? 1.0 : 0.621371;
    final String velocityUnit = useMetric ? 'km/h' : 'mph';
    final String distLabel = useMetric ? 'km' : 'mi';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride History'),
        actions: [
          if (historyVM.drives.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear All Logs',
              onPressed: () => _confirmClearAll(context, historyVM),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.brightness == Brightness.light
                ? [const Color(0xFFF1F5F9), const Color(0xFFFFFFFF)]
                : [const Color(0xFF0F172A), const Color(0xFF1E293B)],
          ),
        ),
        child: historyVM.isLoading
            ? const Center(child: CircularProgressIndicator())
            : historyVM.drives.isEmpty
                ? _buildEmptyState(theme)
                : _buildGroupedDriveList(context, theme, historyVM.drives, distMulti, distLabel, velocityUnit, historyVM),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_toggle_off_rounded,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Drives Recorded Yet',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a simulated drive from the dashboard tab\nto populate travel logs.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedDriveList(
    BuildContext context,
    ThemeData theme,
    List<Drive> drives,
    double distMulti,
    String distLabel,
    String speedLabel,
    HistoryViewModel viewModel,
  ) {
    // 1. Group drives by localized day codes
    final Map<String, List<Drive>> grouped = {};
    for (var drive in drives) {
      final key = _getDateHeaderString(drive.startTime);
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(drive);
    }

    final keys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: keys.length,
      itemBuilder: (context, groupIndex) {
        final dateKey = keys[groupIndex];
        final List<Drive> driveGroup = grouped[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header section (Tesla/Garmin Connect look)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 12.0, bottom: 8.0),
              child: Text(
                dateKey.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            // Drive entries inside date scope
            ...driveGroup.map((drive) {
              return _buildTeslaDriveCard(context, theme, drive, distMulti, distLabel, speedLabel, viewModel);
            }).toList(),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildTeslaDriveCard(
    BuildContext context,
    ThemeData theme,
    Drive drive,
    double distMulti,
    String distLabel,
    String speedLabel,
    HistoryViewModel viewModel,
  ) {
    final bool isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final strokeColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final displayDist = drive.distance * distMulti;
    // Calculate average speed from aggregate values
    final totalHours = drive.durationSeconds / 3600.0;
    final double avgSpeed = totalHours > 0 ? (drive.distance / totalHours) : 0.0;
    final displayAvgSpeed = avgSpeed * distMulti;

    final String timeRange = '${DateFormat('hh:mm a').format(drive.startTime)} - ${DateFormat('hh:mm a').format(drive.endTime)}';
    final String durationString = _formatSeconds(drive.durationSeconds);

    return Dismissible(
      key: Key('drive_${drive.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) {
        if (drive.id != null) {
          viewModel.deleteDrive(drive.id!);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Ride log deleted'),
              action: SnackBarAction(
                label: 'Undo',
                textColor: Colors.white,
                onPressed: () {
                  viewModel.addMockDrive(drive);
                },
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        elevation: 0,
        color: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: strokeColor, width: 1.0),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            // Navigate to Details Screen
            if (drive.id != null) {
              context.push('/ride-details/${drive.id}');
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Top Row: Travel endpoints and time boundaries range
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.trip_origin_rounded, color: theme.colorScheme.primary, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${drive.startLocation} to ${drive.endLocation}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      timeRange,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Grid Stats (Garmin styled indicators)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCompactCardStat(
                      theme,
                      'DISTANCE',
                      '${displayDist.toStringAsFixed(1)} $distLabel',
                      Icons.map_outlined,
                      Colors.blueAccent,
                    ),
                    _buildCompactCardStat(
                      theme,
                      'AVG SPEED',
                      '${displayAvgSpeed.toStringAsFixed(0)} $speedLabel',
                      Icons.speed_rounded,
                      Colors.indigoAccent,
                    ),
                    _buildCompactCardStat(
                      theme,
                      'DURATION',
                      durationString,
                      Icons.av_timer_rounded,
                      const Color(0xFF10B981),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCardStat(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  String _getDateHeaderString(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) {
      return 'Today';
    } else if (checkDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('EEE, MMMM d, yyyy').format(date);
    }
  }

  String _formatSeconds(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    if (minutes == 0) return '${totalSeconds}s';
    return '${minutes} mins';
  }

  void _confirmClearAll(BuildContext context, HistoryViewModel viewModel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All History?'),
        content: const Text('This will delete all previous drive records from storage. This action is permanent.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              viewModel.clearHistory();
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
