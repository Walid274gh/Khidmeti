// lib/screens/home/widgets/home_cta_button.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

// ============================================================================
// HOME CTA BUTTON — Design C: square icon + title + subtitle + pill badge
// ============================================================================

class HomeCtaButton extends StatefulWidget {
  const HomeCtaButton({super.key});

  @override
  State<HomeCtaButton> createState() => _HomeCtaButtonState();
}

class _HomeCtaButtonState extends State<HomeCtaButton> {
  bool _pressed = false;

  void _onTap(BuildContext context) {
    HapticFeedback.mediumImpact();
    context.push(AppRoutes.serviceRequest, extra: {'isEmergency': false});
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final accent  = isDark ? AppTheme.darkAccent  : AppTheme.lightAccent;
    final surface = isDark ? AppTheme.darkSurface  : AppTheme.lightSurface;
    final border  = isDark ? AppTheme.darkBorder   : AppTheme.lightBorder;
    final text    = isDark ? AppTheme.darkText      : AppTheme.lightText;
    final subtext = isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;

    return Semantics(
      button: true,
      label:  context.tr('home.cta_schedule'),
      child: GestureDetector(
        onTapDown:   (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          _onTap(context);
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale:    _pressed ? 0.974 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: Container(
            height: AppConstants.buttonHeight,
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkSurface.withOpacity(0.60)
                  : AppTheme.lightSurfaceVariant,
              // [UI-FIX RADIUS]: was BorderRadius.circular(16) — raw value.
              // Replaced with AppConstants.radiusLg (16dp — same value,
              // now linked to the design system token).
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              border:       Border.all(color: border, width: 0.5),
            ),
            child: Row(
              children: [
                const SizedBox(width: AppConstants.paddingSm + 2),

                // Square icon
                Container(
                  width:  38,
                  height: 38,
                  decoration: BoxDecoration(
                    color:        accent.withOpacity(isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    border: Border.all(
                      color: accent.withOpacity(isDark ? 0.25 : 0.20),
                      width: 0.5,
                    ),
                  ),
                  child: Icon(
                    AppIcons.requests,
                    color: accent,
                    size:  20,
                  ),
                ),

                const SizedBox(width: AppConstants.spacingSm + 2),

                // Title + subtitle
                Expanded(
                  child: Column(
                    mainAxisAlignment:  MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('home.cta_schedule'),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color:         text,
                              fontWeight:    FontWeight.w700,
                              letterSpacing: -0.3,
                              height:        1.1,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr('home.cta_schedule_sub'),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: subtext,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Pill badge
                Container(
                  margin: const EdgeInsets.only(
                      right: AppConstants.paddingSm + 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingMd,
                    vertical:   AppConstants.spacingXs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: accent,
                    // [UI-FIX RADIUS]: was BorderRadius.circular(50) — magic number.
                    // Replaced with AppConstants.radiusCircle (fully rounded pill).
                    borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
                  ),
                  child: Text(
                    context.tr('home.cta_new'),
                    style: TextStyle(
                      fontSize:      AppConstants.fontSizeXs,
                      fontWeight:    FontWeight.w700,
                      color:         Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
