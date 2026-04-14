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

const double _kBadgeIconSize = 12.0;

// [MANUAL FIX S-TOKEN]: marker border widths are now named constants.
// Regular marker: was 2.5 — off-grid, no token. Snapped to
//   AppConstants.borderWidthSelected (1.5) which is the on-grid "selected/emphasis"
//   border weight. Map markers are visually prominent elements — borderWidthSelected
//   is the correct semantic choice.
// Best marker: was 3.0 — intentionally thicker to distinguish the best worker.
//   Promoted to a file-local token so the value is documented and easy to change
//   in one place. Not added to AppConstants because it is map-marker–specific.
const double _kBestMarkerBorderWidth = 3.0;

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

    final color = isBest
        ? AppTheme.warningAmber
        : (isDark ? AppTheme.darkAccent : AppTheme.lightAccent);

    final icon = AppTheme.getProfessionIcon(worker.profession!);
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
                    // [MANUAL FIX]: was isBest ? 3.0 : 2.5 — 2.5 had no token.
                    // Best marker keeps _kBestMarkerBorderWidth (3.0, file-local token).
                    // Regular marker snapped to AppConstants.borderWidthSelected (1.5).
                    width: isBest
                        ? _kBestMarkerBorderWidth
                        : AppConstants.borderWidthSelected,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:      color.withOpacity(isBest ? 0.70 : 0.55),
                      blurRadius: isBest ? 18 : 12,
                      offset:     const Offset(0, 3),
                    ),
                  ],
                ),
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
