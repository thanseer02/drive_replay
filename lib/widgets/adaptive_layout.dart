import 'package:flutter/material.dart';

/// Adaptive layout breakpoint.
const double kTabletBreakpoint = 720.0;

/// Determines if the current screen is tablet-sized.
bool isTablet(BuildContext context) {
  return MediaQuery.sizeOf(context).width >= kTabletBreakpoint;
}

/// Determines if the device is in landscape orientation.
bool isLandscape(BuildContext context) {
  return MediaQuery.orientationOf(context) == Orientation.landscape;
}

/// A layout builder that provides phone vs tablet/landscape layout variants.
///
/// ```dart
/// AdaptiveLayout(
///   phone: SingleColumnContent(),
///   tablet: TwoColumnContent(),
/// )
/// ```
class AdaptiveLayout extends StatelessWidget {
  /// Widget shown on phone in portrait (< 720 dp).
  final Widget phone;

  /// Widget shown on tablets or landscape phones (≥ 720 dp or landscape).
  /// Falls back to [phone] if not provided.
  final Widget? tablet;

  const AdaptiveLayout({
    super.key,
    required this.phone,
    this.tablet,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool wide = constraints.maxWidth >= kTabletBreakpoint;
        if (wide && tablet != null) {
          return tablet!;
        }
        return phone;
      },
    );
  }
}

/// A two-column layout wrapper used on tablet/landscape.
/// Places [left] and [right] side-by-side with an optional [divider].
class TwoColumnLayout extends StatelessWidget {
  final Widget left;
  final Widget right;
  final double leftFlex;
  final double rightFlex;
  final bool showDivider;

  const TwoColumnLayout({
    super.key,
    required this.left,
    required this.right,
    this.leftFlex = 1.0,
    this.rightFlex = 1.0,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: (leftFlex * 10).round(),
          child: left,
        ),
        if (showDivider)
          VerticalDivider(
            width: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        Expanded(
          flex: (rightFlex * 10).round(),
          child: right,
        ),
      ],
    );
  }
}
