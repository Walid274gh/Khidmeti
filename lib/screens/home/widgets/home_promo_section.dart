// lib/screens/home/widgets/home_promo_section.dart
// FIX (Engineer): ConsumerWidget → StatelessWidget.
//   ref was never read inside build() — ConsumerWidget was unnecessary,
//   registering this widget in Riverpod's subscriber graph for no benefit.
// FIX (Designer): statusAcceptedDark/Light replaced with promoBlueDark/Light.
//   Status colours (semantic meaning: "job accepted") were being used as
//   decorative card accents — a design system violation.

import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/localization.dart';

class HomePromoSection extends StatelessWidget {
  const HomePromoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize:       MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.paddingLg,
            AppConstants.paddingSm,
            AppConstants.paddingLg,
            AppConstants.spacingSm,
          ),
          child: Text(
            context.tr('home.promos_title'),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight:    FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark
                      ? AppTheme.darkSecondaryText
                      : AppTheme.lightSecondaryText,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PromoCard(
                isDark:    isDark,
                // FIX: dedicated promo colour — not a status colour
                accent:    isDark
                    ? AppTheme.promoBlueDark
                    : AppTheme.promoBlueLight,
                badgeText: context.tr('home.promo_badge_discount'),
                title:     context.tr('home.promo_plumber_title'),
                subtitle:  context.tr('home.promo_plumber_subtitle'),
              ),
              const SizedBox(height: AppConstants.sectionCardGap),
              _PromoCard(
                isDark:    isDark,
                accent:    AppTheme.aiPrimary,
                badgeText: context.tr('home.promo_badge_new'),
                title:     context.tr('home.promo_ai_title'),
                subtitle:  context.tr('home.promo_ai_subtitle'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  final bool   isDark;
  final Color  accent;
  final String badgeText;
  final String title;
  final String subtitle;

  const _PromoCard({
    required this.isDark,
    required this.accent,
    required this.badgeText,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title — $subtitle',
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMd),
        decoration: BoxDecoration(
          color: accent.withOpacity(isDark ? 0.07 : 0.05),
          borderRadius: BorderRadius.circular(AppConstants.radiusXl),
          border: Border.all(
            color: accent.withOpacity(isDark ? 0.18 : 0.14),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingSm,
                vertical:   AppConstants.spacingXs,
              ),
              decoration: BoxDecoration(
                color:        accent.withOpacity(0.14),
                borderRadius: BorderRadius.circular(AppConstants.radiusXs),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize:      AppConstants.fontSizeXs,
                  fontWeight:    FontWeight.w700,
                  color:         accent,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: AppConstants.fontSizeSm,
                color: isDark
                    ? AppTheme.darkSecondaryText
                    : AppTheme.lightSecondaryText,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
