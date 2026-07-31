import 'dart:math';
import 'package:flutter/material.dart';
import 'package:drive_replay/core/services/local_db/app_database.dart';

class RoutePainter extends CustomPainter {
  final List<TripPoint> points;
  final double currentLat;
  final double currentLng;
  final double currentHeading;

  RoutePainter({
    required this.points,
    required this.currentLat,
    required this.currentLng,
    required this.currentHeading,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // 1. Calculate Bounding Box
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    // Add padding to bounding box
    final latRange = max(maxLat - minLat, 0.0001);
    final lngRange = max(maxLng - minLng, 0.0001);
    
    minLat -= latRange * 0.1;
    maxLat += latRange * 0.1;
    minLng -= lngRange * 0.1;
    maxLng += lngRange * 0.1;

    // Helper to map LatLng to Canvas XY
    Offset toCanvas(double lat, double lng) {
      final x = ((lng - minLng) / (maxLng - minLng)) * size.width;
      final y = size.height - (((lat - minLat) / (maxLat - minLat)) * size.height); // Invert Y
      return Offset(x, y);
    }

    // 2. Draw Route Polyline
    final routePaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.8)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    bool first = true;
    for (var p in points) {
      final offset = toCanvas(p.latitude, p.longitude);
      if (first) {
        path.moveTo(offset.dx, offset.dy);
        first = false;
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }
    
    // Add glow
    final glowPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.2)
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
      
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, routePaint);

    // 3. Draw Current Position Marker (Car)
    final markerPos = toCanvas(currentLat, currentLng);
    
    canvas.save();
    canvas.translate(markerPos.dx, markerPos.dy);
    // Rotate canvas based on heading (0 is North -> Up)
    canvas.rotate(currentHeading * (pi / 180));
    
    final markerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
      
    final markerShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    // Draw simple chevron for car
    final carPath = Path()
      ..moveTo(0, -15)
      ..lineTo(10, 15)
      ..lineTo(0, 8)
      ..lineTo(-10, 15)
      ..close();
      
    canvas.drawPath(carPath, markerShadow);
    canvas.drawPath(carPath, markerPaint);
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RoutePainter oldDelegate) {
    return oldDelegate.currentLat != currentLat ||
           oldDelegate.currentLng != currentLng ||
           oldDelegate.currentHeading != currentHeading ||
           oldDelegate.points.length != points.length;
  }
}
