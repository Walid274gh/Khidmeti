// lib/screens/home/widgets/home_cta_button.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

// ============================================================================
// HOME CTA BUTTON — Design C: square icon + title + subtitle + pill badge
//
// Same height as before (AppConstants.buttonHeight = 54.0).
// FIX (UI Polish): "Nouveau →" badge changed from borderRadius(radiusSm = 8)
// to a fully pill-shaped borderRadius(50) to match the circular/glassmorphism
// design language of the search bar and icon containers.
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
            height: AppConstants.buttonHeight, // 54.0 — unchanged
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkSurface.withOpacity(0.60)
                  : AppTheme.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border:       Border.all(color: border, width: 0.5),
            ),
            child: Row(
              children: [
                const SizedBox(width: AppConstants.paddingSm + 2),

                // Square icon — calendar + checkmark
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

                // FIX (UI Polish — pill badge): was BorderRadius.circular(radiusSm = 8)
                // which looked square against the circular icon containers and pill
                // search bar. Changed to BorderRadius.circular(50) for a fully rounded
                // pill shape that matches the app's circular design language.
                Container(
                  margin: const EdgeInsets.only(
                      right: AppConstants.paddingSm + 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingMd,
                    vertical:   AppConstants.spacingXs + 2,
                  ),
                  decoration: BoxDecoration(
                    color:        accent,
                    borderRadius: BorderRadius.circular(50),
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
