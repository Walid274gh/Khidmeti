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
      width:  64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent,
        boxShadow: [
          BoxShadow(
            color:       accent.withOpacity(0.35),
            blurRadius:  40,
            spreadRadius: 0,
            offset:      const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        AppIcons.home,
        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        size:  30,
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
