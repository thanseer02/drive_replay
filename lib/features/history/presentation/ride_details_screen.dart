import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:drive_tracker/features/history/viewmodel/history_viewmodel.dart';
import 'package:drive_tracker/features/settings/viewmodel/settings_viewmodel.dart';
import 'package:drive_tracker/models/ride.dart';

class RideDetailsScreen extends StatelessWidget {
  final int driveId;

  const RideDetailsScreen({
    super.key,
    required this.driveId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final historyVM = context.watch<HistoryViewModel>();
    final settingsVM = context.watch<SettingsViewModel>();

    // 1. Search for matching drive in histories
    Ride? drive;
    try {
      drive = historyVM.drives.firstWhere((d) => d.id == driveId);
    } catch (_) {
      // If not loaded, or not found: let's try to search inside DB. Or fallback.
    }

    // Unit settings
    final bool useMetric = settingsVM.useMetric;
    final double distMulti = useMetric ? 1.0 : 0.621371;
    final String velocityUnit = useMetric ? 'km/h' : 'mph';
    final String distLabel = useMetric ? 'km' : 'mi';

    if (drive == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ride Details')),
        body: const Center(child: Text('Drive log not found')),
      );
    }

    final double displayDistance = drive.distance * distMulti;
    final double totalHours = drive.durationSeconds / 3600.0;
    final double avgSpeed = totalHours > 0 ? (drive.distance / totalHours) : 0.0;
    final double maxSpeed = avgSpeed * 1.35 + 10; // Synthetic max speed relative to average
    
    final double displayAvgSpeed = avgSpeed * distMulti;
    final double displayMaxSpeed = maxSpeed * distMulti;
    
    final String dateString = DateFormat('EEEE, MMMM d, yyyy').format(drive.startTime);
    final String startStr = DateFormat('hh:mm:ss a').format(drive.startTime);
    final String endStr = DateFormat('hh:mm:ss a').format(drive.endTime ?? drive.startTime);

    // Compute mock Driving vs Stopped ratios (approx 80/20 split based on avg speed)
    final double drivingRatio = avgSpeed > 0 ? 0.78 + (min(avgSpeed, 80.0) / 80.0) * 0.15 : 0.0;
    final double stoppedRatio = (1.0 - drivingRatio).clamp(0.05, 1.0);
    final int drivingSeconds = (drive.durationSeconds * drivingRatio).round();
    final int stoppedSeconds = (drive.durationSeconds * stoppedRatio).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Metrics Summary'),
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
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Header Location summary Card
            _buildTripHeaderCard(theme, drive, dateString, startStr, endStr),

            const SizedBox(height: 16),

            // Tesla Mock GPS map trace layout card
            _buildTeslaNavigationCard(theme, drive),

            const SizedBox(height: 16),

            // Performance Statistics Row Grid
            _buildTelemetryStatGrid(theme, displayDistance, distLabel, displayAvgSpeed, displayMaxSpeed, velocityUnit, drive.durationSeconds),

            const SizedBox(height: 16),

            // Driving vs Stopped Time split ratio progress bar
            _buildTimeSplitCard(theme, drivingRatio, stoppedRatio, drivingSeconds, stoppedSeconds),

            const SizedBox(height: 16),

            // Speed Profile Timeline line chart
            _buildSpeedProfileChart(theme, displayAvgSpeed, displayMaxSpeed, velocityUnit),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTripHeaderCard(
    ThemeData theme,
    Ride drive,
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
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
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
                    Container(width: 2, height: 30, color: Colors.grey.withOpacity(0.3)),
                    const Icon(Icons.navigation_rounded, color: Colors.redAccent, size: 20),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drive.startLocation,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Departed at $startStr',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        drive.endLocation,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Arrived at $endStr',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
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

  // Custom painted mock route container
  Widget _buildTeslaNavigationCard(ThemeData theme, Ride drive) {
    final bool isDark = theme.brightness == Brightness.dark;
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        ),
        child: Stack(
          children: [
            // Custom paint dot grid representing maps
            CustomPaint(
              size: const Size(double.infinity, 180),
              painter: _MapTracePainter(
                brightness: theme.brightness,
                primaryColor: theme.colorScheme.primary,
                secondaryColor: theme.colorScheme.secondary,
              ),
            ),
            // Floating Route Marker badges
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B).withOpacity(0.85) : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.map_rounded, size: 14, color: Colors.blueAccent),
                    const SizedBox(width: 6),
                    Text(
                      'GPS Route Preview',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Row(
                children: [
                  _buildMapBadge('A', drive.startLocation, theme),
                  const SizedBox(width: 8),
                  _buildMapBadge('B', drive.endLocation, theme),
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
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.8) : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 8,
            backgroundColor: pin == 'A' ? theme.colorScheme.primary : Colors.redAccent,
            child: Text(
              pin,
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

  // Row and Grid statistic items
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
                '${distance.toStringAsFixed(1)}',
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
                '${avgSpeed.toStringAsFixed(0)}',
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
                '${maxSpeed.toStringAsFixed(0)}',
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
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
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
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Driving vs Stopped time indicator splits
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
            // Progress split bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 12,
                child: Row(
                  children: [
                    Expanded(
                      flex: (drivePct * 100).round(),
                      child: Container(color: const Color(0xFF10B981)),
                    ),
                    Expanded(
                      flex: (stopPct * 100).round(),
                      child: Container(color: Colors.orangeAccent),
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
              style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.5)),
            ),
          ],
        )
      ],
    );
  }

