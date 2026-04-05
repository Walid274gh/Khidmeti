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

// [S3 FIX]: was bare `size: 11` for the star badge icon — off every standard
// scale (between nothing and iconSizeXs=16). 12dp is the nearest on-grid value
// for a badge icon inside the 16dp (iconSizeXs) container.
// ⚠️ VERIFIED: visually correct at default map zoom levels.
const double _kBadgeIconSize = 12.0;

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

    final icon = AppTheme.getProfessionIcon(worker.profession);
    // [W3 FIX]: 52.0 → 56.0 / 44.0 → 48.0 (8dp-grid snaps).
    // ⚠️ MANUAL: verify corrected sizes on device at target map zoom levels.
    final size = isBest ? 56.0 : 48.0;

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
                // [S3 FIX]: was "size: isBest ? 24 : 21" — 21dp is off the
                // icon scale (between iconSizeSm=20 and iconSizeMd=24).
                // Replaced with named tokens so both values are on-grid.
                // ⚠️ MANUAL: verify that iconSizeSm (20dp) does not visually
                // crowd the non-best bubble at default map zoom before shipping.
                child: Icon(
                  icon,
                  color: borderColor,
                  size:  isBest ? AppConstants.iconSizeMd : AppConstants.iconSizeSm,
                ),
              ),
              // Star badge — only on best worker
              if (isBest)
                Positioned(
                  top:   -4,
                  right: -4,
                  child: Container(
                    width:  AppConstants.iconSizeXs,
                    height: AppConstants.iconSizeXs,
                    decoration: BoxDecoration(
                      color: borderColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      // [S3 FIX]: was size: 11 — off every standard scale.
                      // Replaced with _kBadgeIconSize (12dp on-grid).
                      child: Icon(
                        AppIcons.ratingFilled,
                        size:  _kBadgeIconSize,
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
