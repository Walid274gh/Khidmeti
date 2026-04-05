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
                // [UI-FIX SPACING]: was SizedBox(width: paddingSm + 2) = 10dp
                // — off 4dp grid. Replaced with spacingChipGap (12dp on-grid).
                const SizedBox(width: AppConstants.spacingChipGap),

                // Square icon container
                // [W8 FIX]: was width: 40, height: 40 — raw literals.
                // Replaced with AppConstants.iconContainerXl (40dp named token).
                Container(
                  width:  AppConstants.iconContainerXl,
                  height: AppConstants.iconContainerXl,
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

                const SizedBox(width: AppConstants.spacingChipGap),

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
                      // [UI-FIX SPACING]: was SizedBox(height: 2) — raw px.
                      // Replaced with AppConstants.spacingXxs (2dp token).
                      SizedBox(height: AppConstants.spacingXxs),
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
                  // [UI-FIX SPACING]: was margin right: paddingSm + 2 = 10dp
                  // — off grid. Replaced with spacingChipGap (12dp on-grid).
                  margin: const EdgeInsets.only(
                      right: AppConstants.spacingChipGap),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingMd,
                    vertical:   AppConstants.spacingXs,
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
                      // [W2 FIX]: was Colors.white — hardcoded primitive.
                      // Replaced with colorScheme.onPrimary — semantically
                      // correct: text that contrasts with the primary/accent fill.
                      color:         Theme.of(context).colorScheme.onPrimary,
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
