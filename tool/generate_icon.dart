import 'dart:io';
import 'package:image/image.dart';

void main() {
  final outDir = Directory('web/icons');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);
  final size = 1024;

  final image = Image(width: size, height: size);

  // Background gradient
  for (var y = 0; y < size; y++) {
    final t = y / (size - 1);
    final r = (33 + (90 - 33) * t).toInt();
    final g = (150 + (210 - 150) * t).toInt();
    final b = (255 + (255 - 255) * t).toInt();
    fillRect(image, x1: 0, y1: y, x2: size - 1, y2: y, color: ColorRgb8(r, g, b));
  }

  // Road shape
  drawPolygon(image, vertices: [
    Point(0.20 * size, 0.45 * size),
    Point(0.80 * size, 0.45 * size),
    Point(0.75 * size, 0.35 * size),
    Point(0.25 * size, 0.35 * size),
  ], color: ColorRgb8(255, 255, 255), thickness: 160);

  fillPolygon(image, vertices: [
    Point(0.24 * size, 0.74 * size),
    Point(0.76 * size, 0.74 * size),
    Point(0.88 * size, 0.58 * size),
    Point(0.64 * size, 0.38 * size),
    Point(0.36 * size, 0.38 * size),
    Point(0.18 * size, 0.58 * size),
  ], color: ColorRgb8(11, 85, 167));

  // Headlight accent
  fillCircle(image, x: (0.30 * size).toInt(), y: (0.60 * size).toInt(), radius: 36, color: ColorRgb8(255, 242, 0));
  fillCircle(image, x: (0.70 * size).toInt(), y: (0.60 * size).toInt(), radius: 36, color: ColorRgb8(255, 242, 0));

  final file = File('${outDir.path}/Icon-512.png');
  file.writeAsBytesSync(encodePng(image));
  // ignore: avoid_print
  print('Generated ${file.path}');
}
