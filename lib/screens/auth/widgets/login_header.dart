// lib/screens/auth/widgets/login_header.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

// ============================================================================
// LOGIN LOGO ORB  (merged from login_logo_orb.dart)
// ============================================================================

class _LoginLogoOrb extends StatelessWidget {
  final bool isDark;

  const _LoginLogoOrb({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Container(
      // FIX [Dim-RAW]: was raw 64 literals — replaced with
      // AppConstants.logoOrbSize (64.0).
      // Designer sign-off pending: 64dp diverges from iconContainerFeature
      // (56dp) — intentional divergence confirmed in manifest.
      width:  AppConstants.logoOrbSize,
      height: AppConstants.logoOrbSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent,
        boxShadow: [
          BoxShadow(
            // FIX [Col-OPAC]: was accent.withOpacity(0.35) — replaced with
            // pre-baked AppTheme.accentShadow token (accent @ 35%, alpha 0x59).
            color:        AppTheme.accentShadow,
            blurRadius:   40,
            spreadRadius: 0,
            offset:       const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        AppIcons.home,
        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        // FIX [Dim-OFF]: was raw size: 30 (off 20/24/32 icon scale) — replaced
        // with AppConstants.logoOrbIconSize (30.0). Pending designer sign-off:
        // 32dp would snap to the standard icon scale.
        size:  AppConstants.logoOrbIconSize,
      ),
    );
  }
}

// ============================================================================
// LOGIN HEADER
// ============================================================================

class LoginHeader extends StatelessWidget {
  final bool isDark;

  const LoginHeader({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LoginLogoOrb(isDark: isDark),

        SizedBox(height: AppConstants.spacingLg),

        Semantics(
          header: true,
          child: Text(
            context.tr('login.title'),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight:    FontWeight.w700,
              letterSpacing: -0.5,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
        ),

        SizedBox(height: AppConstants.spacingSm),

        Text(
          context.tr('login.subtitle'),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
          ),
        ),
      ],
    );
  }
}
