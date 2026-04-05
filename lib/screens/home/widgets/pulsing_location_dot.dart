// lib/screens/home/widgets/pulsing_location_dot.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';

// ============================================================================
// PULSING LOCATION DOT
// ============================================================================

class PulsingLocationDot extends StatefulWidget {
  const PulsingLocationDot({super.key});

  @override
  State<PulsingLocationDot> createState() => _PulsingLocationDotState();
}

class _PulsingLocationDotState extends State<PulsingLocationDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;
  late Animation<double>   _opacity;

  static const Color _dotColor = AppTheme.cyanBlue;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _scale = Tween<double>(begin: 0.6, end: 2.2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // [UI-FIX COLOR]: was Colors.white (hardcoded).
    // The location dot always sits on the map (dark tile background), so
    // white is the correct semantic intent. Replaced with
    // colorScheme.onPrimary which maps to white on this app's dark/light
    // themes while remaining themeable.
    final borderColor = Theme.of(context).colorScheme.onPrimary;

    // [MANUAL FIX — S3]: dot diameter was 14dp — off the 8dp grid
    // (falls between iconSizeXs=16 and nothing below it).
    // Promoted to AppConstants.locationDotSize (16dp = nearest on-grid value).
    // The ripple ring uses the same base size via Transform.scale, so its
    // visual proportion is preserved. The MarkerLayer in home_map_background.dart
    // allocates 28×28dp for this marker — 16dp inner dot fits comfortably
    // inside that budget (leaves 6dp padding each side for the border + glow).
    final double dotSize = AppConstants.locationDotSize;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Ripple ring
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Transform.scale(
            scale: _scale.value,
            child: Container(
              width:  dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _dotColor.withOpacity(_opacity.value),
              ),
            ),
          ),
        ),

        // Solid dot
        Container(
          width:  dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            shape:  BoxShape.circle,
            color:  _dotColor,
            border: Border.all(color: borderColor, width: 2.5),
            boxShadow: [
              BoxShadow(
                color:        _dotColor.withOpacity(0.45),
                blurRadius:   8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
