// lib/screens/auth/widgets/auth_background.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';

class AuthBackground extends StatelessWidget {
  final bool isDark;

  const AuthBackground({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppTheme.darkAuthHeroTop, AppTheme.darkBackground]
                // FIX [H6]: was Colors.white (hardcoded) — replaced with
                // AppTheme.lightSurface (#FFFFFF). Visually identical but
                // semantically correct and respects the token system.
                // Verify on a physical device before shipping.
                : [AppTheme.lightSurface, AppTheme.lightBackground],
          ),
        ),
        child: IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, -1.2),
                radius: 1.0,
                colors: [
                  // FIX [H4]: was (isDark ? darkAccent : lightAccent)
                  // .withOpacity(isDark ? 0.18 : 0.07) — replaced with
                  // pre-baked const tokens darkAccentHalo / lightAccentHalo.
                  isDark ? AppTheme.darkAccentHalo : AppTheme.lightAccentHalo,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
