import 'package:flutter/material.dart';

class AnimatedDuration extends StatelessWidget {
  final int seconds;
  final TextStyle? style;
  final Duration duration;

  const AnimatedDuration({
    super.key,
    required this.seconds,
    this.style,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: seconds.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        final totalSeconds = animValue.round();
        final int h = totalSeconds ~/ 3600;
        final int m = (totalSeconds % 3600) ~/ 60;
        final int s = totalSeconds % 60;

        String formattedStr;
        if (h > 0) {
          formattedStr = '${h}h ${m}m ${s}s';
        } else if (m > 0) {
          formattedStr = '${m}m ${s}s';
        } else {
          formattedStr = '${s}s';
        }

        return Text(
          formattedStr,
          style: style,
        );
      },
    );
  }
}
