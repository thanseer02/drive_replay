import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:drive_tracker/features/history/viewmodel/history_viewmodel.dart';
import 'package:drive_tracker/features/settings/viewmodel/settings_viewmodel.dart';
import 'package:drive_tracker/models/activity_model.dart';
import 'package:drive_tracker/models/activity_location.dart';
import 'package:drive_tracker/widgets/shimmer_loader.dart';

class RideDetailsScreen extends StatefulWidget {
  final int driveId;
  final bool isEmbedded;

  const RideDetailsScreen({
    super.key,
    required this.driveId,
    this.isEmbedded = false,
  });

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryViewModel>().loadRideDetails(widget.driveId);
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

    if (historyVM.isLoadingDetails) {
      return widget.isEmbedded
          ? const ShimmerDetailsLoader()
          : Scaffold(
              appBar: AppBar(title: const Text('Ride Metrics Summary')),
              body: const ShimmerDetailsLoader(),
            );
    }

    final drive = historyVM.selectedRide;

    if (drive == null) {
      return widget.isEmbedded
          ? Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: const Text('Ride Details'),
              ),
              body: const Center(
                child: Text(
                  'Select a ride to view metrics',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            )
          : Scaffold(
              appBar: AppBar(title: const Text('Ride Details')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Drive log not found or deleted'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
    }

    final double displayDistance = drive.distance * distMulti;
    final double displayAvgSpeed = drive.averageSpeed * distMulti;
    final double displayMaxSpeed = drive.maxSpeed * distMulti;
    
    final String dateString = DateFormat('EEEE, MMMM d, yyyy').format(drive.startTime);
    final String startStr = DateFormat('hh:mm:ss a').format(drive.startTime);
    final String endStr = DateFormat('hh:mm:ss a').format(drive.endTime ?? drive.startTime);

    // Compute Driving vs Stopped ratios based on actual database variables
    final int totalSeconds = drive.duration;
    final double drivingRatio = totalSeconds > 0 ? ((drive.duration - drive.stopTime) / totalSeconds).clamp(0.0, 1.0) : 0.0;
    final double stoppedRatio = totalSeconds > 0 ? (drive.stopTime / totalSeconds).clamp(0.0, 1.0) : 0.0;

    final locations = drive.locations ?? [];

    final mainContent = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: theme.brightness == Brightness.light
              ? [const Color(0xFFF1F5F9), const Color(0xFFFFFFFF)]
              : [const Color(0xFF0F172A), const Color(0xFF1E293B)],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Header Location summary Card
          _buildTripHeaderCard(theme, drive, dateString, startStr, endStr),

          const SizedBox(height: 16),

          // Tesla GPS map trace layout card using real historical locations
          _buildTeslaNavigationCard(theme, drive, locations),

          const SizedBox(height: 16),

          // Performance Statistics Row Grid
          _buildTelemetryStatGrid(theme, displayDistance, distLabel, displayAvgSpeed, displayMaxSpeed, velocityUnit, drive.duration),

          const SizedBox(height: 16),

          // Driving vs Stopped Time split ratio progress bar
          _buildTimeSplitCard(theme, drivingRatio, stoppedRatio, drive.duration - drive.stopTime, drive.stopTime),

          const SizedBox(height: 16),

          // Speed Profile Timeline line chart
          _buildSpeedProfileChart(theme, locations, displayAvgSpeed, displayMaxSpeed, velocityUnit),

          const SizedBox(height: 24),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isEmbedded,
        title: const Text('Ride Metrics Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever_rounded),
            color: Colors.redAccent,
            tooltip: 'Delete Ride Log',
            onPressed: () => _confirmDelete(context, historyVM, drive.id),
          ),
        ],
      ),
      body: mainContent,
    );
  }


  Widget _buildTripHeaderCard(
    ThemeData theme,
    ActivityModel drive,
    String dateString,
    String startStr,
    String endStr,
  ) {
    final bool isDark = theme.brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'COMPLETED TRIP LOG',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'ID: #${drive.id}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              dateString,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Column(
                  children: [
                    Icon(Icons.trip_origin_rounded, color: theme.colorScheme.primary, size: 20),
                    Container(width: 2, height: 30, color: Colors.grey.withValues(alpha: 0.3)),
                    const Icon(Icons.navigation_rounded, color: Colors.redAccent, size: 20),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Departed at $startStr',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'End',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Arrived at $endStr',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Custom painted route container using genuine coordinates data points
  Widget _buildTeslaNavigationCard(ThemeData theme, ActivityModel drive, List<ActivityLocation> locations) {
    final bool isDark = theme.brightness == Brightness.dark;
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        ),
        child: Stack(
          children: [
            if (locations.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_rounded, size: 40, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                    const SizedBox(height: 8),
                    Text(
                      'No GPS tracks captured for this short trip.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                    ),
                  ],
                ),
              )
            else
              Semantics(
                label: 'Map visualization showing path of the ride',
                value: '${locations.length} total GPS path trace points recorded.',
                child: CustomPaint(
                  size: const Size(double.infinity, 200),
                  painter: _MapTracePainter(
                    locations: locations,
                    brightness: theme.brightness,
                    primaryColor: theme.colorScheme.primary,
                    secondaryColor: theme.colorScheme.secondary,
                  ),
                ),
              ),
            // Floating Route Marker badges
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map_rounded, size: 14, color: Colors.blueAccent),
                    const SizedBox(width: 6),
                    Text(
                      locations.isNotEmpty ? 'GPS Route Trace (${locations.length} pts)' : 'No GPS Trace Map',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ),
            if (locations.isNotEmpty)
              Positioned(
                bottom: 16,
                right: 16,
                child: Row(
                  children: [
                    _buildMapBadge('Start', 'Start', theme),
                    const SizedBox(width: 8),
                    _buildMapBadge('End', 'End', theme),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildMapBadge(String pin, String label, ThemeData theme) {
    final bool isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 8,
            backgroundColor: pin == 'Start' ? theme.colorScheme.primary : Colors.redAccent,
            child: Text(
              pin.substring(0, 1),
              style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500),
          )
        ],
      ),
    );
  }

  Widget _buildTelemetryStatGrid(
    ThemeData theme,
    double distance,
    String distLabel,
    double avgSpeed,
    double maxSpeed,
    String speedLabel,
    int durationSeconds,
  ) {
    final bool isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final strokeColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final String hrMinString = _formatDuration(durationSeconds);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDetailsStatTile(
                theme,
                'DISTANCE',
                distance.toStringAsFixed(1),
                distLabel,
                Icons.alt_route_rounded,
                Colors.blueAccent,
                cardBg,
                strokeColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailsStatTile(
                theme,
                'DURATION',
                hrMinString.split(' ')[0],
                hrMinString.contains(' ') ? hrMinString.split(' ')[1] : 'sec',
                Icons.timelapse_rounded,
                const Color(0xFF10B981),
                cardBg,
                strokeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDetailsStatTile(
                theme,
                'AVG VELOCITY',
                avgSpeed.toStringAsFixed(0),
                speedLabel,
                Icons.query_stats_rounded,
                Colors.indigoAccent,
                cardBg,
                strokeColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailsStatTile(
                theme,
                'PEAK VELOCITY',
                maxSpeed.toStringAsFixed(0),
                speedLabel,
                Icons.electric_car_rounded,
                Colors.orangeAccent,
                cardBg,
                strokeColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsStatTile(
    ThemeData theme,
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
    Color bg,
    Color stroke,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSplitCard(
    ThemeData theme,
    double drivePct,
    double stopPct,
    int driveSec,
    int stopSec,
  ) {
    final bool isDark = theme.brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DRIVING VS STOPPED TIME RATIO',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    if (drivePct > 0)
                      Expanded(
                        flex: (drivePct * 100).round(),
                        child: Container(color: const Color(0xFF10B981)),
                      ),
                    if (stopPct > 0)
                      Expanded(
                        flex: (stopPct * 100).round(),
                        child: Container(color: Colors.orangeAccent),
                      ),
                    if (drivePct == 0 && stopPct == 0)
                      Expanded(
                        child: Container(color: Colors.grey.withValues(alpha: 0.3)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLegendItem('Driving (${(drivePct * 100).toStringAsFixed(0)}%)', _formatSeconds(driveSec), const Color(0xFF10B981), theme),
                _buildLegendItem('Stopped (${(stopPct * 100).toStringAsFixed(0)}%)', _formatSeconds(stopSec), Colors.orangeAccent, theme),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String title, String desc, Color color, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            Text(
              desc,
              style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildSpeedProfileChart(
    ThemeData theme,
    List<ActivityLocation> locations,
    double avgSpeed,
    double maxSpeed,
    String unit,
  ) {
    final bool isDark = theme.brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SPEED ANALYSIS PROFILE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'Peak: ${maxSpeed.toStringAsFixed(0)} $unit',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              width: double.infinity,
              child: Semantics(
                label: 'Speed Profile Chart',
                value: 'Average speed is ${avgSpeed.toStringAsFixed(1)} $unit. Peak speed reached ${maxSpeed.toStringAsFixed(0)} $unit.',
                child: CustomPaint(
                  painter: _SpeedGraphPainter(
                    locations: locations,
                    avgSpeed: avgSpeed,
                    maxSpeed: maxSpeed,
                    primaryColor: theme.colorScheme.primary,
                    brightness: theme.brightness,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Start', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                Text('Average speed: ${avgSpeed.toStringAsFixed(1)} $unit', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
                Text('End', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
              ],
            )
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '$minutes m';
  }

  String _formatSeconds(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainder = seconds % 60;
    if (minutes > 0) return '${minutes}m ${remainder}s';
    return '${seconds}s';
  }

  void _confirmDelete(BuildContext context, HistoryViewModel viewModel, int? driveId) {
    if (driveId == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Trip?'),
        content: const Text('This will delete this specific ride telemetry report from history permanently.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              await viewModel.deleteDrive(driveId);
              if (context.mounted) {
                context.pop(); // Pop back to history log
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Trip deleted successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Custom Painter draws a mockup GPS Route path mapping real physical lat/long points
class _MapTracePainter extends CustomPainter {
  final List<ActivityLocation> locations;
  final Brightness brightness;
  final Color primaryColor;
  final Color secondaryColor;

  _MapTracePainter({
    required this.locations,
    required this.brightness,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.04)
      ..strokeWidth = 1;

    // Draw Grid background
    const double step = 20;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paintGrid);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paintGrid);
    }

    if (locations.isEmpty) return;

    // Projection calculation: determine bounds
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (var loc in locations) {
      if (loc.latitude < minLat) minLat = loc.latitude;
      if (loc.latitude > maxLat) maxLat = loc.latitude;
      if (loc.longitude < minLng) minLng = loc.longitude;
      if (loc.longitude > maxLng) maxLng = loc.longitude;
    }

    final double latRange = maxLat - minLat;
    final double lngRange = maxLng - minLng;

    final double padding = 28.0;
    final double mapW = size.width - 2 * padding;
    final double mapH = size.height - 2 * padding;

    // Map each coordinate to canvas space
    final List<Offset> points = [];
    for (var loc in locations) {
      // Scale lat and lng ranges proportionally to the layout box
      final double x = padding + (latRange == 0 ? mapW / 2 : ((loc.latitude - minLat) / latRange) * mapW);
      // Invert Y because latitude grows upwards while canvas Y coordinates grow downwards
      final double y = padding + (lngRange == 0 ? mapH / 2 : (1.0 - ((loc.longitude - minLng) / lngRange)) * mapH);
      points.add(Offset(x, y));
    }

    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    // Glow under road line (dark mode helper)
    if (brightness == Brightness.dark && points.isNotEmpty) {
      final shadowPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawPath(path, shadowPaint);
    }

    // Active Road paint
    final roadPaint = Paint()
      ..shader = LinearGradient(
        colors: [primaryColor, secondaryColor],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, roadPaint);

    // Draw start and end pin locations
    if (points.length >= 2) {
      final start = points.first;
      final end = points.last;

      canvas.drawCircle(start, 5, Paint()..color = primaryColor..style = PaintingStyle.fill);
      canvas.drawCircle(start, 9, Paint()..color = primaryColor.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 1.5);

      canvas.drawCircle(end, 5, Paint()..color = Colors.redAccent..style = PaintingStyle.fill);
      canvas.drawCircle(end, 9, Paint()..color = Colors.redAccent.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom speed analysis profile chart painter (renders true dashboard speed traces)
class _SpeedGraphPainter extends CustomPainter {
  final List<ActivityLocation> locations;
  final double avgSpeed;
  final double maxSpeed;
  final Color primaryColor;
  final Brightness brightness;

  _SpeedGraphPainter({
    required this.locations,
    required this.avgSpeed,
    required this.maxSpeed,
    required this.primaryColor,
    required this.brightness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (avgSpeed == 0.0) return;

    final double width = size.width;
    final double height = size.height;

    // Draw back gridlines
    final gridPaint = Paint()
      ..color = brightness == Brightness.dark ? const Color(0xFF334155).withValues(alpha: 0.2) : Colors.grey[300]!.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    
    canvas.drawLine(Offset(0, height * 0.25), Offset(width, height * 0.25), gridPaint);
    canvas.drawLine(Offset(0, height * 0.5), Offset(width, height * 0.5), gridPaint);
    canvas.drawLine(Offset(0, height * 0.75), Offset(width, height * 0.75), gridPaint);

    final path = Path()..moveTo(0, height);
    final List<double> speeds = locations.map((loc) => loc.speed * 3.6).toList(); // convert to km/h

    if (speeds.length > 1) {
      final double stepX = width / (speeds.length - 1);
      final double denominator = maxSpeed > 0 ? maxSpeed : 1.0;
      for (int i = 0; i < speeds.length; i++) {
        final double x = i * stepX;
        final double speedRatio = (speeds[i] / denominator).clamp(0.0, 1.0);
        final double y = height - (height * speedRatio * 0.85); // keep 15% padding top
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
    } else {
      // Fallback synthetic graph if data path is empty
      final List<Offset> points = [
        const Offset(0.0, 1.0),
        const Offset(0.15, 0.45),
        const Offset(0.35, 0.3),
        const Offset(0.5, 0.95),
        const Offset(0.65, 0.2),
        const Offset(0.85, 0.4),
        const Offset(1.0, 1.0),
      ];
      for (int i = 0; i < points.length; i++) {
        final x = points[i].dx * width;
        final y = height - (height * (1.0 - points[i].dy));
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
    }

    // Draw shader area under curve
    final fillPath = Path.from(path)
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [primaryColor.withValues(alpha: 0.35), primaryColor.withValues(alpha: 0.0)],
      ).createShader(Offset.zero & size);

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Average Speed horizontal line
    final avgLine = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    final double avgRatio = maxSpeed > 0 ? (avgSpeed / maxSpeed).clamp(0.1, 0.95) : 0.5;
    final double avgY = height * (1.0 - avgRatio * 0.85);
    
    canvas.drawLine(Offset(0, avgY), Offset(width, avgY), avgLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

