// lib/screens/home/widgets/location_address_display.dart
//
// Midnight Rose v2.0: FontWeight.w500 → w400

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';

// ============================================================================
// LOCATION ADDRESS DISPLAY
// ============================================================================

class LocationAddressDisplay extends StatelessWidget {
  final String? address;

  const LocationAddressDisplay({super.key, required this.address});

  @override
  Widget build(BuildContext context) {
    if (address == null || address!.isEmpty) {
      return const _AddressShimmer();
    }
    return _AddressText(address: address!);
  }
}

// ── Shimmer placeholder ───────────────────────────────────────────────────────

class _AddressShimmer extends StatefulWidget {
  const _AddressShimmer();

  @override
  State<_AddressShimmer> createState() => _AddressShimmerState();
}

class _AddressShimmerState extends State<_AddressShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width:  120,
        height: 12,
        decoration: BoxDecoration(
          // [UI-FIX COLOR]: was (isDark ? Colors.white : Colors.black).withOpacity(...)
          // — hardcoded primitives. Replaced with darkText / lightText tokens
          // so the shimmer pulse is expressed in the theme's actual text colour.
          color: (isDark ? AppTheme.darkText : AppTheme.lightText)
              .withOpacity(_anim.value * 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

// ── Resolved text ─────────────────────────────────────────────────────────────

class _AddressText extends StatefulWidget {
  final String address;

  const _AddressText({super.key, required this.address});

  @override
  State<_AddressText> createState() => _AddressTextState();
}

class _AddressTextState extends State<_AddressText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppTheme.darkAccent    : AppTheme.lightAccent;
    final textColor = isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;

    return FadeTransition(
      opacity: _fade,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.location, size: 13, color: iconColor),
          // [UI-FIX SPACING]: was SizedBox(width: 4) — raw px.
          // Replaced with AppConstants.spacingXs (4dp — same value, now tokenised).
          const SizedBox(width: AppConstants.spacingXs),
          Flexible(
            child: Text(
              widget.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:      textColor,
                    fontWeight: FontWeight.w400,   // was w500 — forbidden
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
