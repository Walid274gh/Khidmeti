// lib/screens/home/widgets/worker_map_marker.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/worker_model.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import 'worker_preview_sheet.dart';

// ============================================================================
// MARKER
// ============================================================================

class WorkerMapMarker extends StatelessWidget {
  final WorkerModel worker;
  /// When true, renders a golden star marker — visually distinct from others.
  final bool isBest;

  const WorkerMapMarker({
    super.key,
    required this.worker,
    this.isBest = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Best-worker retains the distinctive warningAmber gold.
    // All other workers use the unified brand accent — getProfessionColor()
    // has been removed in favour of consistent visual identity.
    final color = isBest
        ? AppTheme.warningAmber
        : (isDark ? AppTheme.darkAccent : AppTheme.lightAccent);

    final icon  = AppTheme.getProfessionIcon(worker.profession);
    final size  = isBest ? 52.0 : 44.0;

    // [UI-FIX COLOR / C2]: was Colors.white (hardcoded primitive).
    // The bubble border sits on the map tile background — semantically it
    // needs "the colour that contrasts with the primary/accent fill".
    // colorScheme.onPrimary maps to white on this theme while remaining
    // themeable, matching the same fix already applied in pulsing_location_dot.
    final borderColor = Theme.of(context).colorScheme.onPrimary;

    return GestureDetector(
      onTap: () => _showPreview(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.topRight,
            clipBehavior: Clip.none,
            children: [
              // Bubble
              Container(
                width:  size,
                height: size,
                decoration: BoxDecoration(
                  color:  color,
                  shape:  BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: isBest ? 3.0 : 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:      color.withOpacity(isBest ? 0.70 : 0.55),
                      blurRadius: isBest ? 18 : 12,
                      offset:     const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: borderColor, size: isBest ? 24 : 21),
              ),
              // Star badge — only on best worker
              if (isBest)
                Positioned(
                  top:   -4,
                  right: -4,
                  child: Container(
                    // [UI-FIX SIZING]: was 18×18 — off 8dp grid.
                    // Snapped to iconSizeXs (16dp) — nearest on-grid value.
                    width:  AppConstants.iconSizeXs,
                    height: AppConstants.iconSizeXs,
                    decoration: BoxDecoration(
                      color: borderColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      // [UI-FIX ICON]: was Icons.star_rounded (raw icon).
                      // Replaced with AppIcons.ratingFilled (same glyph,
                      // now routed through the design system token).
                      child: Icon(
                        AppIcons.ratingFilled,
                        size:  11,
                        color: AppTheme.warningAmber,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Triangle pointer
          CustomPaint(
            size:    const Size(12, 7),
            painter: _PointerPainter(color: color),
          ),
        ],
      ),
    );
  }

  void _showPreview(BuildContext context) {
    showModalBottomSheet(
      context:              context,
      backgroundColor:      Colors.transparent,
      isScrollControlled:   true,
      builder: (_) => WorkerPreviewSheet(worker: worker),
    );
  }
}

// ── Triangle pointer painter ──────────────────────────────────────────────────

class _PointerPainter extends CustomPainter {
  final Color color;
  const _PointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
