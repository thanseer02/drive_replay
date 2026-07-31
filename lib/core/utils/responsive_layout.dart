import 'package:flutter/widgets.dart';

extension ResponsiveLayout on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;
  bool get isDesktop => screenWidth >= 1200;

  // Responsive sizing helpers
  double heightPercent(double percent) => screenHeight * (percent / 100);
  double widthPercent(double percent) => screenWidth * (percent / 100);
}
