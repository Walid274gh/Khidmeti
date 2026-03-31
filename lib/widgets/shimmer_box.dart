// lib/widgets/shimmer_box.dart

import 'package:flutter/material.dart';

class ShimmerBox extends StatelessWidget {
  final double  height;
  final double  borderRadius;
  final double  opacity;
  final double? width;

  const ShimmerBox({
    super.key,
    required this.height,
    required this.borderRadius,
    required this.opacity,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width:  width,
      height: height,
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black)
            .withOpacity(opacity * 0.1),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

