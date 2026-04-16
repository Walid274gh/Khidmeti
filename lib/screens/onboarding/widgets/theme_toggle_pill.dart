// lib/screens/onboarding/widgets/theme_toggle_pill.dart
//
// Circular pill that toggles between light/dark/system theme.
// Cycles: system → light → dark → system.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/theme_provider.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';

class ThemeTogglePill extends ConsumerWidget {
  const ThemeTogglePill({super.key});

  ThemeMode _next(ThemeMode current) {
    switch (current) {
      case ThemeMode.system: return ThemeMode.light;
      case ThemeMode.light:  return ThemeMode.dark;
      case ThemeMode.dark:   return ThemeMode.system;
    }
  }

  IconData _iconFor(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return Icons.brightness_auto_rounded;
      case ThemeMode.light:  return Icons.light_mode_rounded;
      case ThemeMode.dark:   return Icons.dark_mode_rounded;
    }
  }

  String _labelFor(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return 'System theme';
      case ThemeMode.light:  return 'Light mode';
      case ThemeMode.dark:   return 'Dark mode';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode   = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label:  _labelFor(mode),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          ref.read(themeModeProvider.notifier).setThemeMode(_next(mode));
        },
        child: Container(
          width:  AppConstants.buttonHeightMd,
          height: AppConstants.buttonHeightMd,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? AppTheme.darkSurface
                : AppTheme.lightSurface,
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              width: 0.5,
            ),
          ),
          child: AnimatedSwitcher(
            duration: AppConstants.animDurationMicro,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child:   child,
            ),
            child: Icon(
              _iconFor(mode),
              key:   ValueKey(mode),
              size:  AppConstants.iconSizeSm,
              color: isDark
                  ? AppTheme.darkAccent
                  : AppTheme.lightAccent,
            ),
          ),
        ),
      ),
    );
  }
}
