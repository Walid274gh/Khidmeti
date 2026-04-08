// lib/screens/service_request/widgets/location_visual.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';
import '../../../providers/service_request_form_controller.dart';

// ============================================================================
// LOCATION VISUAL
// Creative location representation — no map tiles, no API key required.
//
// States:
//   • idle       → muted rings + grey pin, subtle grid
//   • detecting  → animated pulsing rings + spinner overlay on pin
//   • detected   → accent rings + solid pin + address + coordinates
//   • error/denied → red-tinted rings + error indicator
//
// Design: three concentric rings emanate outward from a central pin,
// with a subtle dot-grid background. Pure Flutter, offline-capable.
// ============================================================================

class LocationVisual extends StatefulWidget {
  final LocationDetectionStatus status;
  final double? latitude;
  final double? longitude;
  final String address;
  final Color accentColor;
  final bool isDark;

  const LocationVisual({
    super.key,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.accentColor,
    required this.isDark,
  });

  @override
  State<LocationVisual> createState() => _LocationVisualState();
}

class _LocationVisualState extends State<LocationVisual>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _anim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeOut),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(LocationVisual old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status) _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.status == LocationDetectionStatus.detecting) {
      _pulse.repeat();
    } else {
      _pulse.stop();
      _pulse.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  bool get _isDetected =>
      widget.status == LocationDetectionStatus.detected;
  bool get _isDetecting =>
      widget.status == LocationDetectionStatus.detecting;
  bool get _isFailed =>
      widget.status == LocationDetectionStatus.denied ||
      widget.status == LocationDetectionStatus.error;

  Color get _ringColor {
    if (_isDetected) return widget.accentColor;
    if (_isFailed) return AppTheme.signOutRed;
    if (_isDetecting) return widget.accentColor;
    return widget.isDark
        ? AppTheme.darkBorder
        : AppTheme.lightBorder;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Visual canvas ───────────────────────────────────────────
        SizedBox(
          height: 140,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConstants.radiusLg),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Dot-grid background
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DotGridPainter(
                      color: (_isDetected
                              ? widget.accentColor
                              : widget.isDark
                                  ? AppTheme.darkBorder
                                  : AppTheme.lightBorder)
                          .withOpacity(0.18),
                    ),
                  ),
                ),

                // Animated rings
                AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) {
                    if (_isDetecting) {
                      // Pulsing rings during detection
                      return CustomPaint(
                        size: const Size(140, 140),
                        painter: _RingPainter(
                          progress: _anim.value,
                          color: _ringColor,
                          ringCount: 3,
                          animated: true,
                        ),
                      );
                    }
                    // Static rings when detected / idle / error
                    return CustomPaint(
                      size: const Size(140, 140),
                      painter: _RingPainter(
                        progress: 1.0,
                        color: _ringColor,
                        ringCount: 3,
                        animated: false,
                        opacity: _isDetected ? 0.20 : 0.10,
                      ),
                    );
                  },
                ),

                // Central pin
                _CentralPin(
                  isDetected: _isDetected,
                  isDetecting: _isDetecting,
                  isFailed: _isFailed,
                  accentColor: widget.accentColor,
                  isDark: widget.isDark,
                ),
              ],
            ),
          ),
        ),

        // ── Address footer ──────────────────────────────────────────
        _AddressFooter(
          status: widget.status,
          address: widget.address,
          latitude: widget.latitude,
          longitude: widget.longitude,
          accentColor: widget.accentColor,
          isDark: widget.isDark,
        ),
      ],
    );
  }
}

// ── Central pin ───────────────────────────────────────────────────────────────

class _CentralPin extends StatelessWidget {
  final bool isDetected;
  final bool isDetecting;
  final bool isFailed;
  final Color accentColor;
  final bool isDark;

