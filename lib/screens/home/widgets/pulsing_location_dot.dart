// lib/screens/home/widgets/pulsing_location_dot.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';

// ============================================================================
// PULSING LOCATION DOT
//
// authOrbBlue deleted — use cyanBlue (0xFF06B6D4) which is kept as a
// functional location/map colour and visually identical.
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

  // Dot colour — cyanBlue replaces deleted authOrbBlue
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
    return Stack(
      alignment: Alignment.center,
      children: [
        // Ripple ring
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Transform.scale(
            scale: _scale.value,
            child: Container(
              width:  14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _dotColor.withOpacity(_opacity.value),
              ),
            ),
          ),
        ),

        // Solid dot
        Container(
          width:  14,
          height: 14,
          decoration: BoxDecoration(
            shape:  BoxShape.circle,
            color:  _dotColor,
            border: Border.all(color: Colors.white, width: 2.5),
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