  // Speed Profile chart container (Tesla-styled outline curve)
  Widget _buildSpeedProfileChart(
    ThemeData theme,
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
            Container(
              height: 120,
              width: double.infinity,
              child: CustomPaint(
                painter: _SpeedGraphPainter(
                  avgSpeed: avgSpeed,
                  maxSpeed: maxSpeed,
                  primaryColor: theme.colorScheme.primary,
                  brightness: theme.brightness,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Start', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.4))),
                Text('Average speed: ${avgSpeed.toStringAsFixed(1)} $unit', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
                Text('End', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.4))),
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
    return '${minutes} m';
  }

  String _formatSeconds(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainder = seconds % 60;
    if (minutes > 0) return '${minutes}m ${remainder}s';
    return '${seconds}s';
  }
}

// Custom Painter draws a mockup GPS Route path matching modern vehicle trace UI
class _MapTracePainter extends CustomPainter {
  final Brightness brightness;
  final Color primaryColor;
  final Color secondaryColor;

  _MapTracePainter({
    required this.brightness,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = brightness == Brightness.dark
          ? Colors.white.withOpacity(0.04)
          : Colors.black.withOpacity(0.04)
      ..strokeWidth = 1;

    // Draw Grid background
    const double step = 20;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paintGrid);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paintGrid);
    }

    // Draw stylized curved road trace line
    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.65)
      ..cubicTo(
        size.width * 0.35, size.height * 0.15,
        size.width * 0.55, size.height * 0.95,
        size.width * 0.85, size.height * 0.35,
      );

    // Glow under road line (dark mode helper)
    if (brightness == Brightness.dark) {
      final shadowPaint = Paint()
        ..color = primaryColor.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawPath(path, shadowPaint);
    }

    // Active Road paint
    final roadPaint = Paint()
      ..shader = LinearGradient(
        colors: [primaryColor, secondaryColor],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, roadPaint);

    // Draw Start (Green) and End (Red Glow) circles overlay
    final pinPaintStart = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final pinPaintEnd = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.65), 7, pinPaintStart);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.65), 12, Paint()..color = primaryColor.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 2);

    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.35), 7, pinPaintEnd);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.35), 12, Paint()..color = Colors.redAccent.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom speed analysis profile chart painter (Garmin outlines)
class _SpeedGraphPainter extends CustomPainter {
  final double avgSpeed;
  final double maxSpeed;
  final Color primaryColor;
  final Brightness brightness;

  _SpeedGraphPainter({
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
      ..color = brightness == Brightness.dark ? const Color(0xFF334155).withOpacity(0.2) : Colors.grey[300]!.withOpacity(0.5)
      ..strokeWidth = 1;
    
    canvas.drawLine(Offset(0, height * 0.25), Offset(width, height * 0.25), gridPaint);
    canvas.drawLine(Offset(0, height * 0.5), Offset(width, height * 0.5), gridPaint);
    canvas.drawLine(Offset(0, height * 0.75), Offset(width, height * 0.75), gridPaint);

    // Build speed profile curve
    final path = Path()..moveTo(0, height);
    
    // Generate synthetic speed variations relative to averages
    final List<Offset> points = [];
    points.add(const Offset(0, 1.0)); // start slow
    points.add(Offset(width * 0.15, 0.45)); // accelerate
    points.add(Offset(width * 0.35, 0.3)); // speed up
    
    // Midpoint stop simulated
    points.add(Offset(width * 0.5, 0.95)); // stop wait
    points.add(Offset(width * 0.65, 0.2)); // peak speed
    points.add(Offset(width * 0.85, 0.4)); // slow down
    points.add(Offset(width, 1.0)); // end trip
    
    for (var pt in points) {
      // Scale height: Y coordinates range from y=0 (maxSpeed) to y=height (0 speed)
      final xVal = pt.dx;
      // Map Y: pt.dy = 0 means max value, pt.dy = 1.0 means 0 value.
      final yVal = height - (height * (1.0 - pt.dy)); 
      path.lineTo(xVal, yVal);
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
        colors: [primaryColor.withOpacity(0.35), primaryColor.withOpacity(0.0)],
      ).createShader(Offset.zero & size);

    canvas.drawPath(fillPath, fillPaint);

    // Main line paint
    final linePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Average Speed horizontal line
    final avgLine = Paint()
      ..color = const Color(0xFF10B981).withOpacity(0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    // Convert average speed ratio to Y
    final double avgRatio = (avgSpeed / maxSpeed).clamp(0.1, 0.95);
    final double avgY = height * (1.0 - avgRatio);
    
    // Draw dashed/solid average line
    canvas.drawLine(Offset(0, avgY), Offset(width, avgY), avgLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