  const _CentralPin({
    required this.isDetected,
    required this.isDetecting,
    required this.isFailed,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isFailed
        ? AppTheme.signOutRed
        : isDetected
            ? Colors.white
            : (isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText);

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDetected
            ? accentColor
            : (isDark
                ? AppTheme.darkSurface
                : AppTheme.lightSurface),
        border: Border.all(
          color: isFailed
              ? AppTheme.signOutRed.withOpacity(0.5)
              : isDetected
                  ? accentColor.withOpacity(0.6)
                  : (isDark
                      ? AppTheme.darkBorder
                      : AppTheme.lightBorder),
          width: 1.5,
        ),
        boxShadow: isDetected
            ? [
                BoxShadow(
                  color: accentColor.withOpacity(0.30),
                  blurRadius: 16,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: isDetecting
          ? Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accentColor,
                ),
              ),
            )
          : Icon(
              isFailed
                  ? Icons.location_off_rounded
                  : isDetected
                      ? AppIcons.location
                      : Icons.location_searching_rounded,
              size: 22,
              color: iconColor,
            ),
    );
  }
}

// ── Address footer ────────────────────────────────────────────────────────────

class _AddressFooter extends StatelessWidget {
  final LocationDetectionStatus status;
  final String address;
  final double? latitude;
  final double? longitude;
  final Color accentColor;
  final bool isDark;

  const _AddressFooter({
    required this.status,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.accentColor,
    required this.isDark,
  });

  bool get _isDetected => status == LocationDetectionStatus.detected;
  bool get _isDetecting => status == LocationDetectionStatus.detecting;
  bool get _isFailed =>
      status == LocationDetectionStatus.denied ||
      status == LocationDetectionStatus.error;

  @override
  Widget build(BuildContext context) {
    final String statusText;
    final Color statusColor;

    if (_isDetecting) {
      statusText = context.tr('request_form.location_detecting');
      statusColor = accentColor;
    } else if (_isDetected) {
      statusText = address.isNotEmpty
          ? address
          : context.tr('request_form.location_detected');
      statusColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    } else if (_isFailed) {
      statusText = context.tr('request_form.location_denied');
      statusColor = AppTheme.signOutRed;
    } else {
      statusText = context.tr('request_form.location_idle');
      statusColor = isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMd,
        vertical: AppConstants.spacingMd,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkSurface.withOpacity(0.5)
            : AppTheme.lightSurface.withOpacity(0.8),
        border: Border(
          top: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status dot
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(right: 7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isDetected
                      ? (isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess)
                      : _isFailed
                          ? AppTheme.signOutRed
                          : (isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText),
                ),
              ),
              Expanded(
                child: Text(
                  statusText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: _isDetected
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Coordinates badge — [C1] FIX: fontSizeXs (10dp) → fontSizeXxs (11dp)
          // [MANUAL] FIX: raw 'monospace' string → AppConstants.monoFontFamily
          if (_isDetected && latitude != null) ...[
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontFamily: AppConstants.monoFontFamily,
                    fontSize: AppConstants.fontSizeXxs,
                    color: accentColor.withOpacity(0.65),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── CustomPainters ────────────────────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  final Color color;
  const _DotGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const step = 20.0;
    const radius = 1.5;

    for (double x = step; x < size.width; x += step) {
      for (double y = step; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.color != color;
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final int ringCount;
  final bool animated;
  final double opacity;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.ringCount,
    required this.animated,
    this.opacity = 0.15,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;

    for (int i = 0; i < ringCount; i++) {
      final fraction = (i + 1) / ringCount;

      double ringProgress;
      double ringOpacity;

      if (animated) {
        // Staggered pulsing rings
        final offset = i * 0.25;
        final adjusted = ((progress - offset) % 1.0).clamp(0.0, 1.0);
        ringProgress = adjusted;
        ringOpacity = (1.0 - adjusted) * 0.35;
      } else {
        ringProgress = fraction;
        ringOpacity = opacity * (1.0 - fraction * 0.4);
      }

      final radius = maxRadius * (animated ? ringProgress : fraction);
      if (radius <= 0) continue;

      final paint = Paint()
        ..color = color.withOpacity(ringOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = animated ? 1.5 : 1.0;

      canvas.drawCircle(center, radius, paint);

      if (!animated) {
        // Fill
        final fillPaint = Paint()
          ..color = color.withOpacity(ringOpacity * 0.4)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, radius, fillPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
