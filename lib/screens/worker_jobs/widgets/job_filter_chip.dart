// lib/screens/worker_jobs/widgets/job_filter_chip.dart

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';

class JobFilterChip extends StatelessWidget {
  final String     label;
  final int        count;
  final bool       isActive;
  final bool       isDark;
  final Color      accentColor;
  final VoidCallback onTap;

  const JobFilterChip({
    super.key,
    required this.label,
    required this.count,
    required this.isActive,
    required this.isDark,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button:   true,
      label:    '$label ($count)',
      selected: isActive,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve:    Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? accentColor.withOpacity(0.18)
                // [TOKEN FIX]: was AppTheme.darkSurface.withOpacity(0.5) /
                // Colors.white.withOpacity(0.7). Dark half-opacity surface
                // replaced with baked token AppTheme.darkSurfaceHalf.
                : (isDark
                    ? AppTheme.darkSurfaceHalf
                    : Colors.white.withOpacity(0.7)),
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: Border.all(
              color: isActive
                  ? accentColor.withOpacity(0.7)
                  // [TOKEN FIX]: was Colors.white/black.withOpacity(0.08) —
                  // replaced with baked tokens darkCardBorderOverlay /
                  // lightCardBorderOverlay.
                  : (isDark
                      ? AppTheme.darkCardBorderOverlay
                      : AppTheme.lightCardBorderOverlay),
              width: isActive ? 1.5 : 1.0,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color:      accentColor.withOpacity(0.15),
                      blurRadius: 8,
                      offset:     const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isActive
                          ? accentColor
                          : (isDark
                              ? AppTheme.darkSecondaryText
                              : AppTheme.lightSecondaryText),
                      fontWeight: isActive
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isActive
                        ? accentColor
                        : (isDark
                            ? Colors.white.withOpacity(0.12)
                            : Colors.black.withOpacity(0.08)),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '$count',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isActive
                              ? Colors.white
                              : (isDark
                                  ? AppTheme.darkSecondaryText
                                  : AppTheme.lightSecondaryText),
                          fontWeight: FontWeight.w700,
                          fontSize:   10,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
