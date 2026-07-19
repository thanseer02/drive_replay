import 'package:flutter/material.dart';

class AnimatedNumber extends StatelessWidget {
  final double value;
  final String suffix;
  final String prefix;
  final TextStyle? style;
  final Duration duration;
  final int precision;

  const AnimatedNumber({
    super.key,
    required this.value,
    this.suffix = '',
    this.prefix = '',
    this.style,
    this.duration = const Duration(milliseconds: 750),
    this.precision = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value),
      duration: duration,
      curve: Curves.easeOutExpo,
      builder: (context, animValue, child) {
        String formatted = precision == 0 
            ? animValue.round().toString() 
            : animValue.toStringAsFixed(precision);
        return RichText(
          text: TextSpan(
            style: style ?? DefaultTextStyle.of(context).style,
            children: [
              if (prefix.isNotEmpty) TextSpan(text: prefix),
              TextSpan(text: formatted),
              if (suffix.isNotEmpty)
                TextSpan(
                  text: suffix,
                  style: TextStyle(
                    fontSize: (style?.fontSize ?? 14) * 0.55,
                    fontWeight: FontWeight.normal,
                    color: (style?.color ?? Colors.white).withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
