import 'dart:io';
import 'dart:math';
import 'package:image/image.dart';

void main() {
  final outDir = Directory('web/icons');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);
  final size = 1024;

  final image = Image(size, size);

  // Background gradient
  for (var y = 0; y < size; y++) {
    final t = y / (size - 1);
    final r = (33 + (90 - 33) * t).toInt();
    final g = (150 + (210 - 150) * t).toInt();
    final b = (255 + (255 - 255) * t).toInt();
    fillRect(image, 0, y, size - 1, y, getColor(r, g, b));
  }

  // Road shape
  final road = drawPath(image, [
    Point(0.20 * size, 0.45 * size),
    Point(0.80 * size, 0.45 * size),
    Point(0.75 * size, 0.35 * size),
    Point(0.25 * size, 0.35 * size),
  ], color: getColor(255, 255, 255), width: 160);

  fillConvexPolygon(image, [
    Point(0.24 * size, 0.74 * size),
    Point(0.76 * size, 0.74 * size),
    Point(0.88 * size, 0.58 * size),
    Point(0.64 * size, 0.38 * size),
    Point(0.36 * size, 0.38 * size),
    Point(0.18 * size, 0.58 * size),
  ], getColor(11, 85, 167));

  // Headlight accent
  fillCircle(image, (0.30 * size).toInt(), (0.60 * size).toInt(), 36, getColor(255, 242, 0));
  fillCircle(image, (0.70 * size).toInt(), (0.60 * size).toInt(), 36, getColor(255, 242, 0));

  final file = File('${outDir.path}/Icon-512.png');
  file.writeAsBytesSync(encodePng(image));
  print('Generated ${file.path}');
}
